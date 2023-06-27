pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IMapoExecutor.sol";


interface IMapoService {
    enum MessageType {
        CALLDATA,
        MESSAGE
    }


    struct MessageData {
        bool relay;
        MessageType msgType;
        bytes target;
        bytes payload;
        uint256 gasLimit;
        uint256 value;
    }

    function getMessageFee(uint256 _toChain, address _feeToken, uint256 _gasLimit) external view returns(uint256, address);

    function transferOut(uint256 _toChain, bytes memory _messageData,address _feeToken) external payable  returns(bytes32);


    function addRemoteCaller(uint256 _fromChain, bytes memory _fromAddress,bool _tag) external;
}

contract Echo is Ownable, IMapoExecutor {

    address MapoService;

    mapping(string => string) public EchoList;

    mapping(uint256 => address) public TargetList;

    mapping(address => bool) public WhiteList;

    function setList(string memory _key,string memory _val) external returns(bool) {
        require(WhiteList[msg.sender]," have no right ");
        EchoList[_key] = _val;
        return true;
    }


    function setRelayList(string memory _key,string memory _val) external returns(bytes memory newData) {
        require(WhiteList[msg.sender]," have no right ");
        EchoList[_key] = _val;
        string memory key = "hello";
        string memory val = "hellCallData";
        newData = abi.encode(key,val);
        return newData;
    }

    function getData(string memory _key,string memory _val) public view returns(bytes memory data){

        data = abi.encodeWithSelector(Echo.setList.selector,_key,_val);
    }

    function getRelayData(string memory _key,string memory _val) public view returns(bytes memory data){

        data = abi.encodeWithSelector(Echo.setRelayList.selector,_key,_val);
    }

    function getMessageData(string memory _key,string memory _val) public view returns(bytes memory data){

        data = abi.encode(_key,_val);
    }

    function getMessageBytes(IMapoService.MessageData memory mData) public view returns(bytes memory data){

        data = abi.encode(mData);
    }

    function setWhiteList(address _executeAddress) external onlyOwner {
        WhiteList[_executeAddress] = true;
    }

    function setMapoService(address _IMapoService) external onlyOwner{
        MapoService = _IMapoService;
    }

    function setTarget(address _target,uint256 _chainId) external onlyOwner{
        TargetList[_chainId] = _target;
    }

    function echo(uint256 _tochainId,bytes memory _target,string memory _key,string memory _val) external payable{

        bytes memory data = getData(_key,_val);

        //IMapoService.MessageData memory mData = IMapoService.MessageData(false,IMapoService.MessageType.CALLDATA,_target,data,500000,0);

        bytes memory mData = abi.encode(false,IMapoService.MessageType.CALLDATA,_target,data,500000,0);

        IMapoService(MapoService).transferOut{value:msg.value}(_tochainId, mData, address(0));

    }

    function addCorrespondence(uint256 _fromChain,bytes memory _targetAddress,bool _tag) external  onlyOwner{

        IMapoService(MapoService).addRemoteCaller(_fromChain,_targetAddress,_tag);
    }


    function mapoExecute(uint256 _fromChain, uint256 _toChain, bytes calldata _fromAddress, bytes32 _orderId, bytes calldata _message) external  override returns(bytes memory newData) {

        (string memory key,string memory value)  = abi.decode(_message,(string,string));

        EchoList[key] = value;

        string memory val = "hello-Target-address";
        newData = abi.encode(val,key);
        return newData;
    }


}
