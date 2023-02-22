
module.exports = async (taskArgs,hre) => {
    const {deploy} = hre.deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    await deploy('MAPOmnichainServiceRelayV3', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MAPOmnichainServiceRelayV3'
    })

    let mosRelay = await ethers.getContract('MAPOmnichainServiceRelayV3');

    console.log("MAPOmnichainServiceRelayV3 address:",mosRelay.address);

    let data = mosRelay.interface.encodeFunctionData("initialize", [taskArgs.wrapped, taskArgs.lightnode]);

    await deploy('MAPOmnichainServiceProxyV3', {
        from: deployer.address,
        args: [mosRelay.address,data],
        log: true,
        contract: 'MAPOmnichainServiceProxyV3',
    })

    let mosRelayProxy = await ethers.getContract('MAPOmnichainServiceProxyV3');

    console.log("MAPCrossChainServiceRelayProxy address:",mosRelayProxy.address);

}