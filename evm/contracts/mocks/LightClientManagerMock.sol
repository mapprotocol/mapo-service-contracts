// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@mapprotocol/protocol/contracts/interface/ILightClientManager.sol";
import "@mapprotocol/protocol/contracts/interface/ILightNode.sol";

contract LightClientManager is ILightClientManager, Ownable {
    mapping(uint256 => address) public lightClientContract;
    mapping(uint256 => address) public updateBlockContract;

    function register(uint256 _chainId, address _contract, address _blockContract) external onlyOwner {
        lightClientContract[_chainId] = _contract;
        updateBlockContract[_chainId] = _blockContract;
    }

    function updateBlockHeader(uint256 _chainId, bytes memory _blockHeader) external override {
        require(updateBlockContract[_chainId] != address(0), "not register");
        ILightNode lightNode = ILightNode(updateBlockContract[_chainId]);
        lightNode.updateBlockHeader(_blockHeader);
    }

    function notifyLightClient(uint256 _chainId, address _from, bytes memory _data) external override {

    }

    function verifyProofDataWithCache(
        uint256 _chainId,
        bytes memory _receiptProof
    ) external override returns (bool success, string memory message, bytes memory logs) {
        return (true, "success", _receiptProof);
    }

    function verifyProofData(
        uint _chainId,
        bytes memory _receiptProof
    ) external pure override returns (bool success, string memory message, bytes memory logs) {
        //        require(lightClientContract[_chainId] != address(0), "not register");
        //        ILightNode lightNode = ILightNode(lightClientContract[_chainId]);
        //        return lightNode.verifyProofData(_receiptProof);
        if (_chainId == 888) {
            return (false, "fail", _receiptProof);
        } else {
            return (true, "success", _receiptProof);
        }
    }

    function clientState(uint256) external pure override returns (bytes memory) {
        bytes memory b;
        return b;
    }

    function updateLightClient(uint256 _chainId, bytes memory _data) external override {}

    function headerHeight(uint256 _chainId) external view override returns (uint256) {
        require(lightClientContract[_chainId] != address(0), "not register");
        ILightNode lightNode = ILightNode(updateBlockContract[_chainId]);

        return lightNode.headerHeight();
    }

    function verifiableHeaderRange(uint256) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function finalizedState(uint256, bytes memory) external view override returns (bytes memory) {
        bytes memory b;
        return b;
    }

    function isVerifiable(uint256 _chainId, uint256 _blockHeight, bytes32 _hash) external view override returns (bool) {
        return true;
    }

    function nodeType(uint256 _chainId) external view override returns (uint256) {
        return 3;
    }
}
