class Wherefore < Formula
  include Language::Python::Virtualenv

  desc "Explains WHY two datasets differ, not just that they do"
  homepage "https://github.com/tracelore/wherefore"
  url "https://files.pythonhosted.org/packages/1a/6c/8f2326b10283a0703c28f489e1700ada6e81cc2953ed74e905f9613b8dc3/wherefore-0.3.1.tar.gz"
  sha256 "db83824058a9d9c9127cf22d8427f860571a1551824cf15b6429c0e01f9eb590"
  license "Apache-2.0"

  # This formula skips a published version: the tap was never bumped
  # for 0.2.0 (PostgreSQL connectivity), so this update brings BOTH
  # PostgreSQL support and 0.3.0's database batch mode
  # (`compare-dir db://* db://*`) to Homebrew at once. See README.md's
  # changelog section for the user-facing summary of both rounds.
  #
  # v0.3.1: fixes a real pandas 3.0.3 segfault (pd.to_datetime on a
  # plain non-date string column -- not a Python exception, a real
  # SIGSEGV) and a real --fuzzy-keys correctness bug (could merge two
  # unrelated records whose keys differ only in separator/case). The
  # pandas resource below is downgraded to 2.3.3 to match
  # wherefore 0.3.1's own pandas>=2.2,<3.0 constraint -- see
  # CHANGELOG.md in the main repo for the full account of both fixes.
  #
  # Built once, successfully, on a real Mac (Apple Silicon) after the
  # build issues documented below (and the original five from the
  # 0.1.0 round, still relevant -- see install()'s comments). This
  # bottle is what makes that pay off permanently: every future
  # `brew install` on a matching platform downloads this prebuilt
  # archive instead of repeating the from-source build.
  # The old bottle block was removed, not left pointing at a stale
  # artifact. The previous bottle was built against pandas 3.0.3 (the
  # broken, segfaulting version) -- it would pour a binary that
  # contains exactly the bug v0.3.1 exists to fix. A fresh
  # `brew install --build-bottle` + `brew bottle` needs to run against
  # this updated formula before a new `bottle do...end` block can be
  # added back.

  # Confirmed by directly inspecting every dependency's real sdist
  # pyproject.toml (not guessed): TWO of the resources below require
  # maturin/Rust (cargo) to build from source -- jiter (via anthropic)
  # and pydantic_core (via pydantic). Homebrew's
  # virtualenv_install_with_resources always passes pip --no-binary
  # :all: (confirmed via Homebrew/discussions#1723 -- substituting a
  # prebuilt wheel for any one resource fails differently, with "is
  # not installable: Neither setup.py nor pyproject.toml found"), so
  # both of these need a real cargo on PATH during the build. This is
  # the standard, correct fix for that -- not wheel substitution.
  #
  # polars-runtime-32 (the compiled engine behind datacompy's
  # unconditional `polars[pandas]` dependency -- not something this
  # formula can avoid) ALSO needs Rust, but `rust => :build` alone is
  # NOT sufficient for it: its sdist pins a specific NIGHTLY toolchain
  # via rust-toolchain.toml (confirmed by reading it directly:
  # `channel = "nightly-2026-04-01"`), which only rustup can honor --
  # Homebrew's plain `rust` formula has no rustup and can't satisfy
  # that pin. Rather than add rustup and fetch a full nightly toolchain
  # for this one dependency, polars-runtime-32 is fetched as a prebuilt
  # wheel instead (see install() below) -- the lower-risk fix, given
  # how many real, distinct build issues this dependency tree had
  # already surfaced by the time this was found.
  depends_on "rust" => :build
  depends_on "python@3.13"

  resource "annotated-doc" do
    url "https://files.pythonhosted.org/packages/57/ba/046ceea27344560984e26a590f90bc7f4a75b06701f653222458922b558c/annotated_doc-0.0.4.tar.gz"
    sha256 "fbcda96e87e9c92ad167c2e53839e57503ecfda18804ea28102353485033faa4"
  end

  resource "annotated-types" do
    url "https://files.pythonhosted.org/packages/ee/67/531ea369ba64dcff5ec9c3402f9f51bf748cec26dde048a2f973a4eea7f5/annotated_types-0.7.0.tar.gz"
    sha256 "aff07c09a53a08bc8cfccb9c85b05f1aa9a2a6f23728d790723543408344ce89"
  end

  resource "anthropic" do
    url "https://files.pythonhosted.org/packages/b9/8a/9afc7305a2ce4b52b30e137f83cd2a6a90b918b3997073db11bb5a1de55a/anthropic-0.111.0.tar.gz"
    sha256 "39cbda0ac17a6d423e5bf609811bd69b26eddf6299d7a468126e05bc711ce826"
  end

  resource "anyio" do
    url "https://files.pythonhosted.org/packages/1c/b5/001890774a9552aff22502b8da382593109ce0c95314abaebbb116567545/anyio-4.14.0.tar.gz"
    sha256 "b47c1f9ccf73e67021df785332508f99379c68fa7d0684e8e3492cb1d4b23f89"
  end

  resource "certifi" do
    url "https://files.pythonhosted.org/packages/c9/c7/424b75da314c1045981bd9777432fad05a9e0c69daa4ed7e308bbaffe405/certifi-2026.6.17.tar.gz"
    sha256 "024c88eeec92ca068db80f02b8b07c9cef7b9fe261d1d535abfd5abd6f6af432"
  end

  resource "datacompy" do
    url "https://files.pythonhosted.org/packages/d0/54/dd9f235dbe223cbc1eb09af13fa095564e5bbb5cb29e4e8df9f859061d10/datacompy-1.0.2.tar.gz"
    sha256 "d1bc4e5763dbe99b168695fccda3caef3815a9f212d7eb43abb1857cfa504ad6"
  end

  resource "distro" do
    url "https://files.pythonhosted.org/packages/fc/f8/98eea607f65de6527f8a2e8885fc8015d3e6f5775df186e443e0964a11c3/distro-1.9.0.tar.gz"
    sha256 "2fa77c6fd8940f116ee1d6b94a2f90b13b5ea8d019b98bc8bafdcabcdd9bdbed"
  end

  resource "docstring_parser" do
    url "https://files.pythonhosted.org/packages/e0/4d/f332313098c1de1b2d2ff91cf2674415cc7cddab2ca1b01ae29774bd5fdf/docstring_parser-0.18.0.tar.gz"
    sha256 "292510982205c12b1248696f44959db3cdd1740237a968ea1e2e7a900eeb2015"
  end

  resource "et_xmlfile" do
    url "https://files.pythonhosted.org/packages/d3/38/af70d7ab1ae9d4da450eeec1fa3918940a5fafb9055e934af8d6eb0c2313/et_xmlfile-2.0.0.tar.gz"
    sha256 "dab3f4764309081ce75662649be815c4c9081e88f0837825f90fd28317d4da54"
  end

  resource "h11" do
    url "https://files.pythonhosted.org/packages/01/ee/02a2c011bdab74c6fb3c75474d40b3052059d95df7e73351460c8588d963/h11-0.16.0.tar.gz"
    sha256 "4e35b956cf45792e4caa5885e69fba00bdbc6ffafbfa020300e549b208ee5ff1"
  end

  resource "httpcore" do
    url "https://files.pythonhosted.org/packages/06/94/82699a10bca87a5556c9c59b5963f2d039dbd239f25bc2a63907a05a14cb/httpcore-1.0.9.tar.gz"
    sha256 "6e34463af53fd2ab5d807f399a9b45ea31c3dfa2276f15a2c3f00afff6e176e8"
  end

  resource "httpx" do
    url "https://files.pythonhosted.org/packages/b1/df/48c586a5fe32a0f01324ee087459e112ebb7224f646c0b5023f5e79e9956/httpx-0.28.1.tar.gz"
    sha256 "75e98c5f16b0f35b567856f597f06ff2270a374470a5c2392242528e3e3e42fc"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/cd/63/9496c57188a2ee585e0f1db071d75089a11e98aa86eb99d9d7618fc1edce/idna-3.18.tar.gz"
    sha256 "ffb385a7e039654cef1ab9ef32c6fafe283c0c0467bba1d9029738ce4a14a848"
  end

  resource "Jinja2" do
    url "https://files.pythonhosted.org/packages/df/bf/f7da0350254c0ed7c72f3e33cef02e048281fec7ecec5f032d4aac52226b/jinja2-3.1.6.tar.gz"
    sha256 "0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d"
  end

  # jiter is the ONE dependency (of 38) that failed building from sdist
  # in real testing: it has a Rust extension built via maturin, and
  # Homebrew's isolated build sandbox didn't have a Rust toolchain
  # (cargo) on PATH, so installing maturin itself as a build dependency
  # failed before jiter's own compilation ever started. Every other
  # dependency in this formula -- including numpy, pandas, and pyarrow,
  # the ones expected to be risky -- built successfully from sdist on
  # the first real test; this was the actual, confirmed failure point.
  #
  # First attempted fix (WRONG, kept here as a documented dead end):
  # pointing this resource at the prebuilt wheel instead of the sdist.
  # This fails differently: Homebrew's virtualenv_install_with_resources
  # always invokes pip with --no-binary :all: (confirmed via a real
  # Homebrew maintainer's answer to the identical mistake on the
  # `pyfiglet` resource in a different formula, Homebrew/discussions
  # #1723) -- it unconditionally treats every resource as source to be
  # built, so handing it a .whl produces "Directory ... is not
  # installable. Neither 'setup.py' nor 'pyproject.toml' found",
  # confirmed by direct testing.
  #
  # REAL fix: jiter's sdist needs a working `cargo` to compile via
  # maturin -- the correct, standard way to give a Homebrew formula a
  # build-time Rust toolchain is `depends_on "rust" => :build` (see
  # this formula's depends_on lines), not substituting a wheel. This
  # does not bloat the final install -- `=> :build` dependencies aren't
  # kept around after the formula finishes building.
  resource "jiter" do
    url "https://files.pythonhosted.org/packages/66/b5/55f06bb281d92fb3cc86d14e1def2bd908bb77693183e7cb1f5a3c388b0c/jiter-0.15.0.tar.gz"
    sha256 "4251acc80e2b7c9b7b8823456ea0fceeb0734dac2df7636d3c711b38476b5a76"
  end

  resource "markdown-it-py" do
    url "https://files.pythonhosted.org/packages/06/ff/7841249c247aa650a76b9ee4bbaeae59370dc8bfd2f6c01f3630c35eb134/markdown_it_py-4.2.0.tar.gz"
    sha256 "04a21681d6fbb623de53f6f364d352309d4094dd4194040a10fd51833e418d49"
  end

  resource "MarkupSafe" do
    url "https://files.pythonhosted.org/packages/7e/99/7690b6d4034fffd95959cbe0c02de8deb3098cc577c67bb6a24fe5d7caa7/markupsafe-3.0.3.tar.gz"
    sha256 "722695808f4b6457b320fdc131280796bdceb04ab50fe1795cd540799ebe1698"
  end

  resource "mdurl" do
    url "https://files.pythonhosted.org/packages/d6/54/cfe61301667036ec958cb99bd3efefba235e65cdeb9c84d24a8293ba1d90/mdurl-0.1.2.tar.gz"
    sha256 "bb413d29f5eea38f31dd4754dd7377d4465116fb207585f97bf925588687c1ba"
  end

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/d0/ad/fed0499ce6a338d2a03ebae59cd15093910c8875328855781952abf6c2fe/numpy-2.4.6.tar.gz"
    sha256 "f3a3570c4a2a16746ac2c31a7c7c7b0c186b95ce902e33db6f28094ed7387dda"
  end

  resource "openpyxl" do
    url "https://files.pythonhosted.org/packages/3d/f9/88d94a75de065ea32619465d2f77b29a0469500e99012523b91cc4141cd1/openpyxl-3.1.5.tar.gz"
    sha256 "cf0e3cf56142039133628b5acffe8ef0c12bc902d2aadd3e0fe5878dc08d1050"
  end

  resource "ordered-set" do
    url "https://files.pythonhosted.org/packages/4c/ca/bfac8bc689799bcca4157e0e0ced07e70ce125193fc2e166d2e685b7e2fe/ordered-set-4.1.0.tar.gz"
    sha256 "694a8e44c87657c59292ede72891eb91d34131f6531463aab3009191c77364a8"
  end

  resource "pandas" do
    url "https://files.pythonhosted.org/packages/33/01/d40b85317f86cf08d853a4f495195c73815fdf205eef3993821720274518/pandas-2.3.3.tar.gz"
    sha256 "e05e1af93b977f7eafa636d043f9f94c7ee3ac81af99c13508215942e64c993b"
    # Downgraded from 3.0.3 in v0.3.1: confirmed by direct testing that
    # pandas 3.0.3 segfaults inside pd.to_datetime(..., errors="coerce",
    # format="ISO8601") on a plain non-date string column -- exactly
    # what loaders.py calls on every load. wherefore 0.3.1 itself pins
    # pandas>=2.2,<3.0 for this reason; this resource must match that
    # constraint, not just the top-level sdist version.
  end

  resource "polars" do
    url "https://files.pythonhosted.org/packages/ff/f9/aeda46259b0669247a160315d2d51269de9504b9dd2f70acadbcb22f46b7/polars-1.41.2.tar.gz"
    sha256 "256d6731162371b77f3f29a55eacb8c0fc740ddb1a293a01d2ef5b5393c5c708"
  end

  # NOTE: no "polars-runtime-32", "pyarrow", or "psycopg2-binary"
  # resource block here, deliberately -- see install() below. All
  # three are fetched directly by name+version from PyPI as prebuilt
  # wheels rather than via Homebrew's resource mechanism, since the
  # resource mechanism always forces a from-sdist build, which is
  # exactly the problem being avoided for each:
  #   - polars-runtime-32: pinned to a specific nightly Rust toolchain
  #     Homebrew's `rust` formula can't provide (see install() below)
  #   - pyarrow: needs a separately-built Arrow C++ library Homebrew
  #     has no clean way to wire up (see install() below)
  #   - psycopg2-binary: its sdist deliberately fails metadata
  #     generation outside of a real binary-wheel build -- confirmed
  #     directly (pip download --no-binary :all: fails with
  #     "metadata-generation-failed" before even reaching compilation).
  #     This is intentional upstream behavior, not a packaging gap:
  #     the package's entire purpose is to BE the prebuilt wheel, as
  #     an alternative to plain `psycopg2` (source build requiring
  #     libpq-dev/pg_config). Forcing a from-source build defeats the
  #     one thing this package exists to avoid.
  # Keeping unused sdist resources around for any of these (download +
  # checksum-verify a tarball that's never actually installed, or in
  # psycopg2-binary's case, one that can't even be installed) would be
  # confusing dead weight, not real infrastructure.

  resource "pydantic" do
    url "https://files.pythonhosted.org/packages/18/a5/b60d21ac674192f8ab0ba4e9fd860690f9b4a6e51ca5df118733b487d8d6/pydantic-2.13.4.tar.gz"
    sha256 "c40756b57adaa8b1efeeced5c196f3f3b7c435f90e84ea7f443901bec8099ef6"
  end

  resource "pydantic_core" do
    url "https://files.pythonhosted.org/packages/9d/56/921726b776ace8d8f5db44c4ef961006580d91dc52b803c489fafd1aa249/pydantic_core-2.46.4.tar.gz"
    sha256 "62f875393d7f270851f20523dd2e29f082bcc82292d66db2b64ea71f64b6e1c1"
  end

  resource "Pygments" do
    url "https://files.pythonhosted.org/packages/c3/b2/bc9c9196916376152d655522fdcebac55e66de6603a76a02bca1b6414f6c/pygments-2.20.0.tar.gz"
    sha256 "6757cd03768053ff99f3039c1a36d6c0aa0b263438fcab17520b30a303a82b5f"
  end

  resource "python-dateutil" do
    url "https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz"
    sha256 "37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3"
  end

  resource "PyYAML" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  resource "RapidFuzz" do
    url "https://files.pythonhosted.org/packages/2c/21/ef6157213316e85790041254259907eb722e00b03480256c0545d98acd33/rapidfuzz-3.14.5.tar.gz"
    sha256 "ba10ac57884ce82112f7ed910b67e7fb6072d8ef2c06e30dc63c0f604a112e0e"
  end

  resource "rich" do
    url "https://files.pythonhosted.org/packages/c0/8f/0722ca900cc807c13a6a0c696dacf35430f72e0ec571c4275d2371fca3e9/rich-15.0.0.tar.gz"
    sha256 "edd07a4824c6b40189fb7ac9bc4c52536e9780fbbfbddf6f1e2502c31b068c36"
  end

  resource "shellingham" do
    url "https://files.pythonhosted.org/packages/58/15/8b3609fd3830ef7b27b655beb4b4e9c62313a4e8da8c676e142cc210d58e/shellingham-1.5.4.tar.gz"
    sha256 "8dbca0739d487e5bd35ab3ca4b36e11c4078f3a234bfce294b0a0291363404de"
  end

  resource "six" do
    url "https://files.pythonhosted.org/packages/94/e7/b2c673351809dca68a0e064b6af791aa332cf192da575fd474ed7d6f16a2/six-1.17.0.tar.gz"
    sha256 "ff70335d468e7eb6ec65b95b99d3a2836546063f63acc5171de367e834932a81"
  end

  resource "sniffio" do
    url "https://files.pythonhosted.org/packages/a2/87/a6771e1546d97e7e041b6ae58d80074f81b7d5121207425c964ddf5cfdbd/sniffio-1.3.1.tar.gz"
    sha256 "f4324edc670a0f49750a81b895f35c3adb843cca46f0530f79fc1babb23789dc"
  end

  resource "typer" do
    url "https://files.pythonhosted.org/packages/5e/ed/ef06584ccdd5c410df0837951ecd7e15d9a6144ea1bd4c73cecab1a89891/typer-0.26.7.tar.gz"
    sha256 "e314a34c617e419c091b2830dda3ea1f257134ff593061a8f5b9717ab8dddb3a"
  end

  resource "typing-inspection" do
    url "https://files.pythonhosted.org/packages/55/e3/70399cb7dd41c10ac53367ae42139cf4b1ca5f36bb3dc6c9d33acdb43655/typing_inspection-0.4.2.tar.gz"
    sha256 "ba561c48a67c5958007083d386c3295464928b01faa735ab8547c5692e87f464"
  end

  resource "typing_extensions" do
    url "https://files.pythonhosted.org/packages/72/94/1a15dd82efb362ac84269196e94cf00f187f7ed21c242792a923cdb1c61f/typing_extensions-4.15.0.tar.gz"
    sha256 "0cea48d173cc12fa28ecabc3b837ea3cf6f38c6d1136f85cbaaf598984861466"
  end

  def install
    # polars-runtime-32 has a deeper problem than first diagnosed.
    # Round 1 found: its Cargo.toml unconditionally enables a
    # "nightly" feature by default (propagating through hashbrown to
    # foldhash's nightly-only hasher_prefixfree_extras feature),
    # reproducing the exact "#![feature] may not be used on the stable
    # release channel" error from pola-rs/polars#22708. Tried fixing
    # via MATURIN_PEP517_ARGS="--no-default-features --features all"
    # (the Polars maintainers' own suggested workaround in that issue).
    #
    # Round 2, after that fix moved the failure EARLIER (metadata
    # generation, not wheel-build) rather than fixing it: read the
    # real sdist's rust-toolchain.toml directly and found
    # `channel = "nightly-2026-04-01"` -- this crate is pinned to a
    # SPECIFIC NIGHTLY rust toolchain by date, not just "stable Rust
    # missing one feature flag." rust-toolchain.toml overrides only
    # work through rustup (confirmed via rustup's own docs); Homebrew's
    # plain `rust` formula has no rustup and can't honor this pin at
    # all, so no maturin/cargo flag combination fixes this -- the
    # mismatch is structural, not cosmetic.
    #
    # Considered: installing `rustup` and fetching the pinned nightly
    # toolchain. Rejected as the first option to try, in favor of the
    # lower-risk option below, given how many real, distinct build
    # issues this dependency tree had already surfaced by this point;
    # a full nightly toolchain fetch is slower and has its own real
    # chance of yet another snag (e.g. that exact dated nightly being
    # unavailable later), for a problem this simpler fix also solves.
    #
    # Used instead: the exact same fix as pyarrow and psycopg2-binary
    # below -- pip itself can select a published wheel for one
    # specific package via --only-binary=X even while Homebrew's
    # blanket --no-binary :all: stays in force for everything else
    # (pypa/pip#13077, #12348). Confirmed a real wheel exists for this
    # exact platform: PyPI lists
    # polars_runtime_32-1.41.2-cp310-abi3-macosx_11_0_arm64.whl --
    # critically an abi3 (stable ABI) wheel, so it's valid for Python
    # 3.10 through 3.13+ without needing an exact cp313 build, and it's
    # fully prebuilt (no nightly Rust needed on this machine at all).
    #
    # pyarrow is a SEPARATE, structurally different problem from the
    # above: it is Python bindings around a separate C++ library
    # (Apache Arrow), not bundled in the sdist -- confirmed by direct
    # testing (CMake error: "Could not find a package configuration
    # file provided by Arrow") and by reading Apache Arrow's own build
    # docs, which describe this as a known, recurring issue for ANYONE
    # building pyarrow's sdist without first separately building or
    # installing the matching Arrow C++ library with exactly the right
    # CMAKE_PREFIX_PATH/Arrow_DIR wiring (real reports of this exact
    # failure on Raspberry Pi, FreeBSD, old macOS, and CI images going
    # back years -- this is not specific to this formula or machine).
    #
    # Considered and rejected: `depends_on "apache-arrow"` plus wiring
    # CMAKE_PREFIX_PATH to it. Rejected because it trades one fragile,
    # version-coupled problem (matching the Homebrew apache-arrow
    # formula's exact build against what pyarrow's CMakeLists.txt
    # expects) for another, when a simpler option exists: pyarrow
    # publishes official prebuilt wheels for this exact platform/Python
    # combination (confirmed: cp313-macosx_12_0_arm64 exists on PyPI),
    # which are self-contained (the Arrow C++ library is bundled
    # inside the wheel) -- Homebrew's hardcoded `--no-binary :all:` is
    # what's forcing an unnecessary from-source build here, not any
    # real requirement of pyarrow itself.
    #
    # psycopg2-binary (NEW this round, for PostgreSQL connectivity and
    # `compare-dir db://* db://*` against real Postgres servers): a
    # third, again structurally different reason for the same fix.
    # Its sdist isn't merely hard to build -- attempting
    # `pip download --no-binary :all:` against it fails immediately
    # with "metadata-generation-failed", confirmed by direct testing,
    # before any compilation step even starts. This is deliberate
    # upstream behavior: the entire point of the "-binary" package is
    # to BE the prebuilt wheel, as the documented alternative to
    # plain `psycopg2` (which needs libpq-dev/pg_config and a C
    # compiler present, and fails immediately without them -- a near-
    # certain failure on a typical Homebrew build sandbox). A real,
    # platform-matching wheel is confirmed to exist on PyPI:
    # psycopg2_binary-2.9.12-cp313-cp313-macosx_11_0_arm64.whl -- note
    # this one is NOT abi3 (unlike polars-runtime-32 above), so it's
    # built specifically for cp313, matching this formula's
    # `depends_on "python@3.13"` and virtualenv_create("python3.13")
    # exactly; there is no broader-compatibility wheel to fall back on
    # if that Python version pin ever changes here.
    #
    # SQLite needs no equivalent handling -- it's part of the Python
    # standard library (the `sqlite3` module), not a PyPI dependency
    # at all.
    #
    # Deliberately does NOT use resource(...).stage / install from the
    # staged sdist directory for any of these three -- that directory
    # only contains the sdist (source), so there is no wheel candidate
    # to pick from there regardless of --only-binary, which would
    # silently reproduce the exact same failure. Must instead ask pip
    # to resolve each package by NAME against the real package index,
    # the same place the prebuilt wheel actually lives.
    venv = virtualenv_create(libexec, "python3.13")

    special_cased = ["polars-runtime-32", "pyarrow", "psycopg2-binary"]
    other_resources = resources.reject { |r| special_cased.include?(r.name) }
    venv.pip_install other_resources

    # Versions pinned directly here (matching every other pin in this
    # formula) rather than read from a resource, since no
    # "polars-runtime-32", "pyarrow", or "psycopg2-binary" resource
    # exists -- see above for why all three are fetched by name from
    # PyPI instead.
    system libexec/"bin/python", "-m", "pip", "install",
           "--no-deps", "--ignore-installed", "--only-binary=polars-runtime-32",
           "polars-runtime-32==1.41.2"
    system libexec/"bin/python", "-m", "pip", "install",
           "--no-deps", "--ignore-installed", "--only-binary=pyarrow",
           "pyarrow==24.0.0"
    system libexec/"bin/python", "-m", "pip", "install",
           "--no-deps", "--ignore-installed", "--only-binary=psycopg2-binary",
           "psycopg2-binary==2.9.12"

    venv.pip_install_and_link buildpath
  end

  # KNOWN, ACCEPTED LIMITATION (confirmed by real testing on Apple
  # Silicon, not a guess): `brew install`'s post-install linkage-fixing
  # step fails on ONE bundled dylib inside psycopg2-binary's wheel --
  #
  #   Error: Failed changing dylib ID of
  #     .../site-packages/psycopg2/.dylibs/libkrb5support.1.1.dylib
  #   Updated load commands do not fit in the header ... needs to be
  #   relinked, possibly with -headerpad or -headerpad_max_install_names
  #
  # This is a Kerberos support library bundled transitively via libpq
  # inside psycopg2-binary's prebuilt wheel -- its dylib header doesn't
  # have enough reserved space for Homebrew's install-name rewrite, the
  # same general class of issue as a too-small -headerpad at link time,
  # except this dylib was built upstream (inside the published wheel),
  # not by this formula, so there's no link step here to add the flag
  # to. Confirmed NOT to break actual functionality: a direct test --
  #   libexec/bin/python -c "import psycopg2; print(psycopg2.__version__)"
  # -- succeeds and reports a real version string after this warning.
  # `brew install` itself confirms this is non-fatal ("the formula
  # built, but you may encounter issues using it or linking other
  # formulae against it" -- informational, not a failure exit code).
  #
  # Accepted as a known, documented limitation rather than chased
  # further, for the same reason similar tradeoffs were accepted
  # elsewhere in this formula: the actual functionality (PostgreSQL
  # connectivity via psycopg2) works correctly despite it, and a fix
  # would mean either re-linking a dylib Homebrew didn't build (fragile,
  # liable to break on psycopg2-binary's next release) or replacing
  # --only-binary with a from-source psycopg2 build (which trades this
  # cosmetic warning for the near-certain, harder failure -only-binary
  # exists to avoid -- see the comment above this method).

  test do
    system bin/"wherefore", "--help"

    (testpath/"source.csv").write("id,val\n1,10\n2,20\n")
    (testpath/"target.csv").write("id,val\n1,10\n2,99\n")
    system bin/"wherefore", "compare", "source.csv", "target.csv", "--output", "report.md"
    assert_path_exists testpath/"report.md"

    # Real SQLite database batch-mode test (db://* db://*), exercising
    # this round's headline feature end-to-end -- not just imported,
    # actually run against real on-disk databases with a real schema
    # difference, the same standard the manual verification before
    # this release used (see the tap's README changelog entry).
    system libexec/"bin/python", "-c", <<~PYTHON
      import sqlite3
      src = sqlite3.connect("#{testpath}/source.sqlite")
      src.execute("CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, status TEXT)")
      src.execute("INSERT INTO customers VALUES (1, 'Alice', 'active'), (2, 'Bob', 'active')")
      src.commit()
      src.close()

      tgt = sqlite3.connect("#{testpath}/target.sqlite")
      tgt.execute("CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, status TEXT)")
      tgt.execute("INSERT INTO customers VALUES (1, 'Alice', 'active'), (2, 'Bob', 'inactive')")
      tgt.commit()
      tgt.close()
    PYTHON

    # Built as an argument array, not an interpolated shell string --
    # "db://*" passed through shell_output would be glob-expanded by
    # the shell against files in the current directory before
    # wherefore ever saw it (a real risk, not theoretical, since `*`
    # is a literal part of this syntax, not a placeholder). `system`
    # with separate arguments bypasses the shell entirely, the same
    # way every other `system bin/"wherefore", ...` call in this file
    # already does.
    ENV["SOURCE_DB"] = "sqlite:///#{testpath}/source.sqlite"
    ENV["TARGET_DB"] = "sqlite:///#{testpath}/target.sqlite"
    system bin/"wherefore", "compare-dir", "db://*", "db://*",
           "--source-conn-env", "SOURCE_DB", "--target-conn-env", "TARGET_DB",
           "--yes", "--output-dir", "#{testpath}/db_reports"
    assert_path_exists testpath/"db_reports/customers_report.md"
  end
end
