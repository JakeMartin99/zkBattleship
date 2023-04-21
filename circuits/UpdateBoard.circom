/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for complete board initialization with public verification of validity.
*/
pragma circom 2.1.5;

include "ConstructRBoard.circom";
include "Merkle.circom";

template Main {
    signal input secret;
    signal input x;
    signal input y;
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal input oldBoard[10][10];
    signal input verifycHash;
    signal input oldrHash;
    signal output rHash;

    (cHash, _) <== ConstructRaw()(secret, patrol, submarine, battleship, destroyer, carrier);
    cHash === verifycHash;
    (_, _, _, _, _, _, _, rHash) <== UpdateRBoard()(secret, nullBasis, oldBoard);

}

component main {public [cHash, oldrHash]} = Main();