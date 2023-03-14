// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IFeeService {
    function getMessageFee(uint256 _chainId,address _feeToken)
    external
    view
    returns(uint256 feeValue,uint256 chainPrice,address receiverAddress);
}
