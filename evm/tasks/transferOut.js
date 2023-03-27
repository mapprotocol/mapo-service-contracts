
function stringToHex(str) {
    return str.split("").map(function(c) {
        return ("0" + c.charCodeAt(0).toString(16)).slice(-2);
    }).join("");
}

module.exports = async (taskArgs) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    console.log("mos salt:", taskArgs.salt);

    let factory = await ethers.getContractAt("IDeployFactory",taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.salt));

    let mosAddress = await factory.getAddress(hash);

    let mos = await ethers.getContractAt('IMOSV3',mosAddress);

    let mDataBytes = await  ethers.utils.abiCoder.encode(false,0,taskArgs.target, taskArgs.calldata, taskArgs.gaslimit, taskArgs.value)

    await (await mos.connect(deployer).transferOut(
        taskArgs.chain,
        mDataBytes,
        "0x0000000000000000000000000000000000000000"
    )).wait();

    console.log(`${mosAddress} transfer out  ${taskArgs.target} to chain ${taskArgs.chain}  successful`);
}