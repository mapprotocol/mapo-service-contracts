// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFeeService.sol";

contract FeeService is IFeeService,Ownable {
    address public feeReceiver;
    mapping(uint256 => mapping(bytes => uint256)) public messageFee;

    function getMessageFee(uint256 _chainId, bytes memory _target) external override view returns(uint256 feeValue,address receiverAddress){

        return (messageFee[_chainId][_target], feeReceiver);
    }

    function setMessageFee(uint256 _chainId, bytes memory _target,uint256 _fee) external onlyOwner {
        messageFee[_chainId][_target] = _fee;
    }


}