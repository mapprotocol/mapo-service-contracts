pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMapoService {
    struct CallData {
        bytes target;
        bytes callData;
        uint256 gasLimit;
        uint256 value;
    }

    function transferOut(uint256 _toChain,CallData memory _callData) external payable  returns(bool);

}

contract HelloWorld is Ownable {

    address MapoService;

    mapping(string => string) public HelloWorldList;

    mapping(uint256 => address) public TargetList;

    mapping(address => bool) public WhiteList;

    function setList(string memory _key,string memory _val) external returns(bool) {
        require(WhiteList[msg.sender]," have no right ");
        HelloWorldList[_key] = _val;
        return true;
    }

    function getData(string memory _key,string memory _val) public view returns(bytes memory data){

        data = abi.encodeWithSelector(HelloWorld.setList.selector,_key,_val);
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

    function greeting(uint256 _tochainId,bytes memory _target,string memory _key,string memory _val) external {

        bytes memory data = getData(_key,_val);

        IMapoService.CallData memory cData = IMapoService.CallData(_target,data,50000,0);

        require(
            IMapoService(MapoService).transferOut(
                _tochainId,
                cData
            ),
            "Greeting fail"
        );
    }
}
