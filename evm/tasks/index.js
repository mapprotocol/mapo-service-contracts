
task("mosDeploy",
    "Deploy the upgradeable MapCrossChainService contract and initialize it",
    require("./mosDeploy")
)
    .addParam("wrapped", "native wrapped token address")
    .addParam("lightnode", "lightNode contract address")

task("relayDeploy",
    "Deploy the upgradeable MapCrossChainServiceRelay contract and initialize it",
    require("./relayDeploy")
)
    .addParam("wrapped", "native wrapped token address")
    .addParam("lightnode", "lightNodeManager contract address")


task("mosSetRelay",
    "Initialize MapCrossChainServiceRelay address for MapCrossChainService",
    require("./mosSetRelay")
)
    .addParam("relay", "map chain relay contract address")
    .addParam("chain", "map chain id")

task("mosSetClient",
    "Set light client address for MapCrossChainService",
    require("./mosSetClient")
)
    .addParam("client", "light client address")


task("mosRegisterChain",
    "MapCrossChainService settings allow cross-chain tokens",
    require("./mosRegisterChain")
)
    .addParam("token", "token address")
    .addParam("chains", "chain ids allowed to cross, separated by ',', ex. `1,2,3` ")
    .addOptionalParam("enable", "true or false", true, types.boolean)


task("relaySetClientManager",
    "Update client manager",
    require("./relaySetClientManager")
)
    .addParam("manager","client manager contract")

task("relayRegisterChain",
    "Register altchain mos to relay chain",
    require("./relayRegisterChain")
)
    .addParam("address", "mos contract address")
    .addParam("chain", "chain id")
    .addOptionalParam("type", "chain type, default 1", 1, types.int)


task("transferOut",
    "Cross-chain transfer out",
    require("./transferOut")
)
    .addParam("mos", "the mos address")
    .addParam("target", "The target address")
    .addParam("calldata", "call data")
    .addOptionalParam("gaslimit", "The receiver address, default is msg.sender",5000000,types.int)
    .addOptionalParam("value", "transfer value, unit WEI",0,types.int)
    .addParam("chain", "target chain id")


task("addWhiteList",
    "Cross-chain add white list",
    require("./addWhiteList")
)
    .addParam("whitelist","This is a whitelist address")
    .addOptionalParam("tag","Default to true","true")

task("setMessageAddress",
    "Set message fee address ",
    require("./mosSetMessageAddress")
)
    .addParam("messagefee", "message fee address")

task("withdraw",
    "withdraw token",
    require("./withdraw")
)
    .addParam("mos", "The mos address")
    .addOptionalParam("token", "The token address","0x0000000000000000000000000000000000000000",types.string)
    .addOptionalParam("address", "The receiver address","",types.string)
    .addParam("value", "withdraw value")


task("setMessageFee",
    "set chain message fee",
    require("./setMessageFee")
)
    .addParam("fee", "Expenses to be fee")
    .addParam("target", "Target chain execution address")
    .addParam("chain", "to chain id")

task("relayList",
    "List mos relay infos",
    require("./relayList")
)
    .addOptionalParam("relay", "The mos address, default mos", "relay", types.string)
    .addOptionalParam("token", "The token address, default wtoken", "wtoken", types.string)

task("mosList",
    "List mos relay infos",
    require("./mosList")
)
    .addOptionalParam("mos", "The mos address, default mos", "mos", types.string)
    .addOptionalParam("token", "The token address, default wtoken", "wtoken", types.string)

task("customData",
    "Construct multi-sign data",
    require("./customData")
)
    .addParam("method", "The name of the method you want to propose")
    .addParam("methodarg", "You want the method parameters for the proposal,multiple parameters are distinguished by commas ',' in sequence")
    .addOptionalParam("safeaddress", "This is the gnosis safe multi-sign address","0x21624d0634c696f6c357cBd8c5B7f629aFf045f7",types.string)
    .addOptionalParam("targetaddress", "Execute the target contract address","0xEd26be082C8145081085Ca58d01e8F2a633fBd03",types.string)
    .addOptionalParam("valuenum", " value","0",types.string)
    .addOptionalParam("delaynum", "How long is the delay","50",types.string)
    .addOptionalParam("ctype", "The type of contract you want to execute(mos,relay,register)","relay",types.string)
    .addOptionalParam("timelockaddress", "The time lock contract address","0x6559AfD04c08d8ebF6c45f0C750237D04f80a8A2",types.string)

task("executeTimeLock",
    "Run timelock execute",
    require("./executeTimeLock")

)
    .addParam("executeid","This is using Gnosis safe's nonce as credential")
    .addOptionalParam("timelockaddress", "withdraw value","0x6559AfD04c08d8ebF6c45f0C750237D04f80a8A2",types.string)

task("timeLockCreate",
    "Create a timelock contract",
    require("./timeLockCreate")
)
    .addParam("salt", "This is a bytes32 salt")
    .addOptionalParam("factory", "This is the deployment factory contract address","0x22Be25989dE6EC15e3A1E8A9F5204333554318dC",types.string)
    .addOptionalParam("timenum", "It's just minimal latency","50",types.string)
    .addOptionalParam("proposer", "Has the PROPOSER_ROLE permission address","0x49d6Dae5D59B3aF296DF35BDc565371c8A563ef6,0x21624d0634c696f6c357cBd8c5B7f629aFf045f7",types.string)
    .addOptionalParam("executor", " Has the EXECUTOR_ROLE permission address","0x49d6Dae5D59B3aF296DF35BDc565371c8A563ef6,0x21624d0634c696f6c357cBd8c5B7f629aFf045f7",types.string)
    .addOptionalParam("admin", "Administrator address","0x49d6Dae5D59B3aF296DF35BDc565371c8A563ef6",types.string)
    .addOptionalParam("valuenum", "Whether a transfer is required when the contract is created","0",types.string)

task("createMultipleSignature",
    "Create a mutil signture address",
    require("./createMultipleSignature")
)
    .addOptionalParam("multiuser", "This is the address of the multiple signers","0xdf713d32535126f3489431711be238DCA44DC808,0x5B5Ec267f388181627020486d88032ef65CB05ca,0x49d6Dae5D59B3aF296DF35BDc565371c8A563ef6",types.string)
    .addOptionalParam("safeaddress", "Gnosis safe factory contract address","0xa6b71e26c5e0845f74c812102ca7114b6a896ab2",types.string)
    .addOptionalParam("threshold", "Multiple sign weight","2",types.string)
    .addOptionalParam("saltnonce", " Create multiple of salt","22776",types.string)

