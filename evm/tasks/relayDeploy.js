
module.exports = async (taskArgs,hre) => {
    const {deploy} = hre.deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    await deploy('MapoServiceRelayV3', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MapoServiceRelayV3'
    })

    let mosRelay = await ethers.getContract('MapoServiceRelayV3');

    console.log("MapoServiceRelayV3 impl address:",mosRelay.address);

    let data = mosRelay.interface.encodeFunctionData("initialize", [taskArgs.wrapped, taskArgs.lightnode]);

    await deploy('MapoServiceProxyV3', {
        from: deployer.address,
        args: [mosRelay.address,data],
        log: true,
        contract: 'MapoServiceProxyV3',
    })

    let mosRelayProxy = await ethers.getContract('MapoServiceProxyV3');

    console.log("MapoServiceProxyV3 address:",mosRelayProxy.address);

}