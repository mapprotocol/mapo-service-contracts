
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    //let proxy = taskArgs.mosAddress;

    console.log("mos address", taskArgs.mosAddress);

    let mos = await ethers.getContractAt('MapoServiceV3', taskArgs.mosAddress);

    await (await mos.connect(deployer).setRelayContract( taskArgs.chain, taskArgs.relay)).wait();

    console.log(`mos set  relay ${taskArgs.relay} with chain id ${taskArgs.chain} successfully `);

}