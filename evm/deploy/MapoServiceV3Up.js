module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
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


    let proxy = await deployments.get("MapoServiceProxyV3");
    let mosProxy = await ethers.getContractAt('MapoServiceV3', proxy.address);

    await (await mosProxy.upgradeTo(mos.address)).wait();

    console.log("MapoServiceV3 up success")
}

module.exports.tags = ['MapoServiceV3Up']