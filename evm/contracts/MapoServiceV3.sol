// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interface/IFeeService.sol";
import "./interface/IMOSV3.sol";
import "./interface/ILightNode.sol";
import "./interface/IMapoExcute.sol";
import "./utils/TransferHelper.sol";
import "./utils/Utils.sol";
import "./utils/EvmDecoder.sol";


contract MapoServiceV3 is ReentrancyGuard, Initializable, Pausable, IMOSV3, UUPSUpgradeable {
    using SafeMath for uint;
    using Address for address;

    uint public immutable selfChainId = block.chainid;
    uint256 public constant gasLimitMin = 21000;
    uint256 public constant gasLimitMax = 10000000;
    uint public nonce;
    uint256 public relayChainId;
    address public wToken;          // native wrapped token
    address public relayContract;
    ILightNode public lightNode;
    IFeeService public feeService;

    struct StoredCalldata {
        bytes callData;
        bytes targetAddress;
        bytes32 orderId;
    }


    mapping(bytes32 => bool) public orderList;
    mapping(uint256 => mapping(address => bool)) public tokenMappingList;
    mapping(uint256 => chainType) public chainTypes;
    mapping(address => bool) public messageWhiteList;
    mapping(address => mapping(bytes => bool)) public relationList;
    mapping(uint256 => mapping(bytes => StoredCalldata) ) public storedCalldataList;

    event mapTransferExecute(uint256 indexed fromChain, uint256 indexed toChain, address indexed from);
    event SetLightClient(address _lightNode);
    event SetFeeService(address feeServiceAddress);
    event SetRelayContract(uint256 _chainId, address _relay);
    event AddWhiteList(address _messageAddress, bool _enable);

    function initialize(address _wToken, address _lightNode)
    public initializer virtual checkAddress(_wToken) checkAddress(_lightNode) {
        wToken = _wToken;
        lightNode = ILightNode(_lightNode);
        _changeAdmin(msg.sender);
    }


    receive() external payable {}


    modifier checkOrder(bytes32 _orderId) {
        require(!orderList[_orderId], "order exist");
        orderList[_orderId] = true;
        _;
    }

    modifier checkBridgeable(address _token, uint _chainId) {
        require(tokenMappingList[_chainId][_token], " not registered");
        _;
    }

    modifier checkAddress(address _address){
        require(_address != address(0), "address is zero");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _getAdmin(), "mos :: only admin");
        _;
    }

    function setPause() external onlyOwner {
        _pause();
    }

    function setUnpause() external onlyOwner {
        _unpause();
    }

    function setLightClient(address _lightNode) external onlyOwner checkAddress(_lightNode) {
        lightNode = ILightNode(_lightNode);
        emit SetLightClient(_lightNode);
    }

    function setFeeService(address _feeServiceAddress) external onlyOwner checkAddress(_feeServiceAddress) {
        feeService = IFeeService(_feeServiceAddress);
        emit SetFeeService(_feeServiceAddress);
    }


    function setRelayContract(uint256 _chainId, address _relay) external onlyOwner checkAddress(_relay) {
        relayContract = _relay;
        relayChainId = _chainId;
        emit SetRelayContract(_chainId,_relay);
    }

    function addWhiteList(address _messageAddress,bool _enable) external onlyOwner {

        messageWhiteList[_messageAddress] = _enable;
        emit AddWhiteList(_messageAddress,_enable);
    }

    function addCorrespondence(bytes memory _targetAddress,bool _tag) external override {
        relationList[msg.sender][_targetAddress] = _tag;
    }

    function getCrossChainFee(uint256 _toChain,address _feeToken,uint256 _gasLimit) public view returns(uint256 amount,address receiverAddress) {
        (uint256 baseLimit,uint256 chainPrice,address receiverFeeAddress) = feeService.getMessageFee(_toChain,_feeToken);

        amount = (baseLimit.add(_gasLimit)).mul(chainPrice);
        receiverAddress = receiverFeeAddress;
    }

    function emergencyWithdraw(address _token, address payable _receiver, uint256 _amount) external onlyOwner checkAddress(_receiver) {
        if (_token == wToken) {
            TransferHelper.safeWithdraw(wToken, _amount);
            TransferHelper.safeTransferETH(_receiver, _amount);
        } else if(_token == address(0)){
            TransferHelper.safeTransferETH(_receiver, _amount);
        }else {
            TransferHelper.safeTransfer(_token,_receiver,_amount);
        }
    }

    function transferOut(uint256 _toChain,MessageData memory _messageData,address _feeToken) external  override
    payable
    nonReentrant
    whenNotPaused
    returns(bool)
    {
        require(_toChain != selfChainId, "Only other chain");
        require(_messageData.gasLimit >= gasLimitMin ,"Execution gas too low");
        require(_messageData.gasLimit <= gasLimitMax ,"Execution gas too high");
        require(_messageData.value == 0,"Not supported at present value");

        (uint256 amount,address receiverFeeAddress)= getCrossChainFee(_toChain,_feeToken,_messageData.gasLimit);
        if(_feeToken == address(0)){
            require(msg.value >= amount , "Need message fee");

            if (msg.value > 0) {
                TransferHelper.safeTransferETH(receiverFeeAddress, msg.value);
            }
        }else {
            TransferHelper.safeTransferFrom(_feeToken,tx.origin,receiverFeeAddress,amount);
        }


        bytes32 orderId = _getOrderID(msg.sender, _messageData.target, _toChain);

        bytes memory fromAddress = Utils.toBytes(msg.sender);

        bytes memory messageData = abi.encode(_messageData);

        emit mapMessageOut(selfChainId, _toChain, orderId, fromAddress,messageData);
        return true;
    }


    function transferIn(uint256 _chainId, bytes memory _receiptProof) external virtual nonReentrant whenNotPaused {
        require(_chainId == relayChainId, "invalid chain id");
        (bool sucess, string memory message, bytes memory logArray) = lightNode.verifyProofData(_receiptProof);
        require(sucess, message);
        IEvent.txLog[] memory logs = EvmDecoder.decodeTxLogs(logArray);

        for (uint i = 0; i < logs.length; i++) {
            IEvent.txLog memory log = logs[i];
            bytes32 topic = abi.decode(log.topics[0], (bytes32));

            if (topic == EvmDecoder.MAP_MESSAGE_TOPIC && relayContract == log.addr) {
                (, IEvent.dataOutEvent memory outEvent) = EvmDecoder.decodeDataLog(log);

                if(outEvent.toChain == selfChainId){
                    _messageIn(outEvent);
                }
            }
        }
        emit mapTransferExecute(_chainId, selfChainId, msg.sender);
    }

    function _messageIn(IEvent.dataOutEvent memory _outEvent) internal checkOrder(_outEvent.orderId)  {

        MessageData memory mData = abi.decode(_outEvent.messageData,(MessageData));

        address callDataAddress = Utils.fromBytes(mData.target);
        if(mData.mosType == msgType.CALLDATA && relationList[callDataAddress][_outEvent.fromAddress]){
            (bool success,bytes memory reason) = callDataAddress.call{gas:mData.gasLimit}(mData.callData);
            if(!success){

                emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,mData.callData, success);

            }else{
                storedCalldataList[_outEvent.fromChain][_outEvent.fromAddress] = StoredCalldata(mData.callData, mData.target, _outEvent.orderId);
                emit mapMessageInError(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,mData.callData, reason);
            }
        }else if(mData.mosType == msgType.MESSAGE){

            try IMapoExcute(callDataAddress).mapoExcute{gas:mData.gasLimit}(_outEvent.fromChain,_outEvent.fromAddress,_outEvent.orderId,mData.callData) {

                emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,mData.callData, true);

            } catch (bytes memory reason) {

                storedCalldataList[_outEvent.fromChain][_outEvent.fromAddress] = StoredCalldata(mData.callData, mData.target, _outEvent.orderId);
                emit mapMessageInError(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,mData.callData, reason);
            }
        }


    }

    function _getOrderID(address _from, bytes memory _to, uint _toChain) internal returns (bytes32){
        return keccak256(abi.encodePacked(address(this), nonce++, selfChainId, _toChain, _from, _to));
    }

    /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override {
        require(msg.sender == _getAdmin(), "MapoService: only Admin can upgrade");
    }

    function changeAdmin(address _admin) external onlyOwner checkAddress(_admin){
        _changeAdmin(_admin);
    }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}