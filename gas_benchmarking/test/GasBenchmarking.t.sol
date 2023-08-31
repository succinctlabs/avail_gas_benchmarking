// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GasBenchmarking.sol";

contract GasBenchmarkingTest is Test {
    GasBenchmarking public gasBenchmarking;

    function setUp() public {
        gasBenchmarking = new GasBenchmarking();
        bytes32[] memory leaves = new bytes32[](180);
        for (uint256 i = 0; i < 180; i++) {
            leaves[i] = bytes32(i);   // For this test, all the data root hashes will just be the block number itself
        }
        gasBenchmarking.submitDataRootMerkleRoot(leaves, 0, 180);
    }

    function testVerifyMerkleProof() public {
        uint256 merkleRootIdx = 0;
        uint256 blockNum = 50;
        bytes32 claimedDataRoot = bytes32(blockNum);   // For this test, all the data root hashes will just be the block number itself
        bytes32[] memory proof = gasBenchmarking.getMerkleProof(merkleRootIdx, blockNum);
        assertEq(gasBenchmarking.verifyDataRoot(merkleRootIdx, proof, claimedDataRoot, blockNum), true);
    }

    function testVerifyMerkleProofCalldata() public {
        uint256 merkleRootIdx = 0;
        uint256 blockNum = 50;
        bytes32 claimedDataRoot = bytes32(blockNum);   // For this test, all the data root hashes will just be the block number itself
        bytes32[] memory proof = gasBenchmarking.getMerkleProof(merkleRootIdx, blockNum);
        assertEq(gasBenchmarking.verifyDataRootCalldata(merkleRootIdx, proof, claimedDataRoot, blockNum), true);
    }
}
