// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

interface IMapoExcute {

    function mapoExcute(uint256 _srcChainId, bytes calldata _fromAddress, bytes32 _orgerId, bytes calldata _callData) external;



}
