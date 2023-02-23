
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let proxy = await hre.deployments.get("FeeService");

    console.log("FeeService address", proxy.address);

    let feeService = await ethers.getContractAt('FeeService', proxy.address);

    await (await feeService.connect(deployer).setMessageFee(taskArgs.chainid,taskArgs.target,taskArgs.fee)).wait();

    console.log(` Set the fee for ${taskArgs.chainid} ${taskArgs.target} to ${taskArgs.fee} `);

}