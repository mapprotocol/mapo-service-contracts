//const {ethers} = require("hardhat");
module.exports = async (taskArgs, hre) => {
    const { deploy } = hre.deployments;
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    await deploy("MapoServiceV3", {
        from: deployer.address,
        args: [],
        log: true,
        contract: "MapoServiceV3",
    });

    let mos = await ethers.getContract("MapoServiceV3");

    console.log("MapoServiceV3 address:", mos.address);

    let data = mos.interface.encodeFunctionData("initialize", [taskArgs.wrapped, taskArgs.lightnode]);

    let mosProxy = await ethers.getContractFactory("MapoServiceProxyV3");

    let initData = await ethers.utils.defaultAbiCoder.encode(["address", "bytes"], [mos.address, data]);

    let deployData = mosProxy.bytecode + initData.substring(2);
    console.log("mos salt:", taskArgs.salt);
    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.salt));

    let factory = await ethers.getContractAt("IDeployFactory", taskArgs.factory);

    console.log("deploy factory address:", factory.address);

    await (await factory.connect(deployer).deploy(hash, deployData, 0)).wait();

    let mosProxyAddress = await factory.connect(deployer).getAddress(hash);

    console.log("deployed mos proxy address:", mosProxyAddress);

    let proxy = await ethers.getContractAt("MapoServiceV3", mosProxyAddress);

    let owner = await proxy.connect(deployer).getAdmin();

    console.log(`MapoServiceV3 Proxy contract address is ${mosProxyAddress}, init admin address is ${owner}`);
};
