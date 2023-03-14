const {ethers} = require("hardhat");
const {expect} = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("MAPO ServiceV3 start test", () =>{

    let owner;
    let addr1;

    let mos;

    let lightNode;

    let wrapped;

    let echo;

    let feeService;

    async function deployContractFixture() {

        [owner, addr1] = await ethers.getSigners();

        let mosContract = await ethers.getContractFactory("MapoServiceV3");
        mos = await mosContract.deploy();
        console.log("mosMessage address:",mos.address);

        let wrappedContract = await ethers.getContractFactory("Wrapped");
        wrapped = await wrappedContract.deploy();
        console.log("Wrapped:",wrapped.address);

        let lightNodeContract = await ethers.getContractFactory("LightNode");
        lightNode = await  lightNodeContract.deploy();
        console.log("lightNodeContract:",lightNode.address);

        let EchoContract = await ethers.getContractFactory("Echo");
        echo = await  EchoContract.deploy();
        console.log("echo address:",echo.address)

        let data  = await mos.initialize(wrapped.address, lightNode.address);

        let proxyContract = await ethers.getContractFactory("MapoServiceProxyV3");
        let proxy = await proxyContract.deploy(mos.address, data.data);
        await proxy.deployed()
        mos = mosContract.attach(proxy.address);

        let feeContract = await ethers.getContractFactory("FeeService");
        feeService = await  feeContract.deploy();
        console.log("FeeService address:",feeService.address)

        return {mos,echo,feeService,owner,addr1};
    }

    describe("",async () =>{

       let{mos,echo,feeService,owner,addr1} = await loadFixture(deployContractFixture)

        it('mosMessage set ', async function () {
            await mos.setRelayContract(5,"0x5FC8d32690cc91D4c39d9d3abcBD16989F875707");

            await mos.addWhiteList(echo.address,true);

            await mos.setFeeService(feeService.address);

            await echo.setWhiteList(mos.address);

            await feeService.setBaseGasLimit(97,1000000);
            await feeService.setChainGasPrice(97,10000);

        });
        it('transferOut start test ', async function () {

            let data = await echo.getData("hello","hello world");

            await mos.transferOut("97",[echo.address,data,"5000000","0"],{value:100});

            await expect(mos.transferOut("212",[echo.address,data,"5000000","0"],{value:100})).to.be.revertedWith("token not registered");

            await expect(mos.connect(addr1).transferOut("97",[echo.address,data,"5000000","0"],{value:60000000000})).to.be.revertedWith("Non-whitelisted address");

            await expect(mos.transferOut("97",[mos.address,data,"5000000","0"],{value:50})).to.be.revertedWith("Need message fee");

            await expect(mos.transferOut("97",[echo.address,data,"5000000","10"],{value:100})).to.be.revertedWith("Not supported at present value");


        });

        it('transferIn start test ', async function () {

            expect(await echo.EchoList("hello")).to.equal("");

            let receiptProof = "0xf90320f9031d945fc8d32690cc91d4c39d9d3abcbd16989f875707f863a0f4397fd41454e34a9a4015d05a670124ecd71fe7f1d05578a62f8009b1a57f8aa00000000000000000000000000000000000000000000000000000000000000005a000000000000000000000000000000000000000000000000000000000000000d4b902a0fa0695e96a5e7edd4f61def03d19534773886eca12cc281c2170c0078210b9f0000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000014f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000000000000000000000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000004c4b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014cf7ed3acca5a467e9e704c703e8d87f634fb0fc900000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4dd1d382400000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000568656c6c6f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c6400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

            await mos.transferIn(5,receiptProof);

            expect(await echo.EchoList("hello")).to.equal("hello world");
        });
    })


})




