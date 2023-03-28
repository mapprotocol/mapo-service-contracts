
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    console.log("fee salt:", taskArgs.feesalt);

    let factory = await ethers.getContractAt("IDeployFactory",taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.feesalt));

    let feeAddress = await factory.getAddress(hash);

    let fee = await ethers.getContractAt('FeeService',feeAddress);

    await (await fee.connect(deployer).setFeeReceiver(taskArgs.address)).wait();

    console.log(`FeeService ${feeAddress} set  receiver address is ${taskArgs.address} successfully `);

}