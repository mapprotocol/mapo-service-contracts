// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@mapprotocol/protocol/contracts/lib/RLPReader.sol";
import "@mapprotocol/protocol/contracts/utils/Utils.sol";
import "@mapprotocol/protocol/contracts/lib/LogDecoder.sol";
import "../interface/IEvent.sol";

library EvmDecoder {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    bytes32 constant MAP_MESSAGE_TOPIC = keccak256(bytes("mapMessageOut(uint256,uint256,bytes32,bytes,bytes)"));

    function decodeDataLog(
        LogDecoder.txLog memory log
    ) internal pure returns (bytes memory executorId, IEvent.dataOutEvent memory outEvent) {
        executorId = Utils.toBytes(log.addr);
        outEvent.fromChain = abi.decode(log.topics[1], (uint256));
        outEvent.toChain = abi.decode(log.topics[2], (uint256));

        (outEvent.orderId, outEvent.fromAddress, outEvent.messageData) = abi.decode(log.data, (bytes32, bytes, bytes));
    }
}
