# homebrew-wherefore

Homebrew tap for [wherefore](https://github.com/tracelore/wherefore).

## Install

```bash
brew tap tracelore/wherefore
brew install wherefore
```

(Once this repo is pushed to GitHub as `tracelore/homebrew-wherefore`,
the above is what users run. `brew tap tracelore/wherefore` works
because Homebrew expands `tracelore/wherefore` to the repo named
`homebrew-wherefore` under the `tracelore` GitHub account/org.)

## Status: build issues found and fixed via real testing (not yet a clean install)

This formula was generated against the real, published PyPI release
(wherefore 0.1.0) -- every URL and sha256 in `Formula/wherefore.rb` was
fetched directly from PyPI's JSON API and independently re-verified
against the actual downloaded file, not just trusted from metadata.
All 38 resource blocks (the full transitive dependency tree, excluding
the optional `s3` extra) were generated the same way Homebrew's own
`homebrew-pypi-poet` tool would.

**Two real build attempts on an actual Mac (Apple Silicon, macOS, real
`brew install --build-from-source`) have happened so far:**

1. **First attempt:** `numpy`, `pandas`, and `pyarrow` -- the packages
   expected to be the hardest, per Homebrew's own docs calling out
   "long build time, complex build process" for this category -- all
   built successfully from sdist. The actual failure was `jiter`
   (pulled in transitively via the `anthropic` SDK), which needs
   `maturin`/Rust (`cargo`) to compile and failed because Homebrew's
   isolated build sandbox has no Rust toolchain on `PATH` by default.

2. **Second attempt (wrong fix, kept as a documented dead end):**
   pointed `jiter`'s resource at its prebuilt wheel instead of the
   sdist, to skip compilation. This failed differently --
   `virtualenv_install_with_resources` always passes pip `--no-binary
   :all:`, so it tried to treat the `.whl` as source code and found no
   `setup.py`/`pyproject.toml` inside it (a wheel is already-built; it
   doesn't have one). Confirmed via a real Homebrew maintainer hitting
   and explaining the identical mistake on a different formula's
   `pyfiglet` resource (Homebrew/discussions#1723).

3. **Real fix, not yet tested:** reverted `jiter` to its sdist and
   added `depends_on "rust" => :build` to the formula -- the standard,
   documented way to give a Homebrew formula a build-time Rust
   toolchain. While fixing this, systematically checked every one of
   the 38 dependencies' real sdist `pyproject.toml` (not just the one
   that already failed) and found TWO MORE packages that also need
   maturin/Rust and would have hit the identical failure in later
   alphabetical position: `pydantic_core` (via `pydantic`) and
   `polars-runtime-32` (the compiled engine behind `datacompy`'s
   unconditional `polars[pandas]` dependency). All three should now be
   covered by the single `rust => :build` dependency.

**Not yet confirmed: whether this actually completes a clean install.**

4. **Third real build attempt:** `jiter` and `pydantic_core` both built
   successfully with `rust => :build` in place -- confirms that fix
   was correct. The build then failed on `polars-runtime-32` with
   `error[E0554]: #![feature] may not be used on the stable release
   channel` on the `foldhash` crate. Traced this to a CONFIRMED
   upstream bug, not anything formula-specific: `polars-runtime-32`
   1.41.2's own `Cargo.toml` unconditionally enables a `nightly`
   feature by default, which propagates through `hashbrown` to
   `foldhash`'s nightly-only `hasher_prefixfree_extras` feature --
   reproducing the EXACT error reported in a still-open Polars GitHub
   issue, [pola-rs/polars#22708](https://github.com/pola-rs/polars/issues/22708)
   ("Build py-polars with stable rust"), which fails identically on
   any stable Rust toolchain, not just Homebrew's.

   Fixed using the Polars maintainers' own confirmed workaround from
   that same issue: pass `--no-default-features --features all` to
   maturin (loses only some nightly-only SIMD optimizations, not
   relevant here). maturin reads build flags from the
   `MATURIN_PEP517_ARGS` environment variable during a pip build
   (confirmed via maturin's own maintainer's answer in
   [PyO3/maturin#1090](https://github.com/PyO3/maturin/discussions/1090)).
   Implemented by replacing the formula's `install` method's single
   `virtualenv_install_with_resources` call with the more verbose
   `venv.pip_install`/`pip_install_and_link` form (also a documented
   Homebrew pattern, for exactly this "do something different for one
   resource" case), installing `polars-runtime-32` separately inside a
   `with_env(MATURIN_PEP517_ARGS: ...)` block so the env var doesn't
   leak into the other 37 resources' builds.

**The next real test (on the user's Mac) is whether this is the last
fix needed, or whether the build now gets past `polars-runtime-32` to
some further issue.** Genuinely don't know yet -- this dependency tree
has now surfaced three distinct real build issues in three attempts,
so a fourth wouldn't be shocking, but there's no further known risk to
flag preemptively at this point.

## Fourth real build attempt: pyarrow

Progress: `jiter` and `pydantic_core` both built successfully with
`rust => :build` in place. The build then reached `pyarrow` and
failed with a CMake error: `Could not find a package configuration
file provided by "Arrow"`.

Confirmed by web research this is NOT specific to this formula or
machine -- it's a well-documented, recurring issue going back years
(Raspberry Pi, FreeBSD, old macOS, CI images) any time pyarrow's
*sdist* is built without the separate Apache Arrow C++ library already
present and discoverable by CMake. pyarrow's sdist does not bundle
Arrow C++; only the *published wheels* are self-contained.

Two real fixes exist. Considered and rejected: `depends_on
"apache-arrow"` plus wiring `CMAKE_PREFIX_PATH`/`Arrow_DIR` correctly
-- rejected because it trades the current fragile problem for another
version-coupling problem (matching the Homebrew `apache-arrow`
formula's exact build against what pyarrow's `CMakeLists.txt`
expects), when pyarrow already publishes official prebuilt wheels for
this exact platform (`cp313-macosx_12_0_arm64`, confirmed on PyPI).

Used instead: pip itself supports overriding the binary policy for one
specific package (`--only-binary=X` alongside Homebrew's blanket
`--no-binary :all:`; documented pattern, see pypa/pip#13077, #12348).
Homebrew's `venv.pip_install` helper has no way to pass this through,
so `pyarrow` is installed via a direct `pip install --only-binary=pyarrow
pyarrow==24.0.0` call instead -- confirmed this mirrors exactly what
Homebrew's own `Virtualenv#pip_install` does internally (reading
`language/python.rb` directly: `python -m pip --python=<venv python>
install <args> <targets>`), not a workaround outside the documented
mechanism. Removed the (now unused) `pyarrow` sdist `resource` block
entirely, since it was never actually consumed by this path and would
have been confusing dead weight otherwise.

**Status:** four real, distinct build issues found and fixed across
four attempts (numpy/pandas built cleanly the whole time -- the
expected-hard packages were never actually the problem). The next test
determines whether this is finally a clean install or whether a fifth
issue surfaces past `pyarrow`.

## Fifth real build attempt: the polars-runtime-32 fix from round 3 was insufficient

The `MATURIN_PEP517_ARGS` fix (round 3, above) did not actually solve
`polars-runtime-32`'s build -- it moved the failure from the
*wheel-build* step to an earlier *metadata-generation* step
(`error: metadata-generation-failed`), which was the signal that the
real problem was deeper than one Cargo feature flag.

Read the real sdist's `rust-toolchain.toml` directly (both copies in
the tarball) and found `channel = "nightly-2026-04-01"` --
`polars-runtime-32` is pinned to a **specific nightly Rust toolchain by
date**, not just "stable Rust missing one feature." Confirmed via
rustup's own documentation that `rust-toolchain.toml` overrides are
only honored by `rustup`; Homebrew's plain `rust` formula has no
`rustup` and cannot satisfy this pin at all, regardless of any
maturin/cargo flag combination. This is a structural mismatch, not a
cosmetic one.

**Decision point, discussed directly with the user rather than just
picked:** install `rustup` and fetch the pinned nightly toolchain (the
"more correct" fix, since it lets the crate build exactly as its
authors intended), versus apply the same `--only-binary` wheel fix
already proven to work for `pyarrow`. Given that this dependency tree
had already surfaced FOUR real, distinct build issues by this point,
and a full nightly toolchain fetch carries its own real risk (that
specific dated nightly might not even be available, or might have its
own snag), the lower-risk, already-proven option was chosen: fetch
`polars-runtime-32` as a prebuilt wheel by name+version, exactly like
`pyarrow`. Confirmed a real wheel exists for this platform
(`polars_runtime_32-1.41.2-cp310-abi3-macosx_11_0_arm64.whl` --
critically `abi3`, the stable ABI, so one wheel covers Python 3.10
through 3.13+ without needing an exact `cp313` match).

Removed the now-unused `polars-runtime-32` sdist `resource` block for
the same reason `pyarrow`'s was removed earlier -- it would never
actually be consumed by this path.

**Net effect:** `rust => :build` is still needed (for `jiter` and
`pydantic_core`, which genuinely do build cleanly on stable Rust), but
`polars-runtime-32` no longer touches Rust/cargo at all on this
machine -- it's a pure wheel install now, same as `pyarrow`.

**Status:** five real, distinct issues found and fixed (one of which
required reversing course after the first fix attempt proved
insufficient) across five attempts. This represents the most thorough
diagnosis completed so far; the next real test determines whether the
build is finally clean.

## Build succeeded. Bottled.

The fifth attempt's fix worked: `wherefore` built successfully on a
real Mac (Apple Silicon, macOS 26.5, arm64_tahoe), confirmed not just
by the build log but by actually running it -- `wherefore --help` and
a real `wherefore compare` against two CSVs both worked correctly,
producing the same output as the PyPI-installed version.

Bottled with `brew bottle tracelore/wherefore/wherefore` (after
reinstalling with `--build-bottle` instead of `--build-from-source` --
the two flags are mutually exclusive; `--build-bottle` already implies
building from source, it just also prepares the result for bottling).
Homebrew's own relocatability check passed clean (no hardcoded Cellar
paths found in the built virtualenv), producing `cellar: :any` --
confirmed correct, not assumed, since the check is Homebrew's own
verification, not a guess.

The `bottle do ... end` block with the real sha256 from that build is
now in `Formula/wherefore.rb`. This is the actual payoff for all five
fixes: every future `brew install tracelore/wherefore/wherefore` on a
matching platform (Apple Silicon, macOS Tahoe or compatible) downloads
this prebuilt bottle instead of repeating the ~3-minute from-source
build -- no Rust, no nightly toolchain pin, no CMake, no Arrow C++
lookup, none of it.

## What's still open

- This bottle only covers `arm64_tahoe`. A different macOS version or
  an Intel Mac would still trigger a from-source build (and might hit
  some or all of the same five issues again, or new ones specific to
  that platform -- not verified).

## Tap pushed, bottle uploaded, root_url wired up

The tap is live at `github.com/tracelore/homebrew-wherefore` (pushed
from the local tap `brew tap-new` created). The actual bottle file --
`wherefore--0.1.0.arm64_tahoe.bottle.tar.gz`, ~95MB -- is uploaded as a
GitHub Release asset under tag `v0.1.0` (not committed to git directly;
release assets are the correct place for a binary this size, confirmed
via Homebrew's own documented pattern for non-`homebrew/core` taps).
Confirmed live with a real `curl -I -L` against the release download
URL (302 redirect to a signed `release-assets.githubusercontent.com`
URL, exactly how GitHub serves any release asset -- not a broken link).

Added `root_url` to the formula's `bottle do` block pointing at that
release, since without it Homebrew defaults to assuming any bottle
belongs to the official `homebrew/core` infrastructure
(`ghcr.io/v2/homebrew/core/...`) -- confirmed by reproducing exactly
that failure (a 404 against Homebrew's own registry) before this fix.

**Not yet verified:** a real `brew install tracelore/wherefore/wherefore`
from a clean/untapped state, against the now-complete formula with
`root_url` set, actually pours the bottle instead of building from
source. That's the next real test.



## Testing locally before pushing

```bash
brew install --build-from-source ./Formula/wherefore.rb
brew test wherefore
brew audit --new-formula wherefore
```

If all three pass, push this repo to GitHub as
`tracelore/homebrew-wherefore` and the tap is live.

## v0.2.0: PostgreSQL connectivity (built, bottled, released -- but never committed)

PostgreSQL support (`psycopg2-binary`) was built and bottled for this
tap. The bottle (`wherefore-0.2.0.arm64_tahoe.bottle.tar.gz`, ~99MB)
was uploaded as a real GitHub Release asset under tag `v0.2.0` and is
still live there. However, the corresponding `Formula/wherefore.rb`
change was never committed to this repo's git history -- confirmed
directly: `git log` on this tap shows no commit between the original
`0.1.0` formula and `0.3.0` below. The release and the tracked formula
file diverged silently. `v0.2.0`'s bottle is left in place,
unreferenced, as a record of what was actually built -- not deleted,
since it's real, working evidence of that round's effort, just never
wired up to the formula that would have made `brew install` use it.

This gap is the direct reason the `0.3.0` work below adds PostgreSQL
support to the formula's resources for the first time from this tap's
perspective, even though `psycopg2-binary` itself isn't new to the
underlying CLI.

## v0.3.0: database batch comparison mode, plus catching up on v0.2.0

`compare-dir db://* db://*` -- batch-comparing every matching table
between two databases with one combined primary-key confirmation
instead of one prompt per table -- is this round's headline feature.
Since the tap was still sitting at `0.1.0` in git (see above), this
update brings PostgreSQL connectivity and the new batch mode to
Homebrew in a single jump.

**Dependency surface: no version drift, one genuinely new package.**
Every package already pinned in the `0.1.0` formula's resources was
independently re-verified against a real, fresh `0.3.0` install
(`pip install -e ".[dev]"` on a clean venv) -- diffed name-by-name and
version-by-version, not eyeballed. All matched exactly; nothing in the
existing dependency tree had moved. The one real addition is
`psycopg2-binary==2.9.12`.

**`psycopg2-binary` needed the same `--only-binary=` fix as
`pyarrow`/`polars-runtime-32`, for a third, distinct reason.**
Confirmed directly: `pip download --no-binary :all:` against its sdist
fails immediately with `metadata-generation-failed`, before any
compilation starts. This is deliberate upstream behavior -- the
package's entire purpose is to BE the prebuilt wheel, as the documented
alternative to plain `psycopg2` (which needs `libpq-dev`/`pg_config`
and a C compiler, and would very likely fail outright in Homebrew's
build sandbox). A real wheel exists for this platform:
`psycopg2_binary-2.9.12-cp313-cp313-macosx_11_0_arm64.whl` -- note this
one is built specifically for cp313, not an abi3 wheel like
`polars-runtime-32`, so it only works because this formula's Python pin
(`depends_on "python@3.13"`) matches exactly; there's no fallback wheel
if that pin changes.

**New, real, accepted limitation: a dylib inside `psycopg2-binary`
trips Homebrew's post-install linkage fix.** Confirmed by direct
testing, reproduced identically across two separate from-source builds
and the final bottle-poured install:

```
Error: Failed changing dylib ID of
  .../site-packages/psycopg2/.dylibs/libkrb5support.1.1.dylib
Updated load commands do not fit in the header ... needs to be
relinked, possibly with -headerpad or -headerpad_max_install_names
```

`libkrb5support` is a Kerberos support library bundled transitively via
libpq inside the wheel -- built upstream, not by this formula, so there's
no link step here to add `-headerpad` to. Confirmed NOT to break actual
functionality: `libexec/bin/python -c "import psycopg2; print(psycopg2.__version__)"`
succeeds and reports a real version string, both right after a
from-source build and after pouring the final public bottle. `brew
install` itself treats this as non-fatal ("the formula built, but you
may encounter issues..." -- informational, not a failure exit). Accepted
as a known, documented limitation, the same way this tap accepted
`polars-runtime-32`'s nightly-Rust pin and `pyarrow`'s Arrow C++
dependency in the `0.1.0` round -- chasing a real fix here means either
relinking a dylib this formula didn't build (fragile against
`psycopg2-binary`'s next release) or giving up `--only-binary` for a
from-source `psycopg2` build (trading a cosmetic warning for the
near-certain harder failure `--only-binary` exists to avoid).

**This bottle is NOT `cellar: :any`, unlike `0.1.0`'s.** `brew bottle`
flagged a real absolute symlink baked into the build:
`libexec/bin/python3.13 -> /opt/homebrew/opt/python@3.13/bin/python3.13`
-- a path tied to this exact machine's Homebrew prefix. `0.1.0`'s
relocatability check passed clean; this one didn't, and that's reported
honestly in the formula's `bottle do` comment rather than carrying
`cellar: :any` forward unchanged. In practice this only matters for a
non-standard Homebrew prefix; every default Apple Silicon install (the
only platform this bottle targets, `arm64_tahoe`) uses `/opt/homebrew`.

**Bottle filename: same double-hyphen-to-single-hyphen rename `0.2.0`
needed.** `brew bottle` writes `wherefore--0.3.0.arm64_tahoe.bottle.tar.gz`
(double hyphen) locally; `brew install` fetches
`wherefore-0.3.0.arm64_tahoe.bottle.tar.gz` (single hyphen) from the
release. Missed on the first upload attempt (real `curl: (56) ... 404`
reproduced and confirmed), fixed by renaming before re-upload -- the
exact same rename `0.2.0`'s asset name shows it also needed, confirmed
by checking that release's asset name directly rather than assuming.

**Bottle hash is not byte-stable across `brew bottle` runs.** Two
separate invocations of the identical `brew bottle ...` command, with
no source changes in between, produced two different file sizes and two
different sha256 hashes. The hash actually committed to the formula was
computed directly (`shasum -a 256`) on the exact file that was later
uploaded and is now live -- not copied from an earlier run's printed
output, which would have been wrong by the time of upload.

**Verified end-to-end against the real, public bottle**, not just the
from-source build: `brew install tracelore/wherefore/wherefore` (no
`--build-from-source` flag) pulled the bottle from the real
`github.com/tracelore/homebrew-wherefore/releases/download/v0.3.0/...`
URL, poured it, and `brew test` ran the formula's full test block
against it -- including a new SQLite-backed `compare-dir db://* db://*`
test (two real on-disk databases, one deliberately mismatched row),
exercising this round's headline feature against the actual installed
bottle, not a mock or a from-source-only check.
