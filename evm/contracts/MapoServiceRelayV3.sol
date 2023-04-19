// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@mapprotocol/protocol/contracts/interface/ILightClientManager.sol";
import "./MapoServiceV3.sol";
import "./utils/NearDecoder.sol";

contract MapoServiceRelayV3 is MapoServiceV3 {

    ILightClientManager public lightClientManager;

    mapping(uint256 => bytes) public mosContracts;

    event SetLightClientManager(address lightClient);
    event RegisterChain(uint256 _chainId, bytes _address, ChainType _type);

    function initialize(address _wToken, address _managerAddress)
    public
    override
    initializer
    checkAddress(_wToken)
    checkAddress(_managerAddress)
    {
        wToken = _wToken;
        lightClientManager = ILightClientManager(_managerAddress);
        _changeAdmin(tx.origin);
    }

    function setLightClientManager(address _managerAddress) external onlyOwner checkAddress(_managerAddress) {
        lightClientManager = ILightClientManager(_managerAddress);
        emit SetLightClientManager(_managerAddress);
    }

    function registerChain(uint256 _chainId, bytes memory _address, ChainType _type) external onlyOwner {
        mosContracts[_chainId] = _address;
        chainTypes[_chainId] = _type;
        emit RegisterChain(_chainId, _address, _type);
    }

    function transferIn(uint256 _chainId, bytes memory _receiptProof) external override nonReentrant whenNotPaused {
        (bool success,string memory message,bytes memory logArray) = lightClientManager.verifyProofData(_chainId, _receiptProof);
        require(success, message);
        if (chainTypes[_chainId] == ChainType.NEAR) {
            (bytes memory mosContract, IEvent.transferOutEvent[] memory outEvents) = NearDecoder.decodeNearLog(logArray);
            for (uint i = 0; i < outEvents.length; i++) {
                IEvent.transferOutEvent memory outEvent = outEvents[i];
                if (outEvent.toChain == 0) {continue;}
                require(Utils.checkBytes(mosContract, mosContracts[_chainId]), "invalid mos contract");
                // TODO
            }
        } else if (chainTypes[_chainId] == ChainType.EVM) {
            LogDecoder .txLog[] memory logs = LogDecoder.decodeTxLogs(logArray);
            for (uint256 i = 0; i < logs.length; i++) {
                LogDecoder .txLog memory log = logs[i];
                bytes32 topic = abi.decode(log.topics[0], (bytes32));

                if (topic == EvmDecoder.MAP_MESSAGE_TOPIC) {
                    bytes memory mosContract = Utils.toBytes(log.addr);
                    if (Utils.checkBytes(mosContract, mosContracts[_chainId])) {
                        (, IEvent.dataOutEvent memory outEvent) = EvmDecoder.decodeDataLog(log);
                        _messageIn(_chainId, outEvent);
                    }
                }
            }
        } else {
            require(false, "chain type error");
        }

        emit mapTransferExecute(_chainId, selfChainId, msg.sender);
    }

    function _messageIn(uint256 _chainId, IEvent.dataOutEvent memory _outEvent) internal checkOrder(_outEvent.orderId)  {

        require(_chainId == _outEvent.fromChain, "MOS: invalid chain id");

        MessageData memory msgData = abi.decode(_outEvent.messageData,(MessageData));
        if(_outEvent.toChain == selfChainId){

            address target = Utils.fromBytes(msgData.target);
            if (msgData.msgType == MessageType.CALLDATA && callerList[target][_chainId][_outEvent.fromAddress]){
                (bool success,bytes memory reason) = target.call{gas: msgData.gasLimit}(msgData.payload);
                if(success){

                    emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, true, bytes(""));

                }else{

                    emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, false, reason);
                }
            }else if(msgData.msgType == MessageType.MESSAGE){
                try IMapoExecutor(target).mapoExecute{gas: msgData.gasLimit}(_outEvent.fromChain, _outEvent.toChain, _outEvent.fromAddress,_outEvent.orderId, msgData.payload) {

                    emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, true, bytes(""));

                } catch (bytes memory reason) {

                   emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, false, reason);
                }
            }
        }else{
            if(msgData.relay){
                address target = Utils.fromBytes(msgData.target);
                if (msgData.msgType == MessageType.CALLDATA && callerList[target][_chainId][_outEvent.fromAddress]){
                    (bool success,bytes memory reason) = target.call{gas: msgData.gasLimit}(msgData.payload);
                    if(success){

                        emit mapMessageOut(_outEvent.fromChain,_outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,reason);

                    }else{

                        emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, false, reason);
                    }
                }else if(msgData.msgType == MessageType.MESSAGE){
                    try IMapoExecutor(target).mapoExecute{gas: msgData.gasLimit}(_outEvent.fromChain, _outEvent.toChain, _outEvent.fromAddress,_outEvent.orderId, msgData.payload) returns (bytes memory newMessageData) {

                        emit mapMessageOut(_outEvent.fromChain,_outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,newMessageData);

                    } catch (bytes memory reason) {

                        emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress, msgData.payload, false, reason);
                    }
                }

            }else{
                emit mapMessageOut(_outEvent.fromChain,_outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,_outEvent.messageData);
            }


        }
    }


}
