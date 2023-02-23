
module.exports = async (taskArgs,hre) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);

    let helloWorld = await ethers.getContractAt('HelloWorld', taskArgs.greetingAddress);

    let value = await helloWorld.connect(deployer).HelloWorldList(taskArgs.key);

    console.log(`${taskArgs.key} : ${value}`);

}