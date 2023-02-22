module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
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


    let proxy = await deployments.get("MAPOmnichainServiceProxyV3");
    let mosProxy = await ethers.getContractAt('MAPOmnichainServiceV3', proxy.address);

    await (await mosProxy.upgradeTo(mos.address)).wait();

    console.log("MAPOmnichainServiceV3 up success")
}

module.exports.tags = ['MAPOmnichainServiceV3Up']