// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interface/IFeeService.sol";

contract FeeService is IFeeService {
    address public feeReceiver;
    address public owner;
    mapping(uint256 => uint256) public baseGas; // chainid => gas
    mapping(uint256 => mapping(address => uint256)) public chainGasPrice; // chain => (feeToken => gasPrice)

    event SetBaseGas(uint256 chainId,uint256 basLimit);
    event SetChainGasPrice(uint256 chainId,uint256 chainPrice);
    event SetFeeReceiver(address receiver);

    constructor(address _owner){
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "fee service only admin");
        _;
    }

    function getMessageFee(uint256 _chainId,address _feeToken) external override view returns(uint256 _base,uint256 _gasPrice,address _receiverAddress){

        return (baseGas[_chainId], chainGasPrice[_chainId][_feeToken], feeReceiver);
    }

    function setBaseGas(uint256 _chainId,uint256 _baseLimit) external onlyOwner {
        baseGas[_chainId] = _baseLimit;
        emit SetBaseGas(_chainId,_baseLimit);
    }

    function setChainGasPrice(uint256 _chainId,address _token,uint256 _chainPrice) external onlyOwner {
        chainGasPrice[_chainId][_token] = _chainPrice;
        emit SetChainGasPrice(_chainId,_chainPrice);
    }

    function setFeeReceiver(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
        emit SetFeeReceiver(_receiver);
    }
}