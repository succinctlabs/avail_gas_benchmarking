// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct DataRootMerkleRoot {
    uint64 startBlockNum;
    uint64 endBlockNum;
    bytes32 root;
}

contract GasBenchmarking {
    mapping(uint256 => DataRootMerkleRoot) public dataRootMerkleRoots;
    uint256 currentMerkleRootIdx = 0;

    // THIS WILL NOT BE SAVED IN THE ACTUAL LIGHT CLIENT CONTRACT.
    mapping(bytes32 => bytes32[2]) children;

    // # of leaves is 180 (1 hours worth of blocks)
    // Height is 8
    // Proof contains the merkle proof and is length 8 (don't need the last one as its the root)
    function verifyDataRoot(uint256 dataRootAccID, bytes32[] memory proof, bytes32 value, uint256 blockNumber) public view returns (bool) {
        DataRootMerkleRoot memory merkleRoot = dataRootMerkleRoots[dataRootAccID];

        require(merkleRoot.startBlockNum <= blockNumber, "blockNumber must be greater than or equal to startBlockNumber");
        require(merkleRoot.endBlockNum >= blockNumber, "blockNumber must be less than or equal to endBlockNumber");


        uint256 treeIdx = blockNumber - merkleRoot.startBlockNum;
        bytes32 hash = value;
        for (uint256 i = 0; i < proof.length; i++) {
            bool siblingIsRight = treeIdx & (1 << i) == 0;

            if (siblingIsRight) {
                hash = keccak256(abi.encodePacked(hash, proof[i]));
            } else {
                hash = keccak256(abi.encodePacked(proof[i], hash));
            }
        }
        return hash == merkleRoot.root;
    }

    // # of leaves is 180 (1 hours worth of blocks)
    // Height is 8
    // Siblings is the merkle proof and is length 8 (don't need the last one as its the root)
    // Index is the location of the value within the merkle tree (0 indexed)
    function verifyDataRootCalldata(uint256 dataRootAccID, bytes32[] calldata proof, bytes32 value, uint256 blockNumber) public view returns (bool) {
        DataRootMerkleRoot memory merkleRoot = dataRootMerkleRoots[dataRootAccID];

        require(merkleRoot.startBlockNum <= blockNumber, "blockNumber must be greater than or equal to startBlockNumber");
        require(merkleRoot.endBlockNum >= blockNumber, "blockNumber must be less than or equal to endBlockNumber");

        uint256 treeIdx = blockNumber - merkleRoot.startBlockNum;
        bytes32 hash = value;
        for (uint256 i = 0; i < proof.length; i++) {
            bool siblingIsRight = treeIdx & (1 << i) == 0;

            if (siblingIsRight) {
                hash = keccak256(abi.encodePacked(hash, proof[i]));
            } else {
                hash = keccak256(abi.encodePacked(proof[i], hash));
            }
        }
        return hash == merkleRoot.root;
    }

    // THIS WILL NOT BE SAVED IN THE ACTUAL LIGHT CLIENT CONTRACT
    // Intead, an off chain actor will need to save the merkle tree and service this request.

    // Each data root accumulator has 180 leaves (1 hours worth of blocks)
    function getMerkleProof(uint256 dataRootAccID, uint256 blockNumber) public view returns (bytes32[] memory siblings) {
        DataRootMerkleRoot memory merkleRoot = dataRootMerkleRoots[dataRootAccID];

        require(merkleRoot.startBlockNum <= blockNumber, "blockNumber must be greater than or equal to startBlockNumber");
        require(merkleRoot.endBlockNum >= blockNumber, "blockNumber must be less than or equal to endBlockNumber");

        siblings = new bytes32[](8);
        bytes32 nodeIter = merkleRoot.root;
        for (uint256 i = 7; i >= 0; i --) {
            bool childIsLeft = (blockNumber - merkleRoot.startBlockNum) & (1 << i) == 0;

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

    event NewDataRootMerkleRoot(uint256 merkleRootIdx, uint256 startBlockNum, uint256 endBlockNum, bytes32 root);

    // # of leaves is 180 (1 hours worth of blocks)
    // Calculate a data root merkle root and save it in the dataRootMerkleRoots struct.
    // Note that our circuit will be doing all this calculation, and the actual light client
    // smart contract will just be submitting the data root merkle root (after the submitted ZK proof is verified, ofc.)
    function submitDataRootMerkleRoot(bytes32[] memory _dataRoots, uint64 startBlockNum, uint64 endBlockNum) public {
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
                DataRootMerkleRoot memory newMerkleRoot = DataRootMerkleRoot({
                    startBlockNum: startBlockNum,
                    endBlockNum: endBlockNum,
                    root: nextLevelNodes[0]
                });
                dataRootMerkleRoots[currentMerkleRootIdx] = newMerkleRoot;
                emit NewDataRootMerkleRoot(currentMerkleRootIdx, startBlockNum, endBlockNum, nextLevelNodes[0]);

                currentMerkleRootIdx += 1;
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