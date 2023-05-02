// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Verifier as InitVerifier} from "./verifiers/init_verifier.sol";
import {Verifier as MoveVerifier} from "./verifiers/move_verifier.sol";

contract Game {
    address public player1;
    address public player2 = address(0);
    bool public player2HasJoined = false;
    bool public gameOver = false;
    uint256 public buyIn;
    uint256 mostRecentP1Timestamp = 0;
    uint256 mostRecentP2Timestamp = 0;
    InitVerifier initVerif = new InitVerifier();
    uint p1FleetHash = 0;
    uint p1StateHash = 0;
    uint p1SaltHash = 0;
    uint p2FleetHash = 0;
    uint p2StateHash = 0;
    uint p2SaltHash = 0;

    constructor() payable {
        player1 = msg.sender;
        buyIn = msg.value;
        require(buyIn <= 1 ether, "Don't bet more than 1 ether.");
    }

    modifier gameNotOver() {
        require (!gameOver, "The game is over.");
        _;
    }

    modifier player2Joined(bool isTrue) {
        require (player2HasJoined == isTrue, player2HasJoined ? "Player 2 has already joined." : "Player 2 hasn't joined yet.");
        _;
    }

    modifier isPlayer(bool isPlayer1) {
        require ((isPlayer1 && msg.sender == player1) || (!isPlayer1 && msg.sender == player2), "You are not the player you say you are.");
        _;
    }

    modifier playerTimedOut(bool isPlayer1) {
        require (
            (isPlayer1 && block.timestamp > mostRecentP1Timestamp + 1 days) || (!isPlayer1 && block.timestamp > mostRecentP2Timestamp + 1 days),
            "The player has not timed out yet."
        );
        _;
    }

    modifier playerBoardStatus(bool isPlayer1, bool isInitialized) {
        if (isPlayer1) {
            require(
                (p1FleetHash != 0 && p1StateHash != 0 && p1SaltHash != 0) == isInitialized,
                isInitialized ? "Player 1 not yet initialized" : "Player 1 already initialized"
            );
        }
        else {
            require(
                (p2FleetHash != 0 && p2StateHash != 0 && p2SaltHash != 0) == isInitialized,
                isInitialized ? "Player 2 not yet initialized" : "Player 2 already initialized"
            );
        }
        _;
    }

    function cancelGame() public isPlayer(true) player2Joined(false) {
        gameOver = true;
        payable(msg.sender).transfer(address(this).balance);
    }

    function joinAsPlayer2() public payable gameNotOver() player2Joined(false) {
        require (msg.value == buyIn, "You did not buy in to the prize pool with the correct amount.");
        player2 = msg.sender;
        player2HasJoined = true;
        mostRecentP1Timestamp = block.timestamp;
        mostRecentP2Timestamp = block.timestamp;
    }

    function forfeit(bool iAmPlayer1) public gameNotOver() player2Joined(true) isPlayer(iAmPlayer1) {
        gameOver = true;
        if (iAmPlayer1) {
            payable(player2).transfer(address(this).balance);
        }
        else {
            payable(player1).transfer(address(this).balance);
        }
    }

    function inactivityTimeout(bool iAmPlayer1) public gameNotOver() player2Joined(true) isPlayer(iAmPlayer1) playerTimedOut(!iAmPlayer1) {
        gameOver = true;
        if (iAmPlayer1) {
            payable(player1).transfer(address(this).balance);
        }
        else {
            payable(player2).transfer(address(this).balance);
        }
    }

    function initializeBoard(
            bool iAmPlayer1,
            uint[2] calldata proof_a,
            uint[2][2] calldata proof_b,
            uint[2] calldata proof_c,
            uint[3] calldata proof_input
        ) public gameNotOver() isPlayer(iAmPlayer1) playerBoardStatus(iAmPlayer1, false) {
            require(initVerif.verifyProof(proof_a, proof_b, proof_c, proof_input), "Initialize board proof invalid.");
            if (iAmPlayer1) {
                if (player2HasJoined) {
                    mostRecentP1Timestamp = block.timestamp;
                }
                (p1FleetHash, p1StateHash, p1SaltHash) = (proof_input[0], proof_input[1], proof_input[2]); 
            }
            else {
                mostRecentP2Timestamp = block.timestamp;
                (p2FleetHash, p2StateHash, p2SaltHash) = (proof_input[0], proof_input[1], proof_input[2]); 
            }
    }

}