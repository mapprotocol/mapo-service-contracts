

module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    await deploy('MapoServiceRelayV3', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MapoServiceRelayV3',
    })

    let mosRelay = await ethers.getContract('MapoServiceRelayV3');

    console.log("MapoServiceRelayV3 up address:",mosRelay.address);

    let proxy = await deployments.get("MapoServiceProxyV3")

    let mosRelayProxy = await ethers.getContractAt('MapoServiceRelayV3',proxy.address);

    await (await mosRelayProxy.upgradeTo(mosRelay.address)).wait();

    console.log("MapoServiceRelayV3 up success");

}

module.exports.tags = ['MapoServiceRelayV3Up']