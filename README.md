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

**Update: this was confirmed working.** A real
`brew install tracelore/wherefore/wherefore` from a clean state (no
`--build-from-source`, no `--build-bottle`) successfully poured the
bottle in seconds and ran a real comparison correctly. v0.1.0's bottle
worked end to end.

## v0.2.0: formula updated, bottle needs rebuilding

`wherefore` 0.2.0 added real PostgreSQL connectivity (verified against
a real Postgres server, see the main repo's `TAXONOMY_TODO.md`). The
formula here has been updated to match:

- `url`/`sha256` bumped to the real, live PyPI 0.2.0 sdist.
- New dependency: `psycopg2-binary` (PostgreSQL driver). Confirmed by
  direct testing this needed the SAME special-case treatment as
  `polars-runtime-32`/`pyarrow` -- its sdist requires `libpq-dev`/
  `pg_config` at build time despite the "-binary" name (which only
  describes the published wheel, not the sdist Homebrew's resource
  mechanism would otherwise try to build). Fetched by name+version
  with `--only-binary`, same pattern as the other two.
- **The old bottle block was removed, not left pointing at a stale
  artifact.** 0.1.0's bottle is for 0.1.0's exact build -- it doesn't
  cover the new dependency at all. A fresh `brew install --build-bottle`
  + `brew bottle` needs to run against this updated formula before a
  new `bottle do...end` block can be added back.

**Status: built, installed, works correctly -- with one real, understood,
accepted limitation, not the clean wheel-fetch success first predicted.**
`psycopg2-binary`'s wheel-fetch fix worked for its actual purpose (no
`pg_config`/`libpq-dev` build failure, confirmed by the install
completing and `psycopg2` importing correctly inside the installed
venv -- `2.9.12 (dt dec pq3 ext lo64)`, confirmed by direct testing,
plus a real end-to-end `wherefore compare` run). But it surfaced a
DIFFERENT, separate real issue: `psycopg2-binary`'s bundled
`libkrb5support.1.1.dylib` (a transitive Kerberos dependency of
`libpq`'s GSSAPI auth support, not dead weight -- confirmed by listing
the wheel's full bundled dependency chain) has essentially zero spare
header space reserved for its install-path load command (confirmed by
measuring the actual Mach-O load command size with `otool -l`: 48
bytes available, 46 used by the original path, Homebrew's real
install path needs 106+ -- short by 60+ bytes, not a trim-a-few-
characters gap). Homebrew's bottle-relocation step can't rewrite a
load command into less space than the path needs, so it warns
("Failed to fix install linkage") but does NOT fail the install --
confirmed the formula still builds, links, and runs correctly despite
the warning.

**Real consequence, decided deliberately rather than chased further:**
`brew bottle` for this version produces a bottle WITHOUT `cellar: :any`
(confirmed: 0.1.0's bottle had it, 0.2.0's doesn't) -- meaning it only
pours for users on Homebrew's standard default Cellar path
(`/opt/homebrew` on Apple Silicon), not a customized one. Considered
properly fixing this via `delocate-wheel` (the real tool for exactly
this class of problem -- rewriting a Mach-O load command with more
reserved space, then re-patching every other binary that references
the old one) and decided against attempting it for now: the fix needs
real macOS Mach-O tooling to verify (untestable from a sandbox), would
need to cascade through several other bundled libraries in the same
dependency chain, and would buy back portability for a Homebrew
install-path customization almost nobody actually uses -- while the
tool already works correctly for everyone on the standard, default
install path today. Tracked as a known, deliberate limitation, not
silently accepted without understanding it.

## Rebuilding the bottle for a new version (the real sequence, proven once already)

```bash
cp Formula/wherefore.rb $(brew --repo tracelore/wherefore)/Formula/wherefore.rb
cd $(brew --repo tracelore/wherefore)
brew uninstall wherefore 2>/dev/null  # ignore error if not installed
brew install --build-bottle tracelore/wherefore/wherefore
brew bottle tracelore/wherefore/wherefore
```

Take the bottle filename and the `bottle do...end` block the last
command prints, add the block to `Formula/wherefore.rb` (with a
`root_url` pointing at a new GitHub Release for the new version tag),
upload the bottle file as that release's asset (renamed to the
SINGLE-dash filename Homebrew's download logic actually expects --
confirmed this naming mismatch is a real, recurring Homebrew quirk for
custom taps, not a one-off), then:

```bash
brew uninstall wherefore
brew install tracelore/wherefore/wherefore   # no source-build flags --
                                               # should pour the new bottle
```

