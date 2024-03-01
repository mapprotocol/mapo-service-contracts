function stringToHex(str) {
    return str
        .split("")
        .map(function (c) {
            return ("0" + c.charCodeAt(0).toString(16)).slice(-2);
        })
        .join("");
}

module.exports = async (taskArgs, hre) => {
    const accounts = await ethers.getSigners();
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    console.log("mos salt:", taskArgs.salt);

    let factory = await ethers.getContractAt("IDeployFactory", taskArgs.factory);

    console.log("deploy factory address:", factory.address);

    let hash = await ethers.utils.keccak256(await ethers.utils.toUtf8Bytes(taskArgs.salt));

    let mosAddress = await factory.getAddress(hash);

    console.log("mos relay proxy address:", mosAddress);

    let mos = await ethers.getContractAt("MapoServiceRelayV3", mosAddress);

    let address = taskArgs.address;
    if (taskArgs.address.substring(0, 2) !== "0x") {
        address = "0x" + stringToHex(taskArgs.address);
    }

    await (await mos.connect(deployer).registerChain(taskArgs.chain, address, taskArgs.type)).wait();

    console.log(`mos relay register chain ${taskArgs.chain}  address ${address} success`);
};
