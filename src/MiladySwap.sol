// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

interface IVerifier {
    function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[1] memory input)
        external
        returns (bool r);
}

contract MiladySwap {
    struct Swap {
        uint256 tokenId1;
        uint256 tokenId2;
        uint8 state; // 0 = not started, 1 = started, 2 = accepted, 3 = finished.
    }

    event SwapStarted(address indexed initiator, address indexed receiver, uint256 tokenId1, uint256 tokenId2);
    event SwapAccepted(address indexed initiator, address indexed receiver, uint256 tokenId1, uint256 tokenId2);
    event SwapFinished(address indexed initiator, address indexed receiver, uint256 tokenId1, uint256 tokenId2);

    /// @notice The ongoing swaps.
    mapping(address => mapping(address => Swap)) swaps;
    /// @notice The Milady NFT contract.
    IERC721 public milady;
    /// @notice The ZK-SNARKs verifier associated with this swap.
    IVerifier public verifier;

    constructor(address _milady, address _verifier) {
        milady = IERC721(_milady);
        verifier = IVerifier(_verifier);
    }

    /// @notice Starts the ZK-Swap. This action cannot be cancelled.
    /// @param receiver The receiver of the milady, which will interact with the contract later.
    /// @param _tokenId1 The ID of the caller's milady to swap.
    /// @param _tokenId2 the ID of the receiver's milady to swap. 
    function startZKSwap(address receiver, uint256 _tokenId1, uint256 _tokenId2) external {
        swaps[msg.sender][receiver] = Swap({tokenId1: _tokenId1, tokenId2: _tokenId2, state: 1});

        emit SwapStarted(msg.sender, receiver, _tokenId1, _tokenId2);
    }

    /// @notice Accepts the ZK-Swap. This action cannot be cancelled. 
    /// @param initiator The address who initiated the transfer.
    function acceptZKSwap(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input,
        address initiator
    ) external {
        Swap storage swap = swaps[initiator][msg.sender];
        require(swap.state == 1, "incorrect swap state");
        swap.state = 2;
        // Verify the ZKP.
        bool success = verifier.verifyProof(a, b, c, input);
        require(success, "invalid proof");

        // Transfer the NFTs to this contract.
        milady.safeTransferFrom(initiator, address(this), swap.tokenId1);
        milady.safeTransferFrom(msg.sender, address(this), swap.tokenId2);

        emit SwapAccepted(initiator, msg.sender, swap.tokenId1, swap.tokenId2);
    }

    /// Finishes the ongoing swap.
    /// @param initiator The address who initiated the swap.
    /// @param receiver The address who accepted the swap.
    function finishZKSwap(address initiator, address receiver) external {
        Swap storage swap = swaps[initiator][receiver];
        require(swap.state == 2, "incorrect swap state");
        swap.state = 3;
        // Transfer the NFTs to the respective parties.
        milady.transferFrom(address(this), initiator, swap.tokenId2);
        milady.transferFrom(address(this), receiver, swap.tokenId1);

        emit SwapFinished(initiator, receiver, swap.tokenId1, swap.tokenId2);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
