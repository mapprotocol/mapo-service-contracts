// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeService {
    function getMessageFee(
        uint256 _chainId,
        address _feeToken
    ) external view returns (uint256 _base, uint256 _gasPrice, address _receiverAddress);
}
