// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFeeService.sol";

contract FeeService is IFeeService,Ownable {
    address public feeReceiver;
    mapping(uint256 => uint256) baseGasLimit;
    mapping(uint256 => mapping(address => uint256)) chainGasPrice;

    event SetBaseGasLimit(uint256 chainId,uint256 basLimit);
    event SetChainGasPrice(uint256 chainId,uint256 chainPrice);
    event SetFeeReceiver(address receiver);

    function getMessageFee(uint256 _chainId,address _feeToken) external override view returns(uint256 baseLimit,uint256 chainPrice,address receiverAddress){

        return (baseGasLimit[_chainId], chainGasPrice[_chainId][_feeToken],feeReceiver);
    }

    function setBaseGasLimit(uint256 _chainId,uint256 _basLimit) external onlyOwner {
        baseGasLimit[_chainId] = _basLimit;
        emit SetBaseGasLimit(_chainId,_basLimit);
    }

    function setChainGasPrice(uint256 _chainId,uint256 _chainPrice) external onlyOwner {
        chainGasPrice[_chainId] = _chainPrice;
        emit SetChainGasPrice(_chainId,_chainPrice);
    }

    function setFeeReceiver(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
        emit SetFeeReceiver(_receiver);
    }
}