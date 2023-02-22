
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let proxy = await hre.deployments.get("MAPOmnichainServiceProxyV3");

    console.log("mos address", proxy.address);

    let mos = await ethers.getContractAt('MAPOmnichainServiceV3', proxy.address);

    await (await mos.connect(deployer).setRelayContract( taskArgs.chain, taskArgs.relay)).wait();

    console.log(`mos set  relay ${taskArgs.relay} with chain id ${taskArgs.chain} successfully `);

}