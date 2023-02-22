module.exports = async (taskArgs, hre) => {
    const {deploy} = hre.deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    await deploy('MAPOmnichainServiceV3', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MAPOmnichainServiceV3',
    })

    let mos = await ethers.getContract('MAPOmnichainServiceV3');

    console.log("MAPOmnichainServiceV3 address:", mos.address);


    let data = mos.interface.encodeFunctionData("initialize", [taskArgs.wrapped, taskArgs.lightnode]);

    await deploy('MAPOmnichainServiceProxyV3', {
        from: deployer.address,
        args: [mos.address, data],
        log: true,
        contract: 'MAPOmnichainServiceProxyV3',
    })

    let mosProxy = await ethers.getContract('MAPOmnichainServiceProxyV3');

    console.log("MAPOmnichainServiceProxyV3 address:", mosProxy.address)
}