module.exports = async function ({ethers, deployments}) {
    const {deploy} = deployments
    const accounts = await ethers.getSigners()
    const deployer = accounts[0];

    console.log("deployer address:", deployer.address);

    await deploy('MessageFee', {
        from: deployer.address,
        args: [],
        log: true,
        contract: 'MessageFee',
    })
    let messageFee = await ethers.getContract('MessageFee');
    console.log("MessageFee address:", messageFee.address);


    console.log("messageFee deploy success")
}

module.exports.tags = ['MessageFee']