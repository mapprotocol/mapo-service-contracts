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
import "./interface/IMapoExecutor.sol";
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

    mapping(bytes32 => bool) public orderList;
    mapping(uint256 => ChainType) public chainTypes;
    mapping(address => mapping(uint256 => mapping(bytes => bool))) public callerList;


    event mapTransferExecute(uint256 indexed fromChain, uint256 indexed toChain, address indexed from);
    event SetLightClient(address _lightNode);
    event SetFeeService(address feeServiceAddress);
    event SetRelayContract(uint256 _chainId, address _relay);

    function initialize(address _wToken, address _lightNode)
    public
    virtual
    initializer
    checkAddress(_wToken)
    checkAddress(_lightNode)
    {
        wToken = _wToken;
        lightNode = ILightNode(_lightNode);
        _changeAdmin(tx.origin);
    }

    receive() external payable {}

    modifier checkOrder(bytes32 _orderId) {
        require(!orderList[_orderId], "order exist");
        orderList[_orderId] = true;
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

    function addRemoteCaller(uint256 _fromChain, bytes memory _fromAddress, bool _tag) external override {
        callerList[msg.sender][_fromChain][_fromAddress] = _tag;
    }

    function getMessageFee(uint256 _toChain, address _feeToken, uint256 _gasLimit) external override view returns(uint256 amount, address receiverAddress) {
        (amount, receiverAddress) = _getMessageFee(_toChain, _feeToken, _gasLimit);
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

    function transferOut(uint256 _toChain, bytes memory _messageData, address _feeToken) external  override
    payable
    nonReentrant
    whenNotPaused
    returns(bool)
    {
        require(_toChain != selfChainId, "Only other chain");

        MessageData memory msgData = abi.decode(_messageData,(MessageData));

        require(msgData.gasLimit >= gasLimitMin ,"Execution gas too low");
        require(msgData.gasLimit <= gasLimitMax ,"Execution gas too high");
        require(msgData.value == 0,"Not supported msg value");

        // TODO: check payload length
        // TODO: check target address

        (uint256 amount,address receiverFeeAddress)= _getMessageFee(_toChain, _feeToken, msgData.gasLimit);
        if(_feeToken == address(0)){
            require(msg.value >= amount , "Need message fee");

            if (msg.value > 0) {
                TransferHelper.safeTransferETH(receiverFeeAddress, msg.value);
            }
        }else {
            TransferHelper.safeTransferFrom(_feeToken, msg.sender, receiverFeeAddress, amount);
        }

        bytes32 orderId = _getOrderID(msg.sender, msgData.target, _toChain);

        bytes memory fromAddress = Utils.toBytes(msg.sender);

        //bytes memory messageData = abi.encode(_messageData);

        emit mapMessageOut(selfChainId, _toChain, orderId, fromAddress, _messageData);

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

        MessageData memory msgData = abi.decode(_outEvent.messageData,(MessageData));

        address target = Utils.fromBytes(msgData.target);
        if(msgData.msgType == MessageType.CALLDATA && callerList[target][_outEvent.fromChain][_outEvent.fromAddress]){
            (bool success,bytes memory reason) = target.call{gas: msgData.gasLimit}(msgData.payload);
            if(success){

                emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, true, bytes(""));

            }else{
                //storedCalldataList[_outEvent.fromChain][_outEvent.fromAddress] = StoredCalldata(msgData.payload, msgData.target, _outEvent.orderId);
                emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, false, reason);
            }
        }else if(msgData.msgType == MessageType.MESSAGE){

            try IMapoExecutor(target).mapoExecute{gas: msgData.gasLimit}(_outEvent.fromChain, _outEvent.toChain, _outEvent.fromAddress,_outEvent.orderId, msgData.payload) {

                emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, true, bytes(""));

            } catch (bytes memory reason) {

                //storedCalldataList[_outEvent.fromChain][_outEvent.fromAddress] = StoredCalldata(msgData.payload, msgData.target, _outEvent.orderId);
                emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, false, reason);
            }
        }


    }

    function _getOrderID(address _from, bytes memory _to, uint _toChain) internal returns (bytes32){
        return keccak256(abi.encodePacked(address(this), nonce++, selfChainId, _toChain, _from, _to));
    }

    function _getMessageFee(uint256 _toChain, address _feeToken, uint256 _gasLimit) internal view returns(uint256 amount, address receiverAddress) {
        (uint256 baseGas,uint256 chainPrice,address receiverFeeAddress) = feeService.getMessageFee(_toChain,_feeToken);

        amount = (baseGas.add(_gasLimit)).mul(chainPrice);
        receiverAddress = receiverFeeAddress;
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