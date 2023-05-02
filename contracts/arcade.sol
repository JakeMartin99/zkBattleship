/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Contract for deploying new game contracts, and finding a user's latest game.
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Game} from "./game.sol";

contract Arcade {

    // Mapping of user address to the most recent Game they created
    mapping(address => Game) public lookup;

    /*
    Creates a new Game contract with a buy in equal to the value passed in,
    and the user set to player 1. The Game is also added to the lookup.

    returns:
        The Game object (or its address, depending on the context).
    */
    function createNewGame() public payable returns(Game) {
        Game newGame = new Game{value: msg.value}(msg.sender);
        lookup[msg.sender] = newGame;
        return newGame;
    }
}