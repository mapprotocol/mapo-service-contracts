module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    await deploy('FeeService', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'FeeService',
        deterministicDeployment: true
    })
    let feeService = await ethers.getContract('FeeService');
    console.log("FeeService address:", feeService.address);


    console.log("messageFee deploy success")
}

module.exports.tags = ['FeeService']