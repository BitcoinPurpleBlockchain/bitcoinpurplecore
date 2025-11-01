# Libraries

| Name                     | Description |
|--------------------------|-------------|
| *libbitcoinpurple_cli*         | RPC client functionality used by *bitcoinpurple-cli* executable |
| *libbitcoinpurple_common*      | Home for common functionality shared by different executables and libraries. Similar to *libbitcoinpurple_util*, but higher-level (see [Dependencies](#dependencies)). |
| *libbitcoinpurple_consensus*   | Stable, backwards-compatible consensus functionality used by *libbitcoinpurple_node* and *libbitcoinpurple_wallet* and also exposed as a [shared library](../shared-libraries.md). |
| *libbitcoinpurpleconsensus*    | Shared library build of static *libbitcoinpurple_consensus* library |
| *libbitcoinpurple_kernel*      | Consensus engine and support library used for validation by *libbitcoinpurple_node* and also exposed as a [shared library](../shared-libraries.md). |
| *libbitcoinpurpleqt*           | GUI functionality used by *bitcoinpurple-qt* and *bitcoinpurple-gui* executables |
| *libbitcoinpurple_ipc*         | IPC functionality used by *bitcoinpurple-node*, *bitcoinpurple-wallet*, *bitcoinpurple-gui* executables to communicate when [`--enable-multiprocess`](multiprocess.md) is used. |
| *libbitcoinpurple_node*        | P2P and RPC server functionality used by *bitcoinpurpled* and *bitcoinpurple-qt* executables. |
| *libbitcoinpurple_util*        | Home for common functionality shared by different executables and libraries. Similar to *libbitcoinpurple_common*, but lower-level (see [Dependencies](#dependencies)). |
| *libbitcoinpurple_wallet*      | Wallet functionality used by *bitcoinpurpled* and *bitcoinpurple-wallet* executables. |
| *libbitcoinpurple_wallet_tool* | Lower-level wallet functionality used by *bitcoinpurple-wallet* executable. |
| *libbitcoinpurple_zmq*         | [ZeroMQ](../zmq.md) functionality used by *bitcoinpurpled* and *bitcoinpurple-qt* executables. |

## Conventions

- Most libraries are internal libraries and have APIs which are completely unstable! There are few or no restrictions on backwards compatibility or rules about external dependencies. Exceptions are *libbitcoinpurple_consensus* and *libbitcoinpurple_kernel* which have external interfaces documented at [../shared-libraries.md](../shared-libraries.md).

- Generally each library should have a corresponding source directory and namespace. Source code organization is a work in progress, so it is true that some namespaces are applied inconsistently, and if you look at [`libbitcoinpurple_*_SOURCES`](../../src/Makefile.am) lists you can see that many libraries pull in files from outside their source directory. But when working with libraries, it is good to follow a consistent pattern like:

  - *libbitcoinpurple_node* code lives in `src/node/` in the `node::` namespace
  - *libbitcoinpurple_wallet* code lives in `src/wallet/` in the `wallet::` namespace
  - *libbitcoinpurple_ipc* code lives in `src/ipc/` in the `ipc::` namespace
  - *libbitcoinpurple_util* code lives in `src/util/` in the `util::` namespace
  - *libbitcoinpurple_consensus* code lives in `src/consensus/` in the `Consensus::` namespace

## Dependencies

- Libraries should minimize what other libraries they depend on, and only reference symbols following the arrows shown in the dependency graph below:

<table><tr><td>

```mermaid

%%{ init : { "flowchart" : { "curve" : "basis" }}}%%

graph TD;

bitcoinpurple-cli[bitcoinpurple-cli]-->libbitcoinpurple_cli;

bitcoinpurpled[bitcoinpurpled]-->libbitcoinpurple_node;
bitcoinpurpled[bitcoinpurpled]-->libbitcoinpurple_wallet;

bitcoinpurple-qt[bitcoinpurple-qt]-->libbitcoinpurple_node;
bitcoinpurple-qt[bitcoinpurple-qt]-->libbitcoinpurpleqt;
bitcoinpurple-qt[bitcoinpurple-qt]-->libbitcoinpurple_wallet;

bitcoinpurple-wallet[bitcoinpurple-wallet]-->libbitcoinpurple_wallet;
bitcoinpurple-wallet[bitcoinpurple-wallet]-->libbitcoinpurple_wallet_tool;

libbitcoinpurple_cli-->libbitcoinpurple_util;
libbitcoinpurple_cli-->libbitcoinpurple_common;

libbitcoinpurple_common-->libbitcoinpurple_consensus;
libbitcoinpurple_common-->libbitcoinpurple_util;

libbitcoinpurple_kernel-->libbitcoinpurple_consensus;
libbitcoinpurple_kernel-->libbitcoinpurple_util;

libbitcoinpurple_node-->libbitcoinpurple_consensus;
libbitcoinpurple_node-->libbitcoinpurple_kernel;
libbitcoinpurple_node-->libbitcoinpurple_common;
libbitcoinpurple_node-->libbitcoinpurple_util;

libbitcoinpurpleqt-->libbitcoinpurple_common;
libbitcoinpurpleqt-->libbitcoinpurple_util;

libbitcoinpurple_wallet-->libbitcoinpurple_common;
libbitcoinpurple_wallet-->libbitcoinpurple_util;

libbitcoinpurple_wallet_tool-->libbitcoinpurple_wallet;
libbitcoinpurple_wallet_tool-->libbitcoinpurple_util;

classDef bold stroke-width:2px, font-weight:bold, font-size: smaller;
class bitcoinpurple-qt,bitcoinpurpled,bitcoinpurple-cli,bitcoinpurple-wallet bold
```
</td></tr><tr><td>

**Dependency graph**. Arrows show linker symbol dependencies. *Consensus* lib depends on nothing. *Util* lib is depended on by everything. *Kernel* lib depends only on consensus and util.

</td></tr></table>

- The graph shows what _linker symbols_ (functions and variables) from each library other libraries can call and reference directly, but it is not a call graph. For example, there is no arrow connecting *libbitcoinpurple_wallet* and *libbitcoinpurple_node* libraries, because these libraries are intended to be modular and not depend on each other's internal implementation details. But wallet code is still able to call node code indirectly through the `interfaces::Chain` abstract class in [`interfaces/chain.h`](../../src/interfaces/chain.h) and node code calls wallet code through the `interfaces::ChainClient` and `interfaces::Chain::Notifications` abstract classes in the same file. In general, defining abstract classes in [`src/interfaces/`](../../src/interfaces/) can be a convenient way of avoiding unwanted direct dependencies or circular dependencies between libraries.

- *libbitcoinpurple_consensus* should be a standalone dependency that any library can depend on, and it should not depend on any other libraries itself.

- *libbitcoinpurple_util* should also be a standalone dependency that any library can depend on, and it should not depend on other internal libraries.

- *libbitcoinpurple_common* should serve a similar function as *libbitcoinpurple_util* and be a place for miscellaneous code used by various daemon, GUI, and CLI applications and libraries to live. It should not depend on anything other than *libbitcoinpurple_util* and *libbitcoinpurple_consensus*. The boundary between _util_ and _common_ is a little fuzzy but historically _util_ has been used for more generic, lower-level things like parsing hex, and _common_ has been used for bitcoinpurple-specific, higher-level things like parsing base58. The difference between util and common is mostly important because *libbitcoinpurple_kernel* is not supposed to depend on *libbitcoinpurple_common*, only *libbitcoinpurple_util*. In general, if it is ever unclear whether it is better to add code to *util* or *common*, it is probably better to add it to *common* unless it is very generically useful or useful particularly to include in the kernel.


- *libbitcoinpurple_kernel* should only depend on *libbitcoinpurple_util* and *libbitcoinpurple_consensus*.

- The only thing that should depend on *libbitcoinpurple_kernel* internally should be *libbitcoinpurple_node*. GUI and wallet libraries *libbitcoinpurpleqt* and *libbitcoinpurple_wallet* in particular should not depend on *libbitcoinpurple_kernel* and the unneeded functionality it would pull in, like block validation. To the extent that GUI and wallet code need scripting and signing functionality, they should be get able it from *libbitcoinpurple_consensus*, *libbitcoinpurple_common*, and *libbitcoinpurple_util*, instead of *libbitcoinpurple_kernel*.

- GUI, node, and wallet code internal implementations should all be independent of each other, and the *libbitcoinpurpleqt*, *libbitcoinpurple_node*, *libbitcoinpurple_wallet* libraries should never reference each other's symbols. They should only call each other through [`src/interfaces/`](`../../src/interfaces/`) abstract interfaces.

## Work in progress

- Validation code is moving from *libbitcoinpurple_node* to *libbitcoinpurple_kernel* as part of [The libbitcoinpurplekernel Project #24303](https://github.com/bitcoinpurple/bitcoinpurple/issues/24303)
- Source code organization is discussed in general in [Library source code organization #15732](https://github.com/bitcoinpurple/bitcoinpurple/issues/15732)
