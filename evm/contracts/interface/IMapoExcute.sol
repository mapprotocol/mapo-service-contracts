// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^8.0.7;

interface IMapoExcute {

    function mapoExcute(uint16 _srcChainId, bytes calldata _target, bytes32 _orgerId, bytes calldata _callData) external;
}
