/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for private, local usage to turn a C-Board into an R-Board with useful extra outputs.
*/
pragma circom 2.1.5;

include "ConstructRBoard.circom";
include "Merkle.circom";

// Pass through template for ConstructRaw
template Main() {
    signal input secret;
    signal input nullBasis;
    signal input patrol[3];
    signal input submarine[3];
    signal input battleship[3];
    signal input destroyer[3];
    signal input carrier[3];
    signal output board[10][10];
    signal output cHash;
    signal output layer7[128];
    signal output layer6[64];
    signal output layer5[32];
    signal output layer4[16];
    signal output layer3[8];
    signal output layer2[4];
    signal output layer1[2];
    signal output rHash;

    (cHash, board) <== ConstructRaw()(secret, patrol, submarine, battleship, destroyer, carrier);
    (layer7, layer6, layer5, layer4, layer3, layer2, layer1, rHash) <== HashRBoard()(secret, nullBasis, board);
}

component main = Main();