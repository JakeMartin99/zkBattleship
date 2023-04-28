/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuit for initializing the game state.
*/
pragma circom 2.1.5;

include "./place_ships.circom";
include "./state_mgmt.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";

/*
    Flattens a fleet into a single list of position codes.

    input signals:
        patrol_p: the patrol boat's collection of position codes
        submarine_p: the submarine's collection of position codes
        destroyer_p: the destroyer's collection of position codes
        battleship_p: the battleship's collection of position codes
        carrier_p: the aircraft carrier's collection of position codes
    output signals:
        out: all of the ships position codes in a single list, ordered as above
*/
template FlattenFleet() {
    signal input patrol_p[2];
    signal input submarine_p[3];
    signal input destroyer_p[3];
    signal input battleship_p[4];
    signal input carrier_p[5];
    signal output out[17];

    out[0] <== patrol_p[0];
    out[1] <== patrol_p[1];
    out[2] <== submarine_p[0];
    out[3] <== submarine_p[1];
    out[4] <== submarine_p[2];
    out[5] <== destroyer_p[0];
    out[6] <== destroyer_p[1];
    out[7] <== destroyer_p[2];
    out[8] <== battleship_p[0];
    out[9] <== battleship_p[1];
    out[10] <== battleship_p[2];
    out[11] <== battleship_p[3];
    out[12] <== carrier_p[0];
    out[13] <== carrier_p[1];
    out[14] <== carrier_p[2];
    out[15] <== carrier_p[3];
    out[16] <== carrier_p[4];
}

/*
    Main circuit for validating and then initializing a game from a set of ship placements.

    input signals:
        patrol: the patrol boat's ship tuple (x, y, dir)
        submarine: the submarine's ship tuple (x, y, dir)
        destroyer: the destroyer's ship tuple (x, y, dir)
        battleship: the battleship's ship tuple (x, y, dir)
        carrier: the aircraft carrier's ship tuple (x, y, dir)
        salt: a collection of random numbers which makes the state hash more secure
        secret: a random number that pseudo-randomizes the hash function
    output signals:
        fleetHash: the hash of the fleet that initialization commits to, as produced by HashFleet()
        stateHash: the hash of the game state to commit to, which is initially all zeros
            -[NOTE] the state itself is a list of binary values, corresponding to the flattened fleet,
                accepting 0 => has not been hit | 1 => has been hit
        saltHash: the hash of the salt that initialization commits to, as produced by HashFleet()
*/
template InitState() {
    signal input patrol[3];
    signal input submarine[3];
    signal input destroyer[3];
    signal input battleship[3];
    signal input carrier[3];
    signal input salt[17];
    signal input secret;
    signal output fleetHash;
    signal output stateHash;
    signal output saltHash;
    
    // Use the ship's tuples to generate a valid fleet placement
    signal (patrol_p[2], submarine_p[3], destroyer_p[3], battleship_p[4], carrier_p[5]) <==
        PlaceFleet()(patrol, submarine, destroyer, battleship, carrier);
    
    // Flatten the placed fleet and hash it
    signal flatFleet[17] <== FlattenFleet()(patrol_p, submarine_p, destroyer_p, battleship_p, carrier_p);
    fleetHash <== HashFleet()(flatFleet, secret);

    // Generate the initial no-hits-registered game state and hash it
    signal state[17];
    for (var i=0; i<17; i++) {
        state[i] <== 0;
    }
    stateHash <== HashState()(state, salt, secret);

    // Generate the salt hash to commit to
    saltHash <== HashFleet()(salt, secret);
}

component main = InitState();