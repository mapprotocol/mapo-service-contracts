
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let echoContract = await ethers.getContractAt('Echo', taskArgs.echoAddress);

    if (taskArgs.target === "0x00"){
        let targetAddress = await echoContract.TargetList(taskArgs.chainid);

        await (await echoContract.connect(deployer).echo(
            taskArgs.chainid,
            targetAddress,
            taskArgs.key,
            taskArgs.value
        )).wait();
    }else{
        await (await echoContract.connect(deployer).echo(
            taskArgs.chainid,
            taskArgs.target,
            taskArgs.key,
            taskArgs.value
        )).wait();
    }

    console.log(`send echo ${taskArgs.key} :${taskArgs.value} success`);

}