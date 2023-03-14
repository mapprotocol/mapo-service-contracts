// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IMOSV3 {

    enum chainType{
        NULL,
        EVM,
        NEAR
    }

    enum msgType {
        MESSAGE,
        CALLDATA
    }

    struct CallData {
        bytes target;
        bytes callData;
        uint256 gasLimit;
        uint256 value;
    }

    struct MessageData {
        msgType msgType;
        bytes target;
        bytes payload;
        uint256 gasLimit;
        uint256 value;
    }

    function transferOut(uint256 _toChain,MessageData memory _messageData,address _feeToken) external payable  returns(bool);

    event mapMessageOut(uint256 indexed fromChain, uint256 indexed toChain,bytes32 orderId, bytes fromAddrss, bytes callData);

    event mapMessageIn(uint256 indexed fromChain, uint256 indexed toChain, bytes32 orderId, bytes fromAddrss, bytes callData, bool executeTag);

}