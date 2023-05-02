// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {Game} from "./game.sol";

contract Arcade {

    mapping(address => Game) public lookup;

    function createNewGame() public payable returns(Game) {
        Game newGame = new Game{value: msg.value}(msg.sender);
        lookup[msg.sender] = newGame;
        return newGame;
    }
}