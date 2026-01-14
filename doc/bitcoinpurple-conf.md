# `bitcoinpurple.conf` Configuration File

The configuration file is used by `bitcoinpurpled`, `bitcoinpurple-qt` and `bitcoinpurple-cli`.

All command-line options (except for `-?`, `-help`, `-version` and `-conf`) may be specified in a configuration file, and all configuration file options (except for `includeconf`) may also be specified on the command line. Command-line options override values set in the configuration file and configuration file options override values set in the GUI.

Changes to the configuration file while `bitcoinpurpled` or `bitcoinpurple-qt` is running only take effect after restarting.

Users should never make any configuration changes which they do not understand. Furthermore, users should always be wary of accepting any configuration changes provided to them by another source (even if they believe that they do understand them).

## Quick Start (TL;DR)

1. Find your data directory (see "Default configuration file locations" below).
2. Create a text file named `bitcoinpurple.conf` in that directory.
3. Add the options you need (see "Example configuration" below).
4. Restart `bitcoinpurpled` or `bitcoinpurple-qt` to apply changes.

The configuration file is not created automatically on first start.

## Configuration File Format

The configuration file is a plain text file and consists of `option=value` entries, one per line. Leading and trailing whitespaces are removed.

In contrast to the command-line usage:
- an option must be specified without leading `-`;
- a value of the given option is mandatory; e.g., `testnet=1` (for chain selection options), `noconnect=1` (for negated options).

### Blank lines

Blank lines are allowed and ignored by the parser.

### Comments

A comment starts with a number sign (`#`) and extends to the end of the line. All comments are ignored by the parser.

Comments may appear in two ways:
- on their own on an otherwise empty line (_preferable_);
- after an `option=value` entry.

### Network specific options

Network specific options can be:
- placed into sections with headers `[main]` (not `[mainnet]`), `[test]` (not `[testnet]`), `[signet]` or `[regtest]`;
- prefixed with a chain name; e.g., `regtest.maxmempool=100`.

Network specific options take precedence over non-network specific options.
If multiple values for the same option are found with the same precedence, the
first one is generally chosen.

This means that given the following configuration, `regtest.rpcport` is set to `3000`:

```
regtest=1
rpcport=2000
regtest.rpcport=3000

[regtest]
rpcport=4000
```

## Example Configuration (Full, With Default Ports)

Below is a fuller example you can copy and edit. Default ports are shown
explicitly; you can remove them to rely on the built-in defaults.

```
# --- Core behavior ---
# Start the RPC server so bitcoinpurple-cli can talk to the node.
server=1

# Run in the background (Linux/Unix only).
# daemon=1

# --- Data directory ---
# datadir=/path/to/your/datadir

# --- Network selection (uncomment exactly one if not mainnet) ---
# testnet=1
# signet=1
# regtest=1

# --- P2P networking ---
# Listen for inbound connections (default: 1).
listen=1

# Default mainnet P2P port (uncomment to override).
# port=13496

# Bind to specific interfaces (optional). Repeat to bind multiple.
# bind=0.0.0.0
# bind=[::]

# Limit total inbound+outbound connections (default: 125).
# maxconnections=125

# --- RPC ---
# Default mainnet RPC port (uncomment to override).
# rpcport=13495

# Restrict RPC to localhost (recommended).
rpcbind=127.0.0.1
rpcallowip=127.0.0.1

# For remote RPC access, add your subnet and a strong auth method.
# rpcbind=0.0.0.0
# rpcallowip=192.168.1.0/24
# rpcauth=user:salt$hash  (use share/rpcauth/rpcauth.py)

# --- Wallet ---
# wallet=wallet.dat
# avoidreuse=1

# --- Indexing / pruning ---
# Build a full transaction index (requires reindex once enabled).
# txindex=1

# Keep only the last N MiB of blocks on disk (disable full archival).
# prune=550

# --- Logging ---
# debug=net
# debug=rpc

# --- Network-specific overrides (only apply when that chain is active) ---
[test]
port=23496
rpcport=23495

[signet]
port=313496
rpcport=313495

[regtest]
port=18444
rpcport=18443
```

## Configuration File Path

The configuration file is not automatically created; you can create it using your favorite text editor. By default, the configuration file name is `bitcoinpurple.conf` and it is located in the BitcoinPurple data directory, but both the BitcoinPurple data directory and the configuration file path may be changed using the `-datadir` and `-conf` command-line options.

The `includeconf=<file>` option in the `bitcoinpurple.conf` file can be used to include additional configuration files.

### Default configuration file locations

Operating System | Data Directory | Example Path
-- | -- | --
Windows | `%APPDATA%\BitcoinPurple\` | `C:\Users\username\AppData\Roaming\BitcoinPurple\bitcoinpurple.conf`
Linux | `$HOME/.bitcoinpurple/` | `/home/username/.bitcoinpurple/bitcoinpurple.conf`
macOS | `$HOME/Library/Application Support/BitcoinPurple/` | `/Users/username/Library/Application Support/BitcoinPurple/bitcoinpurple.conf`

An example configuration file can be generated by [contrib/devtools/gen-bitcoinpurple-conf.sh](../contrib/devtools/gen-bitcoinpurple-conf.sh).
Run this script after compiling to generate an up-to-date configuration file.
The output is placed under `share/examples/bitcoinpurple.conf`.
To use the generated configuration file, copy the example file into your data directory and edit it there, like so:

```
# example copy command for linux user
cp share/examples/bitcoinpurple.conf ~/.bitcoinpurple
```
