
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    console.log("mos address", taskArgs.mosAddress);

    let mos = await ethers.getContractAt('MapoServiceV3',taskArgs.mosAddress);

    await (await mos.connect(deployer).setFeeService(taskArgs.address)).wait();

    console.log(`mos set  message fee service address ${taskArgs.address} successfully `);

}