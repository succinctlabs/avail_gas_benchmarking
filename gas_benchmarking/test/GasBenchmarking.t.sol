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
            leaves[i] = bytes32(i);
        }
        gasBenchmarking.calculateMerkeRoot(leaves);
    }

    function testVerifyMerkleProof() public {
        uint256 index = 50;
        bytes32[] memory proof = gasBenchmarking.getMerkleProof(index);
        assertEq(gasBenchmarking.verifyMerkleProof(proof, bytes32(index), index), true);
    }

    function testVerifyMerkleProofCalldata() public {
        uint256 index = 50;
        bytes32[] memory proof = gasBenchmarking.getMerkleProof(index);
        assertEq(gasBenchmarking.verifyMerkleProofCalldata(proof, bytes32(index), index), true);
    }
}
