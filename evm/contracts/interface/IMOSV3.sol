// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IMOSV3 {

    enum ChainType{
        NULL,
        EVM,
        NEAR
    }

    enum MessageType {
        CALLDATA,
        MESSAGE
    }


    struct MessageData {
        MessageType msgType;
        bytes target;
        bytes payload;
        uint256 gasLimit;
        uint256 value;
    }

    function getMessageFee(uint256 _toChain, address _feeToken, uint256 _gasLimit) external view returns(uint256, address);

    function transferOut(uint256 _toChain, bytes memory _messageData,address _feeToken) external payable  returns(bool);


    function addRemoteCaller(uint256 _fromChain, bytes memory _fromAddress,bool _tag) external;

    event mapMessageOut(uint256 indexed fromChain, uint256 indexed toChain,bytes32 orderId, bytes fromAddrss, bytes callData);

    event mapMessageIn(uint256 indexed fromChain, uint256 indexed toChain, bytes32 orderId, bytes fromAddrss, bytes callData, bool result, bytes reason);

    //event mapMessageInError(uint256 indexed fromChain, uint256 indexed toChain, bytes32 orderId, bytes fromAddrss, bytes callData, bytes reason);
}