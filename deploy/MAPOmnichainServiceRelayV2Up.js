

module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    await deploy('MAPOmnichainServiceRelayV3', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MAPOmnichainServiceRelayV3',
    })

    let mosRelay = await ethers.getContract('MAPOmnichainServiceRelayV3');

    console.log("MAPOmnichainServiceRelayV3 up address:",mosRelay.address);

    let proxy = await deployments.get("MAPOmnichainServiceProxyV3")

    let mosRelayProxy = await ethers.getContractAt('MAPOmnichainServiceRelayV3',proxy.address);

    await (await mosRelayProxy.upgradeTo(mosRelay.address)).wait();

    console.log("MAPOmnichainServiceRelayV3 up success");

}

module.exports.tags = ['MAPOmnichainServiceRelayV3Up']