// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../interface/IEvent.sol";
import "./RLPReader.sol";
import "./Utils.sol";

library EvmDecoder {

    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    bytes32 constant MAP_MESSAGE_TOPIC = keccak256(bytes('mapMessageOut(uint256,uint256,bytes32,bytes,bytes)'));


    function decodeTxLogs(bytes memory logsHash)
    internal
    pure
    returns (IEvent.txLog[] memory _txLogs){
        RLPReader.RLPItem[] memory ls = logsHash.toRlpItem().toList();
        _txLogs = new IEvent.txLog[](ls.length);
        for (uint256 i = 0; i < ls.length; i++) {
            RLPReader.RLPItem[] memory item = ls[i].toList();

            require(item.length >= 3, "log length to low");

            RLPReader.RLPItem[] memory firstItemList = item[1].toList();
            bytes[] memory topic = new bytes[](firstItemList.length);
            for (uint256 j = 0; j < firstItemList.length; j++) {
                topic[j] = firstItemList[j].toBytes();
            }
            _txLogs[i] = IEvent.txLog({
            addr : item[0].toAddress(),
            topics : topic,
            data : item[2].toBytes()
            });
        }
    }

    function decodeDataLog(IEvent.txLog memory log)
    internal
    pure
    returns (bytes memory executorId, IEvent.dataOutEvent memory outEvent){
        executorId = Utils.toBytes(log.addr);
        outEvent.fromChain = abi.decode(log.topics[1], (uint256));
        outEvent.toChain = abi.decode(log.topics[2], (uint256));

        (outEvent.orderId, outEvent.fromAddress,outEvent.cData)
        = abi.decode(log.data, (bytes32,bytes,bytes));
    }


}
