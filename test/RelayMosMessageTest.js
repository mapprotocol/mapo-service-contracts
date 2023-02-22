const {ethers} = require("hardhat");
const {expect} = require("chai");

function getLogs(logData){
    let logs = []
    for (let i = 0; i < logData.length; i++){
        let log = [];
        log[0] =  logData[i].address
        log[1] = logData[i].topics
        log[2] = logData[i].data
        logs.push(log)
    }

    return logs;
}



describe("MAPOmnichainServiceRelayV3 start test", () =>{
    let owner;
    let addr1;

    let MosMessageRelay;
    let mosMessageRelay;

    let LightNode;
    let lightNode;

    let Wrapped;
    let wrapped;

    let PingPong;
    let pingPong;

    let MessageFee;
    let messageFee;

    beforeEach(async () =>{
        [owner, addr1] = await ethers.getSigners();
    })

    it('constract deploy init', async function () {

        MosMessageRelay = await ethers.getContractFactory("MAPOmnichainServiceRelayV3");
        mosMessageRelay = await MosMessageRelay.deploy();
        console.log("mosMessageRelay address:",mosMessageRelay.address);

        Wrapped = await ethers.getContractFactory("Wrapped");
        wrapped = await Wrapped.deploy();
        console.log("Wrapped:",wrapped.address);

        LightNode = await ethers.getContractFactory("LightClientManager");
        lightNode = await  LightNode.deploy();

        PingPong = await ethers.getContractFactory("PingPong");
        pingPong = await  PingPong.deploy();

        let data  = await mosMessageRelay.initialize(wrapped.address,lightNode.address);

        const MapCrossChainServiceProxy = await ethers.getContractFactory("MAPOmnichainServiceProxyV3");
        let mossp = await MapCrossChainServiceProxy.deploy(mosMessageRelay.address,data.data);
        await mossp.deployed()
        mosMessageRelay = MosMessageRelay.attach(mossp.address);

        MessageFee = await ethers.getContractFactory("MessageFee");
        messageFee = await  MessageFee.deploy();

    });

    it('mosMessage set ', async function () {
        await mosMessageRelay.registerChain(5,"0x5FC8d32690cc91D4c39d9d3abcBD16989F875707","1");

        await mosMessageRelay.addWhiteList(pingPong.address,true);

        await mosMessageRelay.addWhiteList(owner.address,true);


        await mosMessageRelay.setMessageFee(messageFee.address);

        await pingPong.setWhiteList(mosMessageRelay.address);

        await messageFee.setMessageFee(97,pingPong.address,100);

    });

    it('transferOut start test ', async function () {

        let data = await pingPong.getData("hello","hello world");

        console.log(pingPong.address)

        await mosMessageRelay.transferOut("97",[pingPong.address,data,"5000000","0"]);

        await expect(mosMessageRelay.transferOut("212",[pingPong.address,data,"5000000","0"])).to.be.revertedWith("Only other chain");


    });

    it('transferIn start test ', async function () {

        expect(await pingPong.PingPongList("hello")).to.equal("");

        let receiptProof = "0xf902c0f902bd945fc8d32690cc91d4c39d9d3abcbd16989f875707f863a056877b1dbedc6754c111b951146b820fe6b723af0213fc415d44b05e1758dd85a00000000000000000000000000000000000000000000000000000000000000005a000000000000000000000000000000000000000000000000000000000000000d4b90240990d2a2ca04d3c48afd73f275a61e9fe79b16c87451862b65592d3a3860e52a6000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000004c4b40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000144a679253410272dd5232b3ff7cf5dbb88f29531900000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4dd1d382400000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

        await mosMessageRelay.transferIn(5,receiptProof);

        expect(await pingPong.PingPongList("hello")).to.equal("hello world");

        //hello -> hello world bsc chain
        let receiptProof97 = "0xf902c0f902bd945fc8d32690cc91d4c39d9d3abcbd16989f875707f863a056877b1dbedc6754c111b951146b820fe6b723af0213fc415d44b05e1758dd85a000000000000000000000000000000000000000000000000000000000000000d4a00000000000000000000000000000000000000000000000000000000000000061b902406e624d148934cdef6962ac3cc94c52505c45ca0e526973de388e1fdbc159c145000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000004c4b40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000144a679253410272dd5232b3ff7cf5dbb88f29531900000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4dd1d382400000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001568656c6c6f20776f726c642062736320636861696e000000000000000000000000000000000000000000000000000000000000000000000000000000"

        await mosMessageRelay.transferIn(5,receiptProof97);

        expect(await pingPong.PingPongList("hello")).to.equal("hello world");

    });

})




