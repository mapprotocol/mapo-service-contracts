
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    console.log("fee salt:", taskArgs.salt);

    let factory = await ethers.getContractAt("IDeployFactory",taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.salt));

    let feeServiceAddress = await factory.getAddress(hash);

    console.log("fee service address:", feeServiceAddress)

    let feeService = await ethers.getContractAt('FeeService', feeServiceAddress);

    await (await feeService.connect(deployer).setBaseGas(taskArgs.chainid,taskArgs.base)).wait();
    await (await feeService.connect(deployer).setChainGasPrice(taskArgs.chainid, taskArgs.token, taskArgs.price)).wait();

    console.log(`Fee service set the fee for ${taskArgs.chainid} ${taskArgs.token} to price is ${taskArgs.price} and  baselimit is ${taskArgs.base}`);

}