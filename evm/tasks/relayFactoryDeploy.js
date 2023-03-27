
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

    let mosProxy = await ethers.getContractFactory('MapoServiceProxyV3');

    let initData = await ethers.utils.defaultAbiCoder.encode(
        ["address","bytes"],
        [mosRelay.address,data]
    )

    let deployData = mosProxy.bytecode + initData.substring(2);

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.salt));

    let factory = await ethers.getContractAt("IDeployFactory", taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    await (await factory.connect(deployer).deploy(hash,deployData,0)).wait();

    let mosProxyAddress = await factory.connect(deployer).getAddress(hash)

    console.log("deployed mos relay proxy address:", mosProxyAddress)

    let proxy = await ethers.getContractAt('MapoServiceV3', mosProxyAddress);

    let owner = await proxy.connect(deployer).getAdmin();

    console.log(`MapoServiceRelayV3 Proxy contract address is ${mosProxyAddress}, init admin address is ${owner}, deploy contract salt is ${hash}`)


}