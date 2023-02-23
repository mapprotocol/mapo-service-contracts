// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IFeeService {
    function getMessageFee(uint256 _chainId, bytes memory _target)
    external
    view
    returns(uint256 feeValue,address receiverAddress);
}
