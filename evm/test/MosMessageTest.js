const {ethers} = require("hardhat");
const {expect} = require("chai");

describe("MAPOmnichainServiceV3 start test", () =>{
    let owner;
    let addr1;

    let MosMessage;
    let mosMessage;

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

        MosMessage = await ethers.getContractFactory("MAPOmnichainServiceV3");
        mosMessage = await MosMessage.deploy();
        console.log("mosMessage address:",mosMessage.address);

        Wrapped = await ethers.getContractFactory("Wrapped");
        wrapped = await Wrapped.deploy();
        console.log("Wrapped:",wrapped.address);

        LightNode = await ethers.getContractFactory("LightNode");
        lightNode = await  LightNode.deploy();

        PingPong = await ethers.getContractFactory("PingPong");
        pingPong = await  PingPong.deploy();

        let data  = await mosMessage.initialize(wrapped.address,lightNode.address);

        const MapCrossChainServiceProxy = await ethers.getContractFactory("MAPOmnichainServiceProxyV3");
        let mossp = await MapCrossChainServiceProxy.deploy(mosMessage.address,data.data);
        await mossp.deployed()
        mosMessage = MosMessage.attach(mossp.address);

        MessageFee = await ethers.getContractFactory("MessageFee");
        messageFee = await  MessageFee.deploy();

    });

    it('mosMessage set ', async function () {
         await mosMessage.setRelayContract(5,"0x5FC8d32690cc91D4c39d9d3abcBD16989F875707");

         await mosMessage.addWhiteList(pingPong.address,true);

         await mosMessage.addWhiteList(owner.address,true);

         await mosMessage.registerChain(pingPong.address,97,"true");

         await mosMessage.setMessageFee(messageFee.address);

        await pingPong.setWhiteList(mosMessage.address);

        await messageFee.setMessageFee(97,pingPong.address,100);

    });

    it('transferOut start test ', async function () {

        let data = await pingPong.getData("hello","hello world");

        await mosMessage.transferOut("97",[pingPong.address,data,"5000000","0"]);

        await expect(mosMessage.transferOut("212",[pingPong.address,data,"5000000","0"])).to.be.revertedWith("token not registered");

        await mosMessage.registerChain(pingPong.address,212,"true");

        await expect(mosMessage.transferOut("212",[pingPong.address,data,"5000000","0"])).to.be.revertedWith("Only other chain");

        await expect(mosMessage.connect(addr1).transferOut("97",[pingPong.address,data,"5000000","0"])).to.be.revertedWith("Non-whitelisted address");

        await mosMessage.registerChain(mosMessage.address,97,"true");
        await expect(mosMessage.transferOut("97",[mosMessage.address,data,"5000000","0"])).to.be.revertedWith("Address has no message fee");

        await expect(mosMessage.transferOut("97",[pingPong.address,data,"5000000","10"])).to.be.revertedWith("Not supported at present value");


    });

    it('transferIn start test ', async function () {

        expect(await pingPong.PingPongList("hello")).to.equal("");

        let receiptProof = "0xf902c0f902bd945fc8d32690cc91d4c39d9d3abcbd16989f875707f863a056877b1dbedc6754c111b951146b820fe6b723af0213fc415d44b05e1758dd85a00000000000000000000000000000000000000000000000000000000000000005a000000000000000000000000000000000000000000000000000000000000000d4b90240fa0695e96a5e7edd4f61def03d19534773886eca12cc281c2170c0078210b9f0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000004c4b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014cf7ed3acca5a467e9e704c703e8d87f634fb0fc900000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4dd1d382400000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

        await mosMessage.transferIn(5,receiptProof);

        expect(await pingPong.PingPongList("hello")).to.equal("hello world");
    });


})




