// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

interface IMapoExecutor {

    function mapoExecute(uint256 _srcChainId, bytes calldata _fromAddress, bytes32 _orderId, bytes calldata _message) external;



}
