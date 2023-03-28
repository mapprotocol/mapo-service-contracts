
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    console.log("mos salt:", taskArgs.salt);

    let factory = await ethers.getContractAt("IDeployFactory",taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.salt));

    let mosAddress = await factory.getAddress(hash);

    console.log("mos proxy address:",mosAddress)

    let mos = await ethers.getContractAt('MapoServiceV3', mosAddress);

    await (await mos.connect(deployer).setLightClient(taskArgs.client)).wait();

    console.log(`mos ${mosAddress} set  light client ${taskArgs.client} successfully `);

}