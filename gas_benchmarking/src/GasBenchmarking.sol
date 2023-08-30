// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract GasBenchmarking {
    bytes32 public root;

    mapping(bytes32 => bytes32[2]) children;

    // # of leaves is 180 (1 hours worth of blocks)
    // Height is 8
    // Siblings is the merkle proof and is length 8 (don't need the last one as its the root)
    // Index is the location of the value within the merkle tree (0 indexed)
    function verifyMerkleProof(bytes32[] memory siblings, bytes32 value, uint256 index) public view returns (bool) {
        bytes32 hash = value;
        for (uint256 i = 0; i < siblings.length; i++) {
            bool siblingIsRight = index & (1 << i) == 0;

            if (siblingIsRight) {
                hash = keccak256(abi.encodePacked(hash, siblings[i]));
            } else {
                hash = keccak256(abi.encodePacked(siblings[i], hash));
            }
        }
        return hash == root;
    }

    // # of leaves is 180 (1 hours worth of blocks)
    // Height is 8
    // Siblings is the merkle proof and is length 8 (don't need the last one as its the root)
    // Index is the location of the value within the merkle tree (0 indexed)
    function verifyMerkleProofCalldata(bytes32[] calldata siblings, bytes32 value, uint256 index) public view returns (bool) {
        bytes32 hash = value;
        for (uint256 i = 0; i < siblings.length; i++) {
            bool siblingIsRight = index & (1 << i) == 0;

            if (siblingIsRight) {
                hash = keccak256(abi.encodePacked(hash, siblings[i]));
            } else {
                hash = keccak256(abi.encodePacked(siblings[i], hash));
            }
        }
        return hash == root;
    }

    // # of leaves is 180 (1 hours worth of blocks)
    function getMerkleProof(uint256 index) public view returns (bytes32[] memory siblings) {
        require(index < 180, "index must be less than 180");

        siblings = new bytes32[](8);
        bytes32 nodeIter = root;
        for (uint256 i = 7; i >= 0; i --) {
            bool childIsLeft = (index & (1 << i) == 0);

            if (childIsLeft) {
                siblings[i] = children[nodeIter][1];
                nodeIter = children[nodeIter][0];
            } else {
                siblings[i] = children[nodeIter][0];
                nodeIter = children[nodeIter][1];
            }

            if (i == 0) {
                break;
            }
        }

        return siblings;
    }

    // # of leaves is 180 (1 hours worth of blocks)
    function calculateMerkeRoot(bytes32[] memory _dataRoots) public {
        require(_dataRoots.length == 180, "leave length must be 180");

        bytes32[] memory currentLevelNodes = new bytes32[](256);
        bytes32[] memory nextLevelNodes;

        for (uint256 i = 0; i < _dataRoots.length; i++) {
            currentLevelNodes[i] = _dataRoots[i];
        }

        // Add dummy data so that the leaves length is a power of 2
        for (uint256 i = _dataRoots.length; i < 256; i++) {
            currentLevelNodes[i] = bytes32(0);
        }

        while (true) {
            if (nextLevelNodes.length == 1) {
                root = nextLevelNodes[0];
                return;
            }

            nextLevelNodes = new bytes32[](currentLevelNodes.length / 2);

            for (uint256 i = 0; i < currentLevelNodes.length; i += 2) {
                bytes32 left = currentLevelNodes[i];
                bytes32 right = currentLevelNodes[i + 1];
                bytes32 node = keccak256(abi.encodePacked(left, right));
                children[node] = [left, right];
                nextLevelNodes[i/2] = node;
            }

            currentLevelNodes = nextLevelNodes;
        }
        assert(false);
    }
}