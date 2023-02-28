module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    await deploy('Echo', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'Echo'
    })

    let echo = await ethers.getContract('Echo');

    console.log("Echo address:",echo.address);

    let proxy = await deployments.get("MapoServiceProxyV3")

    console.log("mos address", proxy.address);

    await (await echo.connect(deployer).setMapoService(proxy.address)).wait()

    await (await echo.connect(deployer).setWhiteList(proxy.address)).wait()
}

module.exports.tags = ['Echo']