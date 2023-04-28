/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Templates for state management.
*/
pragma circom 2.1.5;

include "./utilities/comparators2.circom";

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";

/*
    Hashes a fleet using 220-round 17-to-1 MiMCSponge, used for commiting to fleet placement.

    input signals:
        fleet: a flattened list of fleet position codes
        secret: a random number that pseudo-randomizes the hash function
    output signal:
        out: the resulting hashed value
*/
template HashFleet() {
    signal input fleet[17];
    signal input secret;
    signal output out;

    signal hashed[1] <== MiMCSponge(17, 220, 1)(fleet, secret);
    out <== hashed[0];
}

/*
    Encodes the elements of the state and then hashes them using MiMCSponge, used for committing
    to game state.

    input signals:
        state: a list of binary values, indicating whether that index's ship position has been hit
        salt: a collection of random numbers which makes the state hash more secure
        secret: a random number that pseudo-randomizes the hash function
    output signals:
        out: the resulting hashed value
*/
template HashState() {
    signal input state[17];
    signal input salt[17];
    signal input secret;
    signal output out;

    // Encode the state vector by applying 220-round 2-to-1 MiMCSponge to the element and salt at each index
    signal hashes[17][1];
    signal encState[17];
    for (var i=0; i<17; i++) {
        hashes[i] <== MiMCSponge(2, 220, 1)([state[i], salt[i]], secret);
        encState[i] <== hashes[i][0];
    }

    // Hash the encoded state vector with 220-round 17-to-1 MiMCSpong
    signal hash[1] <== MiMCSponge(17, 220, 1)(encState, secret);
    out <== hash[0];
}

/*
    Validates an opponents move and processes it's effects on the game state.
    
    input signals:
        shotPos: the position code that the opponent's move is firing at
        fleet: all of the ships position codes in a single list
        state: a list of binary values, indicating whether that index's ship position has been hit
    output signals:
        newState: state, but updated to account for if shotPos got a successful hit
        wasAHit: binary for whether or not the shot hit a ship
*/
template ProcessMove() {
    signal input shotPos;
    signal input fleet[17];
    signal input state[17];
    signal output newState[17];
    signal output wasAHit;

    signal isShotLoc[17];
    for (var i=0; i<17; i++) {
        // Whether or not the shot hit the ship position at the current index
        isShotLoc[i] <== IsEqual()([shotPos, state[i]]);

        // If the shot was a hit here, update it from 0 to 1, or fail if it was already 1
        newState[i] <== state[i] + isShotLoc[i];
        RequireBinary()(newState[i]);
    }

    // Whether or not the shot hit anywhere, adds constraint that one shot cannot hit two spaces
    // (which shouldn't happen anyway, but just to be safe)
    wasAHit <== BinaryArrayCount(17)(isShotLoc);
    RequireBinary()(wasAHit);
}

/*
    Determines what ships are sunk in the provided game state.

    input signals:
        state: a list of binary values, indicating whether that index's ship position has been hit
    output signals:
        isSunk: a binary list for whether or not each of the 5 ships is sunk (post-move)
*/
template GetSunk() {
    signal input state[17];
    signal output isSunk[5];

    isSunk[0] <== AND()(state[0], state[1]);
    isSunk[1] <== MultiAND(3)([state[2], state[3], state[4]]);
    isSunk[2] <== MultiAND(3)([state[5], state[6], state[7]]);
    isSunk[3] <== MultiAND(4)([state[8], state[9], state[10], state[11]]);
    isSunk[4] <== MultiAND(5)([state[12], state[13], state[14], state[15], state[16]]);
}