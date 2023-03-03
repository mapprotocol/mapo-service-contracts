// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/ILightClientManager.sol";
import "./interface/IMOSV3.sol";
import "./interface/IFeeService.sol";
import "./utils/TransferHelper.sol";
import "./utils/EvmDecoder.sol";
import "./utils/NearDecoder.sol";
import "./utils/Utils.sol";


contract MapoServiceRelayV3 is ReentrancyGuard, Initializable, Pausable, IMOSV3, UUPSUpgradeable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public constant gasLimitMin = 21000;
    uint256 public constant gasLimitMax = 10000000;
    uint256 public immutable selfChainId = block.chainid;
    uint256 public nonce;
    address public wToken;        // native wrapped token
    ILightClientManager public lightClientManager;
    IFeeService public feeService;

    mapping(bytes32 => bool) public orderList;
    mapping(uint256 => bytes) public mosContracts;
    mapping(uint256 => chainType) public chainTypes;
    mapping(address => bool) public messageWhiteList;

    event mapTransferExecute(uint256 indexed fromChain, uint256 indexed toChain, address indexed from);

    event SetLightClientManager(address lightClient);
    event SetFeeService(address feeServiceAddress);
    event RegisterChain(uint256 _chainId, bytes _address, chainType _type);

    event AddWhiteList(address _messageAddress, bool _enable);

    function initialize(address _wToken, address _managerAddress) public initializer
    checkAddress(_wToken) checkAddress(_managerAddress) {
        wToken = _wToken;
        lightClientManager = ILightClientManager(_managerAddress);
        _changeAdmin(msg.sender);
    }


    receive() external payable {
        require(msg.sender == wToken, "only wToken");
    }


    modifier checkOrder(bytes32 orderId) {
        require(!orderList[orderId], "order exist");
        orderList[orderId] = true;
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _getAdmin(), "mosRelay :: only admin");
        _;
    }

    modifier checkAddress(address _address){
        require(_address != address(0), "address is zero");
        _;
    }


    function setPause() external onlyOwner {
        _pause();
    }

    function setUnpause() external onlyOwner {
        _unpause();
    }

    function setFeeService(address _feeServiceAddress) external onlyOwner checkAddress(_feeServiceAddress) {
        feeService = IFeeService(_feeServiceAddress);
        emit SetFeeService(_feeServiceAddress);
    }


    function setLightClientManager(address _managerAddress) external onlyOwner checkAddress(_managerAddress) {
        lightClientManager = ILightClientManager(_managerAddress);
        emit SetLightClientManager(_managerAddress);
    }

    function registerChain(uint256 _chainId, bytes memory _address, chainType _type) external onlyOwner {
        mosContracts[_chainId] = _address;
        chainTypes[_chainId] = _type;
        emit RegisterChain(_chainId, _address, _type);
    }

    function addWhiteList(address _messageAddress,bool _enable) external onlyOwner {

        messageWhiteList[_messageAddress] = _enable;
        emit AddWhiteList(_messageAddress,_enable);
    }


    function emergencyWithdraw(address _token, address payable _receiver, uint256 _amount) external onlyOwner checkAddress(_receiver) {
        _withdraw(_token, _receiver, _amount);
    }


    function transferOut(uint256 _toChain,CallData memory _callData) external  override
    payable
    nonReentrant
    whenNotPaused
    returns(bool)
    {
        require(_toChain != selfChainId, "Only other chain");
        require(_callData.gasLimit >= gasLimitMin ,"Execution gas too low");
        require(_callData.gasLimit <= gasLimitMax ,"Execution gas too high");
        require(messageWhiteList[msg.sender],"Non-whitelisted address");

        require(_callData.value == 0,"Not supported at present value");

        (uint256 fee,address receiverFeeAddress) = feeService.getMessageFee(_toChain,_callData.target);
        //require(fee > 0,"Address has no message fee");
        uint256 amount = msg.value;
        require(amount == fee, "Need message fee");
        if(amount > 0 ){
            TransferHelper.safeTransferETH(receiverFeeAddress, amount);
        }

        bytes32 orderId = _getOrderId(msg.sender, _callData.target, _toChain);

        bytes memory fromAddress = Utils.toBytes(msg.sender);

        bytes memory callData = abi.encode(_callData);

        emit mapMessageOut(selfChainId, _toChain, orderId,fromAddress,callData);
        return true;
    }


    function transferIn(uint256 _chainId, bytes memory _receiptProof) external nonReentrant whenNotPaused {
        (bool success,string memory message,bytes memory logArray) = lightClientManager.verifyProofData(_chainId, _receiptProof);
        require(success, message);
        if (chainTypes[_chainId] == chainType.NEAR) {
            (bytes memory mosContract, IEvent.transferOutEvent[] memory outEvents) = NearDecoder.decodeNearLog(logArray);
            for (uint i = 0; i < outEvents.length; i++) {
                IEvent.transferOutEvent memory outEvent = outEvents[i];
                if (outEvent.toChain == 0) {continue;}
                require(Utils.checkBytes(mosContract, mosContracts[_chainId]), "invalid mos contract");
                // TODO
            }
        } else if (chainTypes[_chainId] == chainType.EVM) {
            IEvent.txLog[] memory logs = EvmDecoder.decodeTxLogs(logArray);
            for (uint256 i = 0; i < logs.length; i++) {
                IEvent.txLog memory log = logs[i];
                bytes32 topic = abi.decode(log.topics[0], (bytes32));

                if (topic == EvmDecoder.MAP_MESSAGE_TOPIC) {
                    bytes memory mosContract = Utils.toBytes(log.addr);
                    if (Utils.checkBytes(mosContract, mosContracts[_chainId])) {
                        (, IEvent.dataOutEvent memory outEvent) = EvmDecoder.decodeDataLog(log);
                        _messageIn(_chainId, outEvent);
                    }
                }
            }
        } else {
            require(false, "chain type error");
        }

        emit mapTransferExecute(_chainId, selfChainId, msg.sender);
    }

    function _messageIn(uint256 _chainId, IEvent.dataOutEvent memory _outEvent) internal checkOrder(_outEvent.orderId)  {

        require(_chainId == _outEvent.fromChain, "MOS: invalid chain id");

        if(_outEvent.toChain == selfChainId){

            CallData memory cData = abi.decode(_outEvent.cData,(CallData));

            address callDataAddress = Utils.fromBytes(cData.target);

            bool success;

            if(messageWhiteList[callDataAddress]){
                (success, ) = callDataAddress.call{gas:cData.gasLimit}(cData.callData);
            }
            bytes memory fromAddress = Utils.toBytes(msg.sender);

            emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,fromAddress,cData.callData,success);

        }else{

            emit mapMessageOut(selfChainId,_outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,_outEvent.cData);
        }
    }



    function _getOrderId(address _from, bytes memory _to, uint256 _toChain) internal returns (bytes32){
        return keccak256(abi.encodePacked(address(this), nonce++, selfChainId, _toChain, _from, _to));
    }

    function _withdraw(address _token, address payable _receiver, uint256 _amount) internal {
        if (_token == wToken) {
            TransferHelper.safeWithdraw(wToken, _amount);
            TransferHelper.safeTransferETH(_receiver, _amount);
        } else {
            TransferHelper.safeTransfer(_token, _receiver, _amount);
        }
    }


    /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == _getAdmin(), "MapoServiceRelay: only Admin can upgrade");
    }

    function changeAdmin(address _admin) external onlyOwner checkAddress(_admin) {
        _changeAdmin(_admin);
    }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}
