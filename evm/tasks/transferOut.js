
function stringToHex(str) {
    return str.split("").map(function(c) {
        return ("0" + c.charCodeAt(0).toString(16)).slice(-2);
    }).join("");
}

module.exports = async (taskArgs) => {
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:",deployer.address);


    let mos = await ethers.getContractAt('IMOSV3',taskArgs.mos);

    await (await mos.connect(deployer).transferOut(
        taskArgs.chain,
        [
            taskArgs.target,
            taskArgs.calldata,
            taskArgs.gaslimit,
            taskArgs.value
        ]
    )).wait();



    console.log(`transfer out  ${taskArgs.target} to chain ${taskArgs.chain}  successful`);
}