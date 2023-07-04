# MOS Message Contracts

MOS message is a MOS(MAPO Service), MAP Protocol omnichain messaging service, it enables DApp built on one chain to easily interoperate other chains.

![MOS Message](https://raw.githubusercontent.com/mapprotocol/docs/master/develop/mos/message/croosChainMessage.png)

With MOS message you can achieve interoperation with two chains:
* Call a contract on chain B from chain A.
* Pack the message changes in chain A and write them into chain B to realize message synchronization

For examples built on MOS message, visit [omnichain examples](https://github.com/mapprotocol/omnichain-examples).

## MAPO Service

MAP Protocol is the omnichain layer of Web3, a cross-chain interoperable protocol to empower Web3 apps to thrive in the omnichain future.

MAPO Service (MOS) provides common modules needed by cross-chain DApps to further lower the threshold of building cross-chain DApps with MAP protocol. 

![Illustration of MAP Protocol's MAPO Services (MOS) Layer](https://raw.githubusercontent.com/mapprotocol/docs/master/learn/Teachnical_Mechanism/mcs_final.png)

Visit [docs](https://docs.mapprotocol.io/learn/overiew/mcs) for more MOS information.

## Installation

```shell
npm install --save-dev @mapprotocol/mos
# or
yarn add --dev @mapprotocol/mos
```

## Instruction
MapoServiceV3 contract is suitable for evm-compatible chains and implements cross-chain logic

MapoServiceRelayV3 contract implements cross-chain logic and basic cross-chain control based on MAP Relay Chain

FeeService contract is used to manage cross-chain fees.

## Build

Copy file .env.example to .env and configure:
* PRIVATE_KEY - User-deployed private key
* INFURA_KEY - User-deployed infura key
* MOS_SALT - User-deployed mos contract salt
* FEE_SALT - User-deployed fee service contract salt
* DEPLOY_FACTORY - Factory-contract address

```shell
git clone https://github.com/mapprotocol/mapo-service-contracts.git
cd mapo-service-contracts/evm
npm install
```

### Test

```shell
npx hardhat test
```

### Deploy

#### MOS Relay Contract
The following steps help to deploy MOS Relay contracts on MAPO Relay Chain.

1. Deploy Message fee

```
npx hardhat feeFactoryDeploy --network <network>
````

2. Deploy MOS Relay

```
npx hardhat relayFactoryDeploy --wrapped <wrapped token> --lightnode <lightNodeManager address> --network <network>
````

* `wrapped token` is wrapped MAP token address on MAPO Mainnet or Makalu testnet.
* `lightNodeManager address` is the light client manager address deployed on MAP mainnet or MAP Makalu. See [here](https://github.com/mapprotocol/map-contracts/protocol/README.md) for more information.

3. Init MOS Relay

```
npx hardhat setFeeService  --address <message fee service address> --network <network>
````

#### MOS on EVM Chains

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


### Configure

#### Register

* Register an EVM compatiable chain
```
npx hardhat relayRegisterChain --address <MOS address> --chain <chain id> --network <network>
```

* Register a non-EVM chain

```
npx hardhat relayRegisterChain --address <MOS address> --chain <near chain id> --type 2 --network <network>
```
**notice** Now non-evm chain only support Near Protocol.


#### Set message fee

```
npx hardhat setMessageFee --chainid <to chain id> --base <Cross-chain base limit>  --price <gas price> --tokenaddress <The default is native token, can be filled in token address> --network <network>
```

In the FeeService mechanism, there will be base baseGas and a different chainGasPrice for each chain, which is the basis for determining how much Fee to charge for each cross chain.

The cross-chain fee calculation:
```
(baseGas + gasLimit) * chainGasPrice
```
gasLimit is determined by the user who calls the transferOut method and is at least 21000 and at most 10000000

### Upgrade

When upgrade the mos contract through the following commands.

Please execute the following command on the EVM compatible chain

```
npx hardhat deploy --tags MapoServiceV3Up --network <network>
```

Please execute the following command on relay chain mainnet or Makalu testnet
```
npx hardhat deploy --tags MapoServiceRelayV3Up --network <network>
```

### Message cross-chain transfer

1.  transfer out
```
npx hardhat transferOut  --target <to chain target address> --calldata <call data> --chain <to chain id> --network <network>
```

