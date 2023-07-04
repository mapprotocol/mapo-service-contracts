// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@mapprotocol/protocol/contracts/lib/RLPEncode.sol";

contract LightNode {

    function verifyProofData(bytes memory _receiptProof)
    external
    pure
    returns (bool success, string memory message, bytes memory logs){

        return(true,"success",_receiptProof);
    }

    struct txLog {
        address addr;
        bytes[] topics;
        bytes data;
    }

    function encodeTxLog(txLog[] memory _txLogs)
    external
    pure
    returns (bytes memory output){
        bytes[] memory listLog = new bytes[](_txLogs.length);
        bytes[] memory loglist = new bytes[](3);
        for (uint256 j = 0; j < _txLogs.length; j++) {
            loglist[0] = RLPEncode.encodeAddress(_txLogs[j].addr);
            bytes[] memory loglist1 = new bytes[](_txLogs[j].topics.length);
            for (uint256 i = 0; i < _txLogs[j].topics.length; i++) {
                loglist1[i] = RLPEncode.encodeBytes(_txLogs[j].topics[i]);
            }
            loglist[1] = RLPEncode.encodeList(loglist1);
            loglist[2] = RLPEncode.encodeBytes(_txLogs[j].data);
            bytes memory logBytes = RLPEncode.encodeList(loglist);
            listLog[j] = logBytes;
        }
        output = RLPEncode.encodeList(listLog);
    }
}
