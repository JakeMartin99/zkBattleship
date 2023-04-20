/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for hashing and validating a C-Board (constructor board).
    Does NOT on its own check if ships overlap, but otherwise prevents incorrect boards.
*/
pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";

// Flattens a collection of ships' attributes (x, y, dir) into a single list
template CFlatten() {
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal output list[15];

    list[0] <== patrol[0];
    list[1] <== patrol[1];
    list[2] <== patrol[2];
    list[3] <== submarine[0];
    list[4] <== submarine[1];
    list[5] <== submarine[2];
    list[6] <== battleship[0];
    list[7] <== battleship[1];
    list[8] <== battleship[2];
    list[9] <== destroyer[0];
    list[10] <== destroyer[1];
    list[11] <== destroyer[2];
    list[12] <== carrier[0];
    list[13] <== carrier[1];
    list[14] <== carrier[2];
}

// Hashes a collection of ships using 15-to-1 MiMCSponge
template CHash() {
    signal input secret;
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal output hash;

    signal flat[15] <== CFlatten()(patrol, submarine, battleship, destroyer, carrier);
    signal hashed[1] <== MiMCSponge(15, 220, 1)(flat, secret);

    hash <== hashed[0];
}

// Checks if a ship's placement is valid (valid direction choice, and all coordinates on-the-board)
template CCheckShip(len) {
    signal input x;
    signal input y;
    signal input dir;
    
    // Ensure dir is binary
    dir * (dir-1) === 0;

    // Ensure top/left-most coordinate of ship is in-bounds
    signal gx <== GreaterEqThan(5)([x, 0]);
    gx === 1;
    signal gy <== GreaterEqThan(5)([y, 0]);
    gy === 1;
    // Ensure bottom/right-most coordinate of ship is in-bounds
    signal lx <== LessThan(5)([x, 10 - (dir-1)*len]);
    lx === 1;
    signal ly <== LessThan(5)([y, 10 - (dir)*len]);
    ly === 1;
}

// Combines the other templates to both hash a ship collection and validate each ship's placement
template CCheckAll() {
    signal input secret;
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal output hash;

    hash <== CHash()(secret, patrol, submarine, battleship, destroyer, carrier);

    CCheckShip(2)(patrol[0], patrol[1], patrol[2]);
    CCheckShip(3)(submarine[0], submarine[1], submarine[2]);
    CCheckShip(3)(battleship[0], battleship[1], battleship[2]);
    CCheckShip(4)(destroyer[0], destroyer[1], destroyer[2]);
    CCheckShip(5)(carrier[0], carrier[1], carrier[2]);
}