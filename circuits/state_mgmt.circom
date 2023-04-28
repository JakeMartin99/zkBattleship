/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Templates for state management.
*/
pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

/*
    Encodes the state vector by applying 220-round 2-to-1 MiMCSponge to the element and salt at each index.

    input signals:
        state: a list of binary values, indicating whether that index's ship position has been hit
        salt: a collection of random numbers which makes the state hash more secure
        secret: a random number that pseudo-randomizes the hash function
    output signals:
        out: the encoded state vector
*/
template EncodeState() {
    signal input state[17];
    signal input salt[17];
    signal input secret;
    signal output out[17];

    signal hashes[17][1];
    for (var i=0; i<17; i++) {
        hashes[i] <== MiMCSponge(2, 220, 1)([state[i], salt[i]], secret);
        out[i] <== hashes[i][0];
    }
}

/*
    Hashes the encoded state vector wotj 220-round 17-to-1 MiMCSpong.

    input signals:
        encState: the encoded state vector, such as is produced by EncodeState()
        secret: a random number that pseudo-randomizes the hash function
    output signals:
        out: the resulting hashed value
*/
template HashEncodedState() {
    signal input encState[17];
    signal input secret;
    signal output out;

    signal hash[1] <== MiMCSponge(17, 220, 1)(encState, secret);
    out <== hash[0];
}

/*
    Combines EncodeState() and HashEncodedState() to compute the state hash from start to finish

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

    signal encState[17] <== EncodeState()(state, salt, secret);

    out <== HashEncodedState()(encState, secret);
}