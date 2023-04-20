/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for complete board initialization with public verification of validity.
*/
pragma circom 2.1.5;

include "ConstructRBoard.circom";

template RHash() {

}

template Main {
    signal input secret;
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal input verifyBoard[10][10];
    signal output cHash;
    signal output rHash;

    signal board[10][10];
    (cHash, board) <== ConstructRaw()(secret, patrol, submarine, battleship, destroyer, carrier);
    board === verifyBoard;
    (_, _, _, _, _, _, _, rHash) <== HashRBoard()(secret, nullBasis, board);

}

component main = Main();