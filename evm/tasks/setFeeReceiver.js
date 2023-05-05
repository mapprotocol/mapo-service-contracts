
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    console.log("fee salt:", taskArgs.feesalt);

    let factory = await ethers.getContractAt("IDeployFactory",taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.feesalt));

    let feeServiceAddress = await factory.getAddress(hash);

    console.log("fee service address:", feeServiceAddress)

    let fee = await ethers.getContractAt('FeeService', feeServiceAddress);

    await (await fee.connect(deployer).setFeeReceiver(taskArgs.address)).wait();

    console.log(`FeeService set  receiver address is ${taskArgs.address} successfully `);

}