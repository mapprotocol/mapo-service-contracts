// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEvent {
    struct transferOutEvent {
        bytes token;
        bytes from;
        bytes32 orderId;
        uint256 fromChain;
        uint256 toChain;
        bytes to;
        uint256 amount;
        bytes toChainToken;
    }

    struct dataOutEvent {
        bytes32 orderId;
        uint256 fromChain;
        uint256 toChain;
        bytes fromAddress;
        bytes messageData;
    }
}
