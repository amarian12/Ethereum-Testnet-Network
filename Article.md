# Setup testnet Ethereum network with Docker

> Ethereum is a decentralized platform that runs smart contracts: applications that run exactly as programmed without any possibility of downtime, censorship, fraud or third party interference.

This is step-by-step guide, how to setup testnet Ethereum network.

We'll setup ethereum testnet node in the docker container and write ruby json-rpc client.
The difference between __ethereum__(Frontier) and __testnet ethereum__(Ropsten) networks is that the testnet 
used for development. The genesis block on the testnet was set with a very low difficulty so anyone can do minning.
The coins mained in the testnet have no values. You can request some coins on the facuet or trying to mine it.

I assume you have got hand-on experience with Docker, also you’re knowing Ruby a little. 

Copy the source code from my [Github repository.](https://github.com/fishbullet/Ethereum-Private-Network)

Let's get stated from the Docker container, here is a Dockerfile which we'll use:

```Dockerfile
FROM ubuntu:16.04

LABEL version="1.0"
LABEL maintainer="shindu666@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes software-properties-common
RUN add-apt-repository ppa:ethereum/ethereum
RUN apt-get update && apt-get install --yes geth

RUN adduser --disabled-login --gecos "" eth_user

USER eth_user
WORKDIR /home/eth_user

ENTRYPOINT bash
```

Now build an image:

```bash
docker build -t ether_node .
# Output omitted
# ...
```

After the building process, let's start it:

```bash
docker run --rm -it -p 8545:8545 ether_node
# Output omitted
# ...
```

Now we need to start our node to use testnet.

From the docker container:

```bash
eth_user@866a730c6a8f:~$ geth --rpc --rpcaddr="0.0.0.0" --testnet --fast --cache=512 console
WARN [xx-xx|xx:xx:xx] No etherbase set and no accounts found as default 
INFO [xx-xx|xx:xx:xx] Starting peer-to-peer node               instance=Geth/v1.7.2-stable-1db4ecdc/linux-amd64/go1.9
INFO [xx-xx|xx:xx:xx] Allocated cache and file handles         database=/home/eth_user/.ethereum/testnet/geth/chaindata cache=512 handles=1024
INFO [xx-xx|xx:xx:xx] Initialised chain configuration          config="{ChainID: 3 Homestead: 0 DAO: <nil> DAOSupport: true EIP150: 0 EIP155: 10 EIP158: 10 Byzantium: 1700000 Engine: ethash}"
INFO [xx-xx|xx:xx:xx] Disk storage enabled for ethash caches   dir=/home/eth_user/.ethereum/testnet/geth/ethash count=3
INFO [xx-xx|xx:xx:xx] Disk storage enabled for ethash DAGs     dir=/home/eth_user/.ethash                       count=2
INFO [xx-xx|xx:xx:xx] Initialising Ethereum protocol           versions="[63 62]" network=3
INFO [xx-xx|xx:xx:xx] Loaded most recent local header          number=1934866 hash=480bc8…021ca1 td=6358565226576368
INFO [xx-xx|xx:xx:xx] Loaded most recent local full block      number=1934867 hash=a61065…492947 td=6358586381670544
INFO [xx-xx|xx:xx:xx] Loaded most recent local fast block      number=1934866 hash=480bc8…021ca1 td=6358565226576368
INFO [xx-xx|xx:xx:xx] Loaded local transaction journal         transactions=0 dropped=0
INFO [xx-xx|xx:xx:xx] Regenerated local transaction journal    transactions=0 accounts=0
WARN [xx-xx|xx:xx:xx] Blockchain not empty, fast sync disabled 
# ....
```

Note about `geth` command line options:

- `--rpc` enable RPC
- `--rpcaddr="0.0.0.0"` HTTP-RPC server listening interface (default: "localhost")
- `--testnet` Ropsten network: pre-configured test network
- `--fast` Enable fast syncing through state downloads
- `--cache=512` Megabytes of memory allocated to internal caching
- `console` Start an interactive JavaScript environment

Documentation for all other command line options you can find [here](https://github.com/ethereum/go-ethereum/wiki/Command-Line-Options)

The next step, the database synchronization.
That process can be long. In my case I was waiting at least 5 hours before got the last block.

As long as you see in the logs `INFO [00-00|XX:XX:XX] Imported new state entries ....` the network is syncing.

To get rid of annoying log entries like `INFO .....`, stop syncing and start again with `--verbosity=2` options.

```bash
eth_user@866a730c6a8f:~$ geth --rpc --rpcaddr="0.0.0.0" --testnet --fast --cache=512 --verbosity=2 console
WARN [xx-xx|xx:xx:xx] No etherbase set and no accounts found as default 
WARN [xx-xx|xx:xx:xx] Blockchain not empty, fast sync disabled 
Welcome to the Geth JavaScript console!

instance: Geth/v1.7.2-stable-1db4ecdc/linux-amd64/go1.9
modules: admin:1.0 debug:1.0 eth:1.0 miner:1.0 net:1.0 personal:1.0 rpc:1.0 txpool:1.0 web3:1.0

> 
```

The synchronization process can be long, you can check progress with command `eth.syncing`, if syncing is on going you must see:

```json
{                         
  currentBlock: 1032920,  
  highestBlock: 1934940,  
  knownStates: 8621554,   
  pulledStates: 8618011,  
  startingBlock: 3926371  
} 
```

Your actual output must be differ. Check last block here [ropsten.etherscan.io](https://ropsten.etherscan.io/).

If you're lucky guy and your waiting is complete, you'll see `INFO [xx-xx|xx:xx:xx] Imported new chain segment  ...` entries in the log.
The command `eth.syncing` retruns `false` and command `eth.blockNumber` returns the same block number as on [ropsten.etherscan.io](https://ropsten.etherscan.io/) (+\- 2 or 3 blocks).

Now let's create a brand new address and send to it some of ether from faucets.

In order to create a new account we'll use `geth` console and the [`personal_newAccount()`](https://github.com/ethereum/go-ethereum/wiki/Management-APIs#personal_newaccount) method.

```js
> personal.newAccount("foo")
"0xd46c9fb0447dabc0d862141e817039fedbb653b0"
>
```
With the new account send to it some ether by faucet. In my case I'm using [this faucet](http://faucet.ropsten.be:3001/).

We'll check the account balance with JSON-RPC client written by Ruby language (from the `json_rpc_client` folder):

<sub> You might need to install script dependencies, check out the README.md file. </sub>

```bash
$> ruby client.rb "0xd46c9fb0447dabc0d862141e817039fedbb653b0"
Address: 0xd46c9fb0447dabc0d862141e817039fedbb653b0 balance: 0
Sleep 3 second ...
Address: 0xd46c9fb0447dabc0d862141e817039fedbb653b0 balance: 0
Sleep 3 second ...
Address: 0xd46c9fb0447dabc0d862141e817039fedbb653b0 balance: 0
Sleep 3 second ...
Address: 0xd46c9fb0447dabc0d862141e817039fedbb653b0 balance: 3
```

Cheers! The account is filled with 3 ether. You also can check the account balance here [`ropsten etherscan`](https://ropsten.etherscan.io/).

We have got up and running docker container with Ethereum testnet network (AKA Ropsten) and we able to
communicate with our node by JSON-RPC client written by Ruby.
It's a good start to create your own blockchain project based on Ethereum.

References:
- https://ethereum.gitbooks.io/frontier-guide/content/index.html
- http://www.ethdocs.org/en/latest/introduction/index.html
- https://github.com/ethereum/wiki/wiki
- https://github.com/ethereum/go-ethereum/wiki

<sub>P.S. forgive me my bad English, it’s not my native language.</sub>

