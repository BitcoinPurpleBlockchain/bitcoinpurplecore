# BitcoinPurple Core

## What is BitcoinPurple Core?

BitcoinPurple Core connects to the BitcoinPurple peer-to-peer network to download and fully validate blocks and transactions. It also includes a wallet and graphical user interface, which can be optionally built.

Further information about BitcoinPurple Core is available in the [doc folder](/doc).

## Quick Build for Testing and Development

For rapid testing and development, use the `quick_build.sh` script which automates the entire build process with ccache support for faster rebuilds.

### Quick Start

```bash
# First time: Full build (installs dependencies, BerkeleyDB, and builds)
./quick_build.sh --full

# For testing/development: Quick rebuild (5-10x faster)
./quick_build.sh --rebuild
```

### Available Options

- `--full` - Full build including dependencies and BerkeleyDB installation (default)
- `--rebuild` - Quick rebuild without reconfiguring (fastest for iterative development)
- `--build` - Full build with reconfigure (distclean + configure + make)
- `--install-deps` - Install system dependencies only
- `--install-db` - Install BerkeleyDB 4.8 only
- `--clean` - Clean build artifacts
- `--setup-ccache` - Configure ccache for optimal performance
- `--help` - Show detailed usage information

### Features

- Automated dependency installation (build tools, Qt5, libraries)
- BerkeleyDB 4.8 setup for wallet compatibility
- ccache integration for faster rebuilds (5-10x speedup)
- Parallel compilation using all CPU cores
- Colored output for easy debugging
- Build time tracking

### Typical Workflow

```bash
# Initial setup
./quick_build.sh --full

# Make code changes, then quick rebuild
./quick_build.sh --rebuild

# Clean and rebuild from scratch
./quick_build.sh --clean
./quick_build.sh --build
```

The built binaries will be located in:
- `src/bitcoinpurpled` - Daemon
- `src/bitcoinpurple-cli` - CLI tool
- `src/qt/bitcoinpurple-qt` - GUI application
- `src/bitcoinpurple-tx` - Transaction utility
- `src/bitcoinpurple-wallet` - Wallet utility

## Running a Node

After building, start the daemon from the repository root:

```bash
# Run in the foreground (logs to stdout)
./src/bitcoinpurpled

# Or run in the background (Linux/Unix)
./src/bitcoinpurpled -daemon
```

Use `bitcoinpurple-cli` to talk to a running node:

```bash
./src/bitcoinpurple-cli -getinfo
```

To configure the node, create `bitcoinpurple.conf` in the data directory.
See [doc/bitcoinpurple-conf.md](doc/bitcoinpurple-conf.md) for locations,
defaults, and a full example configuration. For platform-specific build
instructions, see [doc/build-*.md](doc).

## License

BitcoinPurple Core is released under the terms of the MIT license. See [COPYING](COPYING) for more information or see <https://opensource.org/licenses/MIT>.

## Development Process

The `master` branch is regularly built (see `doc/build-*.md` for instructions) and tested, but it is not guaranteed to be completely stable. [Tags](https://github.com/bitcoinpurple/bitcoinpurple/tags) are created regularly from release branches to indicate new official, stable release versions of BitcoinPurple Core.

The <https://github.com/bitcoinpurple-core/gui> repository is used exclusively for the development of the GUI. Its master branch is identical in all monotree repositories. Release branches and tags do not exist, so please do not fork that repository unless it is for development reasons.

The contribution workflow is described in [CONTRIBUTING.md](CONTRIBUTING.md) and useful hints for developers can be found in [doc/developer-notes.md](doc/developer-notes.md).

## Testing

Testing and code review is the bottleneck for development; we get more pull requests than we can review and test on short notice. Please be patient and help out by testing other people's pull requests, and remember this is a security-critical project where any mistake might cost people lots of money.

### Automated Testing

Developers are strongly encouraged to write [unit tests](src/test/README.md) for new code, and to submit new unit tests for old code. Unit tests can be compiled and run (assuming they weren't disabled in configure) with:

```bash
make check
```

Further details on running and extending unit tests can be found in [/src/test/README.md](/src/test/README.md).

There are also [regression and integration tests](/test), written in Python. These tests can be run (if the [test dependencies](/test) are installed) with:

```bash
test/functional/test_runner.py
```

The CI (Continuous Integration) systems make sure that every pull request is built for Windows, Linux, and macOS, and that unit/sanity tests are run automatically.

### Manual Quality Assurance (QA) Testing

Changes should be tested by somebody other than the developer who wrote the code. This is especially important for large or high-risk changes. It is useful to add a test plan to the pull request description if testing the changes is not straightforward.

## Translations

Changes to translations as well as new translations can be submitted to [BitcoinPurple Core's Transifex page](https://www.transifex.com/bitcoinpurple/bitcoinpurple/).

Translations are periodically pulled from Transifex and merged into the git repository. See the [translation process](doc/translation_process.md) for details on how this works.

**Important**: We do not accept translation changes as GitHub pull requests because the next pull from Transifex would automatically overwrite them again.
