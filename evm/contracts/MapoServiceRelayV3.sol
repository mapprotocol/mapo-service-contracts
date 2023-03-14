// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./MapoServiceV3.sol";
import "./interface/ILightClientManager.sol";
import "./utils/NearDecoder.sol";


contract MapoServiceRelayV3 is MapoServiceV3 {

    ILightClientManager public lightClientManager;

    mapping(uint256 => bytes) public mosContracts;

    event SetLightClientManager(address lightClient);
    event RegisterChain(uint256 _chainId, bytes _address, chainType _type);

    function initialize(address _wToken, address _managerAddress) public override initializer
    checkAddress(_wToken) checkAddress(_managerAddress) {
        wToken = _wToken;
        lightClientManager = ILightClientManager(_managerAddress);
        _changeAdmin(msg.sender);
    }

    function setLightClientManager(address _managerAddress) external onlyOwner checkAddress(_managerAddress) {
        lightClientManager = ILightClientManager(_managerAddress);
        emit SetLightClientManager(_managerAddress);
    }

    function registerChain(uint256 _chainId, bytes memory _address, chainType _type) external onlyOwner {
        mosContracts[_chainId] = _address;
        chainTypes[_chainId] = _type;
        emit RegisterChain(_chainId, _address, _type);
    }

    function transferIn(uint256 _chainId, bytes memory _receiptProof) external override nonReentrant whenNotPaused {
        (bool success,string memory message,bytes memory logArray) = lightClientManager.verifyProofData(_chainId, _receiptProof);
        require(success, message);
        if (chainTypes[_chainId] == chainType.NEAR) {
            (bytes memory mosContract, IEvent.transferOutEvent[] memory outEvents) = NearDecoder.decodeNearLog(logArray);
            for (uint i = 0; i < outEvents.length; i++) {
                IEvent.transferOutEvent memory outEvent = outEvents[i];
                if (outEvent.toChain == 0) {continue;}
                require(Utils.checkBytes(mosContract, mosContracts[_chainId]), "invalid mos contract");
                // TODO
            }
        } else if (chainTypes[_chainId] == chainType.EVM) {
            IEvent.txLog[] memory logs = EvmDecoder.decodeTxLogs(logArray);
            for (uint256 i = 0; i < logs.length; i++) {
                IEvent.txLog memory log = logs[i];
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

        if(_outEvent.toChain == selfChainId){

            CallData memory cData = abi.decode(_outEvent.cData,(CallData));

            address callDataAddress = Utils.fromBytes(cData.target);

            bool success;

            if(messageWhiteList[callDataAddress]){
                (success, ) = callDataAddress.call{gas:cData.gasLimit}(cData.callData);
            }

            emit mapMessageIn(_outEvent.fromChain, _outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,cData.callData,success);

        }else{

            emit mapMessageOut(selfChainId,_outEvent.toChain,_outEvent.orderId,_outEvent.fromAddress,_outEvent.cData);
        }
    }


}
