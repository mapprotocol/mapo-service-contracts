
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let proxy = await hre.deployments.get("MAPOmnichainServiceProxyV3");

    console.log("mos address", proxy.address);

    let mos = await ethers.getContractAt('MAPOmnichainServiceV3', proxy.address);

    await (await mos.connect(deployer).addWhiteList(taskArgs.whitelist,taskArgs.tag)).wait();

    console.log(`mos add whiteList ${taskArgs.whitelist} successfully `);

}