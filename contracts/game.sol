/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Contract managing the flow of a game from start to finish.
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Verifier as InitVerifier} from "./init_verifier.sol";
import {Verifier as MoveVerifier} from "./move_verifier.sol";

contract Game {
    // Addresses of the players, and for the eventual winner
    address public player1;
    address public player2 = address(0);
    address public winner = address(0);
    // Whether or not a second player has joined yet, and whether the game has ended
    bool public player2HasJoined = false;
    bool public gameOver = false;
    // The monetary value (per-person) for this game. The prize pool is therefore 2x this
    uint256 public buyIn;
    // Timestamps that track when each player most recently engaged with the game, used to determine inactivity timeouts
    uint256 public mostRecentP1Timestamp = 0;
    uint256 public mostRecentP2Timestamp = 0;
    // zk-SNARK verfiers, auto-produced by snarkjs from the circom circuits
    InitVerifier private initVerif = new InitVerifier();
    MoveVerifier private moveVerif = new MoveVerifier();
    // Hash commmitments for both users zk proofs about their game board
    uint public p1FleetHash = 0;
    uint public p1StateHash = 0;
    uint public p1SaltHash = 0;
    uint public p2FleetHash = 0;
    uint public p2StateHash = 0;
    uint public p2SaltHash = 0;
    // The current turn, goes from 0-3 and cycles as gameplay progresses
    uint8 public turn = 0; // 0: p1 shoots, 1: p2 recieves, 2: p2 shoots, 3: p1 recieves
    uint8 public shotPos = 0;
    // Mappings from shot position code to result code, 0 for not-targeted, 10 for miss, and 11 for hit
    mapping(uint8 => uint8) public p1ShotsHit;
    mapping(uint8 => uint8) public p2ShotsHit;
    // Boolean array for which ships of each user's are sunk, in the standard canonical ordering
    bool[5] p1IsSunk;
    bool[5] p2IsSunk;

    // Constructs the game with the passed in address as player 1, and the msg value (<= 1 eth) as the buy in.
    constructor(address creator) payable {
        player1 = creator;
        buyIn = msg.value;
        require(buyIn <= 1 ether, "Don't bet more than 1 ether.");
    }

    // Adds the requirement that the game is not finished yet.
    modifier gameNotOver() {
        require (!gameOver, "The game is over.");
        _;
    }

    // Adds the requirement that whether or not the user has joined yet is the same as the parameter.
    modifier player2Joined(bool isTrue) {
        require (player2HasJoined == isTrue, player2HasJoined ? "Player 2 has already joined." : "Player 2 hasn't joined yet.");
        _;
    }

    // Adds the requirement that the msg sender is the player indicated by the parameter.
    modifier isPlayer(bool isPlayer1) {
        require ((isPlayer1 && msg.sender == player1) || (!isPlayer1 && msg.sender == player2), "You are not the player you say you are.");
        _;
    }

    // Adds the requirement that the player indicated by the parameter has timed out by being inactive for at least a day.
    modifier playerTimedOut(bool isPlayer1) {
        require (
            (isPlayer1 && block.timestamp > mostRecentP1Timestamp + 1 days) || (!isPlayer1 && block.timestamp > mostRecentP2Timestamp + 1 days),
            "The player has not timed out yet."
        );
        _;
    }

    // Adds the requirement that the player indicated by a parameter's board initialization status is the same as the other parameter.
    modifier playerBoardStatus(bool isPlayer1, bool isInitialized) {
        if (isPlayer1) {
            require(
                (p1FleetHash != 0 && p1StateHash != 0 && p1SaltHash != 0) == isInitialized,
                isInitialized ? "Player 1 not yet initialized" : "Player 1 already initialized."
            );
        }
        else {
            require(
                (p2FleetHash != 0 && p2StateHash != 0 && p2SaltHash != 0) == isInitialized,
                isInitialized ? "Player 2 not yet initialized" : "Player 2 already initialized."
            );
        }
        _;
    }

    // Adds the requirement that it is currently the parameter player's turn (to make a shot).
    modifier isPlayerTurn(bool isPlayer1) {
        if (isPlayer1) {
            require(turn == 0, "Player 1 must wait for their turn.");
        }
        else {
            require(turn == 2, "Player 2 must wait for their turn.");
        }
        _;
    }

    // Adds the requirement that it is currently the parameter player's turn (to process recieving a shot), and that there is a queued shot.
    modifier isRecieverTurn(bool isPlayer1) {
        if (isPlayer1) {
            require(turn == 3, "Player 1 cannot recieve a shot right now.");
        }
        else {
            require(turn == 1, "Player 2 cannot recieve a shot right now.");
        }
        require(shotPos != 0, "No shot queued for reciept.");
        _;
    }

    // Adds the requirement that the parameter player is providing hashes that match their prior commitments.
    modifier validCommitments(bool isPlayer1, uint[11] calldata hashes) {
        if (isPlayer1) {
            require(p1FleetHash == hashes[0], "Fleet hashes do not match.");
            require(p1StateHash == hashes[1], "State hashes do not match.");
            require(p1SaltHash == hashes[2], "Salt hashes do not match.");
        }
        else {
            require(p2FleetHash == hashes[0], "Fleet hashes do not match.");
            require(p2StateHash == hashes[1], "State hashes do not match.");
            require(p2SaltHash == hashes[2], "Salt hashes do not match.");
        }
        _;
    }

    // Adds the requirement that the game is over, and that the msg sender is the winner.
    modifier canWithdraw() {
        require(gameOver, "Game has not ended yet.");
        require(msg.sender == winner, "You are not the winner.");
        _;
    }

    // Lets p1 cancel the game and enable self withdrawls if no p2 has joined yet.
    function cancelGame() public gameNotOver() isPlayer(true) player2Joined(false) {
        gameOver = true;
        winner = player1;
    }

    // Allows another a new user to join the game as p2, if there isn't one yet.
    function joinAsPlayer2() public payable gameNotOver() player2Joined(false) {
        require (msg.value == buyIn, "You did not buy in to the prize pool with the correct amount.");
        player2 = msg.sender;
        player2HasJoined = true;
        // Initialize both timestamps at this point, as this is when both players need to start interacting
        mostRecentP1Timestamp = block.timestamp;
        mostRecentP2Timestamp = block.timestamp;
    }

    // If both players are present, either may forfeit the game and make their opponent the winner.
    function forfeit(bool iAmPlayer1) public gameNotOver() player2Joined(true) isPlayer(iAmPlayer1) {
        gameOver = true;
        winner = iAmPlayer1 ? player2 : player1;
    }

    // If a player has been inactive for at least a day, their opponent may force a timeout forfeit and claim the prize.
    function inactivityTimeout(bool iAmPlayer1) public gameNotOver() player2Joined(true) isPlayer(iAmPlayer1) playerTimedOut(!iAmPlayer1) {
        gameOver = true;
        winner = iAmPlayer1 ? player1 : player2;
    }

    // Initializes a player's board using the zk-proof parameters provided by generating a proof from the state_init circuit.
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

    // Processes a users move to fire a shot at their opponent's board, requiring that this is a valid and totally new target.
    function fireShot(bool iAmPlayer1, uint8 _shotPos) public
        gameNotOver() isPlayer(iAmPlayer1) playerBoardStatus(true, true) playerBoardStatus(false, true) isPlayerTurn(iAmPlayer1) {
            require(1 <= _shotPos && _shotPos <= 100, "Not a valid position to fire at.");
            if (iAmPlayer1) {
                require (p1ShotsHit[_shotPos] == 0);
            }
            else {
                require (p2ShotsHit[_shotPos] == 0);
            }
            shotPos = _shotPos;
            turn = (turn + 1) % 4;
    }

    // Private helper function gets whether a player's whole fleet is sunk.
    function playerIsSunk(bool isPlayer1) private view returns(bool) {
        if (isPlayer1) {
            return (p1IsSunk[0] && p1IsSunk[1] && p1IsSunk[2] && p1IsSunk[3] && p1IsSunk[4]);
        }
        else {
            return (p2IsSunk[0] && p2IsSunk[1] && p2IsSunk[2] && p2IsSunk[3] && p2IsSunk[4]);
        }
    }

    // Processes the reciept of the user's opponent's shot onto their board, using the zk-proof parameters provided by generating a proof from the state_process_move circuit.
    function recieveShot(
        bool iAmPlayer1,
        uint[2] calldata proof_a,
        uint[2][2] calldata proof_b,
        uint[2] calldata proof_c,
        uint[11] calldata proof_input
    ) public gameNotOver() isPlayer(iAmPlayer1) playerBoardStatus(true, true) playerBoardStatus(false, true)
        isRecieverTurn(iAmPlayer1) validCommitments(iAmPlayer1, proof_input) {
            require(moveVerif.verifyProof(proof_a, proof_b, proof_c, proof_input), "Process move proof invalid.");
            if (iAmPlayer1) {
                p1StateHash = proof_input[3];
                p2ShotsHit[shotPos] = uint8(proof_input[4]) + 10;
                for (uint8 i=0; i<5; i++) {
                    p1IsSunk[i] = (proof_input[i+5] == 1);
                }
            }
            else {
                p2StateHash = proof_input[3];
                p1ShotsHit[shotPos] = uint8(proof_input[4]) + 10;
                for (uint8 i=0; i<5; i++) {
                    p2IsSunk[i] = (proof_input[i+5] == 1);
                }
            }
            shotPos = 0;
            turn = (turn + 1) % 4;

            if (playerIsSunk(iAmPlayer1)) {
                gameOver = true;
                winner = iAmPlayer1 ? player2 : player1;
            }
    }

    // The winner can withdraw the whole prize pool balance to their wallet.
    function withdrawPrize() canWithdraw() public {
        payable(winner).transfer(address(this).balance);
    }

}