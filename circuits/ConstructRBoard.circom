/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for constructing and validating an R-Board (raw board).
    Completely prevents invalid board construction.
*/
pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/gates.circom";

include "CheckCBoard.circom";

// Helper template to compute (a || b || ... || n) using !(!a && !b && ... && !n)
template MultiOR(n) {
    signal input in[n];
    signal output out;
    
    signal notIns[n];
    for (var i=0; i<n; i++) {
        notIns[i] <== 1 - in[i];
    }
    signal ands <== MultiAND(n)(notIns);
    out <== 1 - ands;
}

// Adds a ship to a raw board, validating that is not overwriting any ship spaces (thereby preventing overlaps)
template AddShip(len, code) {
    signal input x;
    signal input y;
    signal input dir;
    signal input oldBoard[10][10];
    signal output newBoard[10][10];

    // Ensure dir is binary
    dir * (dir-1) === 0;

    component xEqs[10][10][len];
    component yEqs[10][10][len];
    signal isCoord[10][10][len];
    signal useCoord[10][10];
    for (var k=0; k<10; k++) {
        for (var h=0; h<10; h++) {
            for (var i=0; i<len; i++){
                xEqs[k][h][i] = IsEqual();
                xEqs[k][h][i].in[0] <== x + (dir)*i;
                xEqs[k][h][i].in[1] <== h;
                yEqs[k][h][i] = IsEqual();
                yEqs[k][h][i].in[0] <== y + (1 - dir)*i;
                yEqs[k][h][i].in[1] <== k;
                // Whether or not this coordinate of the ship is at the current location
                isCoord[k][h][i] <== AND()(xEqs[k][h][i].out, yEqs[k][h][i].out);
            }
            // Whether or not any coordinate of the ship at the current location
            useCoord[k][h] <== MultiOR(len)(isCoord[k][h]);
            // Ensure that either the ship is not at this coordinate or the board is empty here (preventing overlaps)
            useCoord[k][h] * oldBoard[k][h] === 0;
            // Place either the original board value, or if applicable the ship's code, at the current location
            newBoard[k][h] <== (1 - useCoord[k][h])*oldBoard[k][h] + (useCoord[k][h])*code;
        }
    }
}

// Validates a C-Board and provides its hash, then converts it into an R-Board and finishes validation. The R-Board is returned
template ConstructRaw() {
    signal input secret;
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal output cHash;
    signal output board[10][10];

    cHash <== CCheckAll()(secret, patrol, submarine, battleship, destroyer, carrier);

    signal initBoard[10][10];
    for (var i=0; i<10; i++) {
        for (var j=0; j<10; j++) {
            initBoard[i][j] <== 0;
        }
    }
    signal board1[10][10] <== AddShip(2, 10)(patrol[0], patrol[1], patrol[2], initBoard);
    signal board2[10][10]  <== AddShip(3, 20)(submarine[0], submarine[1], submarine[2], board1);
    signal board3[10][10]  <== AddShip(3, 30)(battleship[0], battleship[1], battleship[2], board2);
    signal board4[10][10]  <== AddShip(4, 40)(destroyer[0], destroyer[1], destroyer[2], board3);
    board <== AddShip(5, 50)(carrier[0], carrier[1], carrier[2], board4);
}