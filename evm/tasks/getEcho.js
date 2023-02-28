
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let echo = await ethers.getContractAt('Echo', taskArgs.echoAddress);

    let value = await echo.connect(deployer).EchoList(taskArgs.key);

    console.log(`${taskArgs.key} : ${value}`);

}