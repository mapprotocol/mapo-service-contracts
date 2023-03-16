pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/IMapoExecutor.sol";

interface IMapoService {
    enum msgType {
        CALLDATA,
        MESSAGE
    }


    struct MessageData {
        msgType mosType;
        bytes target;
        bytes callData;
        uint256 gasLimit;
        uint256 value;
    }


    function transferOut(uint256 _toChain,MessageData memory _messageData,address _feeToken) external payable  returns(bool);

    function addCorrespondence(bytes memory _targetAddress,bool _tag) external;
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

    function getData(string memory _key,string memory _val) public view returns(bytes memory data){

        data = abi.encodeWithSelector(Echo.setList.selector,_key,_val);
    }

    function getMessageData(string memory _key,string memory _val) public view returns(bytes memory data){

        data = abi.encode(_key,_val);
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

    function echo(uint256 _tochainId,bytes memory _target,string memory _key,string memory _val) external {

        bytes memory data = getData(_key,_val);

        IMapoService.MessageData memory mData = IMapoService.MessageData(IMapoService.msgType.CALLDATA,_target,data,500000,0);

        require(
            IMapoService(MapoService).transferOut(
                _tochainId,
                mData,
                address(0)
            ),
            "Greeting fail"
        );
    }

    function addCorrespondence(bytes memory _targetAddress,bool _tag) external  onlyOwner{

        IMapoService(MapoService).addCorrespondence(_targetAddress,_tag);
    }


    function mapoExecute(uint256 _srcChainId, bytes calldata _fromAddress, bytes32 _orderId, bytes calldata _message) external override {

        (string memory key,string memory value)  = abi.decode(_message,(string,string));

        EchoList[key] = value;

    }


}
