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

## Instruction
MAPOmnichainServiceV3 contract is suitable for evm-compatible chains and implements cross-chain logic

MAPOmnichainServiceRelayV3 contract implements cross-chain logic and basic cross-chain control based on MAP Relay Chain

TokenRegisterV3 contract is used to control the mapping of cross-chain tokens

## Build

```shell
git clone https://github.com/mapprotocol/mapo-service-contracts.git
cd mapo-service-contracts/
npm install
```

## Test

```shell
npx hardhat test
```



## Deploy

### MOS Relay
The following steps help to deploy MOS relay contracts on Map mainnet or Makalu testnet

1. Deploy Message fee
```
npx hardhat deploy --tags MessageFee --network <network>
````
2. Deploy MOS Relay

```
npx hardhat relayDeploy --wrapped <wrapped token> --lightnode <lightNodeManager address> --network <network>
````

* `wrapped token` is wrapped MAP token address on MAP mainnet or MAP Makalu.
* `lightNodeManager address` is the light client mananger address deployed on MAP mainnet or MAP Makalu. See [here](../protocol/README.md) for more information.

3. Init MOS Relay
```
npx hardhat setMessageAddress  --messagefee <message fee address> --network <network>
````

### MOS on EVM Chains

1. Deploy
```
npx hardhat mosDeploy --wrapped <native wrapped address> --lightnode <lightnode address> --network <network>
```

2. Set MOS Relay Address
   The following command on the EVM compatible chain
```
npx hardhat mosSetRelay --relay <Relay address> --chain <map chainId> --network <network>
```
3. Init MOS
```
npx hardhat setMessageAddress  --messagefee <message fee address> --network <network>
````

4. Register
   The following command applies to the cross-chain contract configuration of Map mainnet and Makalu testnet
```
npx hardhat relayRegisterChain --address <MAPOmnichainService address> --chain <chain id> --network <network>
```

### MOS on other chain

The following four commands are generally applicable to Map mainnet and Makalu testnet
```
npx hardhat relayRegisterChain --address <MAPOmnichainService address> --chain <near chain id> --type 2 --network <network>
```

## Configure

### Message fee


1. Set message fee
```
npx hardhat setMessageFee --fee <fee number> --chain <to chain id>  --target <to chain address> --network <network>
```


## Upgrade

When upgrade the mos contract through the following commands.

Please execute the following command on the EVM compatible chain

```
npx hardhat deploy --tags MAPOmnichainServiceV3Up --network <network>
```

Please execute the following command on relay chain mainnet or Makalu testnet
```
npx hardhat deploy --tags MAPOmnichainServiceRelayV3Up --network <network>
```

## Message cross-chain transfer

1.  transfer out
```
npx hardhat transferOut --mos <mos or relay address> --target <to chain target address> --calldata <call data> --chain <to chain id> --network <network>
```


## List token mapped chain

1. relay chain
```
npx hardhat relayList --relay <relay address> --token <token address> --network <network>
```

2. altchains
```
npx hardhat mosList --mos <relay address> --token <token address> --network <network>
```

## Echo details

1. deploy echo

```
npx hardhat deployEcho --mos <optional mos address> --network <network>
```
2. set chainId target address
```
npx hardhat setTarget --chainid <chain id> --target <target address> --network <network>
```

## Echo game

1. query key

```
npx hardhat getEcho --echoAddress <echo address> --key <key> --network <network>
```
2. send echo

```
npx hardhat sendEcho --echoAddress <echo address> --key <key> --value <echo value> --network <network>
```