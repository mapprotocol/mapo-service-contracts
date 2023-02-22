module.exports = async (taskArgs, hre) => {
    const {deploy} = hre.deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    await deploy('MapoServiceV3', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MapoServiceV3',
    })

    let mos = await ethers.getContract('MapoServiceV3');

    console.log("MapoServiceV3 address:", mos.address);


    let data = mos.interface.encodeFunctionData("initialize", [taskArgs.wrapped, taskArgs.lightnode]);

    await deploy('MapoServiceProxyV3', {
        from: deployer.address,
        args: [mos.address, data],
        log: true,
        contract: 'MapoServiceProxyV3',
    })

    let mosProxy = await ethers.getContract('MapoServiceProxyV3');

    console.log("MapoServiceProxyV3 address:", mosProxy.address)
}