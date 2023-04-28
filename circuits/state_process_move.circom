/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuit for processing a move and updating the game state.
*/
pragma circom 2.1.5;

include "./state_mgmt.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";

/*
    Main circuit for validating and then processing a game state update.

    input signals:
    (public)
        fleetHash: the hash of the fleet that was committed to
        stateHash: the hash of the most recent game state which was committed to
        saltHash: the hash of the salt that was committed to
        shotPos: the position code that the opponent's move is firing at
    (private)
        fleet: all of the ships position codes in a single list
        state: a list of binary values, indicating whether that index's ship position has been hit
        salt: a collection of random numbers which makes the state hash more secure
        secret: a random number that pseudo-randomizes the hash function
    output signals:
        newStateHash: the hash of the new, post-move game state to commit to
        wasAHit: binary for whether or not the shot hit a ship
        isSunk: a binary list for whether or not each of the 5 ships is sunk (post-move)
            -[NOTE] the order is the same as everywhere else, small to large ships
*/
template UpdateState() {
    signal input fleetHash;
    signal input stateHash;
    signal input saltHash;
    signal input shotPos;

    signal input fleet[17];
    signal input state[17];
    signal input salt[17];
    signal input secret;

    signal output newStateHash;
    signal output wasAHit;
    signal output isSunk[5];
    
    // Ensure that the fleet being used matches the public commitment
    signal HFleet <== HashFleet()(fleet, secret);
    fleetHash === HFleet;

    // Ensure that the state being used matches the public commitment
    signal HState <== HashState()(state, salt, secret);
    stateHash === HState;

    // Ensure that the salt being used matches the public commitment
    signal HSalt <== HashFleet()(salt, secret);
    saltHash === HSalt;

    // Validate the move, and get the new state hash and whether the move was a hit
    signal (newState[17], hit) <== ProcessMove()(shotPos, fleet, state);
    newStateHash <== HashState()(state, salt, secret);
    wasAHit <== hit;

    // Get the current sunk-status for all of the ships
    isSunk <== GetSunk()(newState);
}

component main {public [fleetHash, stateHash, saltHash, shotPos]} = UpdateState();