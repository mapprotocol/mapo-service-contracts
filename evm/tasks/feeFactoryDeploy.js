//const {ethers} = require("hardhat");
module.exports = async (taskArgs, hre) => {
    const {deploy} = hre.deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    let FeeService = await ethers.getContractFactory('FeeService');


    let deployData = FeeService.bytecode;

    console.log("mos salt:", taskArgs.feesalt);
    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.feesalt));

    let factory = await ethers.getContractAt("IDeployFactory",taskArgs.factory)

    console.log("deploy factory address:",factory.address)

    await (await factory.connect(deployer).deploy(hash,deployData,0)).wait();

    let feeServiceAddress = await factory.connect(deployer).getAddress(hash)

    console.log("deployed fee service address:", feeServiceAddress)

    let feeService = await ethers.getContractAt('FeeService', feeServiceAddress);

     await (await feeService.connect(deployer).initialize()).wait();

    let owner = await feeService.connect(deployer).owner();

    console.log(`FeeService  contract address is ${feeServiceAddress}, init admin address is ${owner}, deploy contract salt is ${hash}`)

}
