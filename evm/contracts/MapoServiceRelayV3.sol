// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@mapprotocol/protocol/contracts/interface/ILightClientManager.sol";
import "./MapoServiceV3.sol";
import "./utils/NearDecoder.sol";

contract MapoServiceRelayV3 is MapoServiceV3 {
    ILightClientManager public lightClientManager;

    mapping(uint256 => bytes) public mosContracts;
    mapping(uint256 => ChainType) public chainTypes;

    event SetLightClientManager(address lightClient);
    event RegisterChain(uint256 _chainId, bytes _address, ChainType _type);

    function initialize(
        address _wToken,
        address _managerAddress
    ) public override initializer checkAddress(_wToken) checkAddress(_managerAddress) {
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

    function getOrderStatus(
        uint256 _chainId,
        uint256 _blockNum,
        bytes32 _orderId
    ) external view override returns (bool exists, bool verifiable, uint256 nodeType) {
        exists = orderList[_orderId];
        verifiable = lightClientManager.isVerifiable(_chainId, _blockNum, bytes32(""));
        nodeType = lightClientManager.nodeType(_chainId);
    }

    function transferOut(
        uint256 _toChain,
        bytes memory _messageData,
        address _feeToken
    ) external payable override nonReentrant whenNotPaused returns (bytes32) {
        bytes32 orderId = _transferOut(_toChain, _messageData, _feeToken);

        _notifyLightClient(_toChain, bytes(""));

        return orderId;
    }

    function transferIn(uint256 _chainId, bytes memory _receiptProof) external override nonReentrant whenNotPaused {
        (bool success, string memory message, bytes memory logArray) = lightClientManager.verifyProofData(
            _chainId,
            _receiptProof
        );
        require(success, message);
        if (chainTypes[_chainId] == ChainType.NEAR) {
            (bytes memory mosContract, IEvent.transferOutEvent[] memory outEvents) = NearDecoder.decodeNearLog(
                logArray
            );
            for (uint i = 0; i < outEvents.length; i++) {
                IEvent.transferOutEvent memory outEvent = outEvents[i];
                if (outEvent.toChain == 0) {
                    continue;
                }
                require(Utils.checkBytes(mosContract, mosContracts[_chainId]), "MOSV3: Invalid mos contract");
                // TODO support near
            }
        } else if (chainTypes[_chainId] == ChainType.EVM) {
            LogDecoder.txLog[] memory logs = LogDecoder.decodeTxLogs(logArray);
            for (uint256 i = 0; i < logs.length; i++) {
                LogDecoder.txLog memory log = logs[i];
                bytes32 topic = abi.decode(log.topics[0], (bytes32));

                if (topic == EvmDecoder.MAP_MESSAGE_TOPIC) {
                    bytes memory mosContract = Utils.toBytes(log.addr);
                    if (Utils.checkBytes(mosContract, mosContracts[_chainId])) {
                        (, IEvent.dataOutEvent memory outEvent) = EvmDecoder.decodeDataLog(log);
                        _transferIn(_chainId, outEvent);
                    }
                }
            }
        } else {
            require(false, "MOSV3: Invalid chain type");
        }

        emit mapTransferExecute(_chainId, selfChainId, msg.sender);
    }

    function transferInWithIndex(
        uint256 _chainId,
        uint256 _logIndex,
        bytes memory _receiptProof
    ) external override nonReentrant whenNotPaused {
        (bool success, string memory message, bytes memory logArray) = lightClientManager.verifyProofDataWithCache(
            _chainId,
            _receiptProof
        );
        require(success, message);
        if (chainTypes[_chainId] == ChainType.NEAR) {
            (bytes memory mosContract, IEvent.transferOutEvent[] memory outEvents) = NearDecoder.decodeNearLog(
                logArray
            );
            IEvent.transferOutEvent memory outEvent = outEvents[_logIndex];
            require(outEvent.toChain != 0, "MOSV3: Invalid target chain id");
            require(Utils.checkBytes(mosContract, mosContracts[_chainId]), "MOSV3: Invalid mos contract");
            // TODO support near
        } else if (chainTypes[_chainId] == ChainType.EVM) {
            LogDecoder.txLog memory log = LogDecoder.decodeTxLog(logArray, _logIndex);
            bytes32 topic = abi.decode(log.topics[0], (bytes32));
            require(topic == EvmDecoder.MAP_MESSAGE_TOPIC, "MOSV3: Invalid topic");
            bytes memory mosContract = Utils.toBytes(log.addr);
            require(Utils.checkBytes(mosContract, mosContracts[_chainId]), "MOSV3: Invalid mos contract");

            (, IEvent.dataOutEvent memory outEvent) = EvmDecoder.decodeDataLog(log);
            _transferIn(_chainId, outEvent);
        } else {
            require(false, "MOSV3: Invalid chain type");
        }
    }

    function _transferIn(
        uint256 _chainId,
        IEvent.dataOutEvent memory _outEvent
    ) internal checkOrder(_outEvent.orderId) {
        require(_chainId == _outEvent.fromChain, "MOSV3: Invalid chain id");

        MessageData memory msgData = abi.decode(_outEvent.messageData, (MessageData));
        if (_outEvent.toChain == selfChainId) {
            _messageIn(_outEvent, msgData);
        } else {
            _messageRelay(_outEvent, msgData);
        }
    }

    function _messageRelay(IEvent.dataOutEvent memory _outEvent, MessageData memory msgData) internal {
        if (msgData.relay) {
            address target = Utils.fromBytes(msgData.target);
            if (msgData.msgType == MessageType.CALLDATA) {
                if (callerList[target][_outEvent.fromChain][_outEvent.fromAddress]) {
                    (bool success, bytes memory returnData) = target.call(msgData.payload);
                    if (success) {
                        _notifyLightClient(_outEvent.toChain, bytes(""));
                        emit mapMessageOut(
                            _outEvent.fromChain,
                            _outEvent.toChain,
                            _outEvent.orderId,
                            msgData.target,
                            returnData
                        );
                    } else {
                        emit mapMessageIn(
                            _outEvent.fromChain,
                            _outEvent.toChain,
                            _outEvent.orderId,
                            _outEvent.fromAddress,
                            msgData.payload,
                            false,
                            returnData
                        );
                    }
                } else {
                    emit mapMessageIn(
                        _outEvent.fromChain,
                        _outEvent.toChain,
                        _outEvent.orderId,
                        _outEvent.fromAddress,
                        msgData.payload,
                        false,
                        bytes("FromAddressNotCaller")
                    );
                }
            } else if (msgData.msgType == MessageType.MESSAGE) {
                if (AddressUpgradeable.isContract(target)) {
                    try
                        IMapoExecutor(target).mapoExecute(
                            _outEvent.fromChain,
                            _outEvent.toChain,
                            _outEvent.fromAddress,
                            _outEvent.orderId,
                            msgData.payload
                        )
                    returns (bytes memory newMessageData) {
                        _notifyLightClient(_outEvent.toChain, bytes(""));
                        emit mapMessageOut(
                            _outEvent.fromChain,
                            _outEvent.toChain,
                            _outEvent.orderId,
                            msgData.target,
                            newMessageData
                        );
                    } catch (bytes memory reason) {
                        emit mapMessageIn(
                            _outEvent.fromChain,
                            _outEvent.toChain,
                            _outEvent.orderId,
                            _outEvent.fromAddress,
                            msgData.payload,
                            false,
                            reason
                        );
                    }
                } else {
                    emit mapMessageIn(
                        _outEvent.fromChain,
                        _outEvent.toChain,
                        _outEvent.orderId,
                        _outEvent.fromAddress,
                        msgData.payload,
                        false,
                        bytes("NoContractAddress")
                    );
                }
            } else {
                emit mapMessageIn(
                    _outEvent.fromChain,
                    _outEvent.toChain,
                    _outEvent.orderId,
                    _outEvent.fromAddress,
                    msgData.payload,
                    false,
                    bytes("MessageTypeError")
                );
            }
        } else {
            _notifyLightClient(_outEvent.toChain, bytes(""));
            emit mapMessageOut(
                _outEvent.fromChain,
                _outEvent.toChain,
                _outEvent.orderId,
                _outEvent.fromAddress,
                _outEvent.messageData
            );
        }
    }

    function _notifyLightClient(uint256 _chainId, bytes memory _data) internal {
        lightClientManager.notifyLightClient(_chainId, address(this), _data);
    }
}
