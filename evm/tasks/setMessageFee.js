
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let proxy = await hre.deployments.get("MessageFee");

    console.log("MessageFee address", proxy.address);

    let messageFee = await ethers.getContractAt('MessageFee', proxy.address);

    await (await messageFee.connect(deployer).setMessageFee(taskArgs.chainid,taskArgs.target,taskArgs.fee)).wait();

    console.log(` Set the fee for ${taskArgs.chainid} ${taskArgs.target} to ${taskArgs.fee} `);

}