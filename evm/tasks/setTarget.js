
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let proxy = await hre.deployments.get("Echo");

    console.log("mos address", proxy.address);

    let echo = await ethers.getContractAt('Echo', proxy.address);

    await (await echo.connect(deployer).setTarget(taskArgs.target,taskArgs.chainid)).wait();

    console.log(`echo set chain id  ${taskArgs.chainid}  target address ${taskArgs.target} successfully `);

}