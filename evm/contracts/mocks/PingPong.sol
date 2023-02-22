pragma solidity ^0.8.7;

contract PingPong {
    mapping(string => string) public PingPongList;

    mapping(address => bool) public whiteList;

    function setList(string memory _Ping,string memory _Pong) external returns(bool) {
            require(whiteList[msg.sender]," have no right ");
            PingPongList[_Ping] = _Pong;
            return true;
    }

    function getData(string memory _Ping,string memory _Pong) external view returns(bytes memory data){

        data = abi.encodeWithSelector(PingPong.setList.selector,_Ping,_Pong);
    }

    function setWhiteList(address _executeAddress) external {
        whiteList[_executeAddress] = true;
    }
}
