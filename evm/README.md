# mapo-service-contracts

## Setup Instructions
Edit the .env-example.txt file and save it as .env

The following node and npm versions are required
````
$ node -v
v14.17.1
$ npm -v
6.14.13
````

Configuration file description

PRIVATE_KEY User-deployed private key

INFURA_KEY User-deployed infura key

MOS_SALT User-deployed mos contract salt

FEE_SALT User-deployed fee swrvice contract salt

DEPLOY_FACTORY Factory-contract address

## Instruction
MapoServiceV3 contract is suitable for evm-compatible chains and implements cross-chain logic

MapoServiceRelayV3 contract implements cross-chain logic and basic cross-chain control based on MAP Relay Chain

FeeService contracts are used to control cross-chain fees

## Build

```shell
git clone https://github.com/mapprotocol/mapo-service-contracts.git
cd mapo-service-contracts/evm
npm install
```

## Test

```shell
npx hardhat test
```



## Deploy

### MOS Relay Contract
The following steps help to deploy MOS Relay contracts on MAPO Relay Chain.

1. Deploy Message fee
```
npx hardhat feeFactoryDeploy --network <network>
````
2. Deploy MOS Relay

```
npx hardhat relayFactoryDeploy --wrapped <wrapped token> --lightnode <lightNodeManager address> --network <network>
````

* `wrapped token` is wrapped MAP token address on MAP mainnet or MAP Makalu testnet.
* `lightNodeManager address` is the light client mananger address deployed on MAP mainnet or MAP Makalu. See [here](https://github.com/mapprotocol/map-contracts/protocol/README.md) for more information.

3. Init MOS Relay
```
npx hardhat setFeeService  --address <message fee service address> --network <network>
````

### MOS on EVM Chains

1. Deploy
```
npx hardhat mosFactoryDeploy --wrapped <native wrapped address> --lightnode <lightnode address> --network <network>
```

2. Set MOS Relay Address
   The following command on the EVM compatible chain
```
npx hardhat mosSetRelay --relay <Relay address> --chain <map chainId> --network <network>
```
3. Init MOS
```
npx hardhat setFeeService  --address <message fee service address> --network <network>
````

4. Register
   The following command applies to the cross-chain contract configuration of Map mainnet and Makalu testnet
```
npx hardhat relayRegisterChain --address <MOS address> --chain <chain id> --network <network>
```

### MOS on other chain

The following four commands are generally applicable to Map mainnet and Makalu testnet
```
npx hardhat relayRegisterChain --address <MOS address> --chain <near chain id> --type 2 --network <network>
```

## Configure

### Message fee


1. Set message fee
```
npx hardhat setMessageFee --chainid <to chain id> --baselimit <Cross-chain base limit>  --price <gas price> --tokenaddress <The default is native token, can be filled in token address> --network <network>
```


## Upgrade

When upgrade the mos contract through the following commands.

Please execute the following command on the EVM compatible chain

```
npx hardhat deploy --tags MapoServiceV3Up --network <network>
```

Please execute the following command on relay chain mainnet or Makalu testnet
```
npx hardhat deploy --tags MapoServiceRelayV3Up --network <network>
```

## Message cross-chain transfer

1.  transfer out
```
npx hardhat transferOut  --target <to chain target address> --calldata <call data> --chain <to chain id> --network <network>
```

