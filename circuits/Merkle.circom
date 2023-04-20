/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for managing R-Board Merkle Trees.
*/
pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

// Hashes a left and right component together using 2-to-1 MiMCSponge
template HashLR() {
    signal input secret;
    signal input l;
    signal input r;
    signal output hash;

    signal hashed[1] <== MiMCSponge(2, 220, 1)([l, r], secret);
    
    hash <== hashed[0];
}

// Hashes a list of elements into a Merkle Tree using HashLR
template HashList() {
    signal input secret;
    signal input list[128];
    signal output layer7[128];
    signal output layer6[64];
    signal output layer5[32];
    signal output layer4[16];
    signal output layer3[8];
    signal output layer2[4];
    signal output layer1[2];
    signal output root;

    signal hashed[128][1];
    for (var i=0; i<128; i++) {
        hashed[i] <== MiMCSponge(1, 220, 1)([list[i]], secret);
        layer7[i] <== hashed[i][0];
    }
    for (var i=0; i<64; i++) {
        layer6[i] <== HashLR()(secret, layer7[2*i], layer7[2*i+1]); 
    }
    for (var i=0; i<32; i++) {
        layer5[i] <== HashLR()(secret, layer6[2*i], layer6[2*i+1]); 
    }
    for (var i=0; i<16; i++) {
        layer4[i] <== HashLR()(secret, layer5[2*i], layer5[2*i+1]); 
    }
    for (var i=0; i<8; i++) {
        layer3[i] <== HashLR()(secret, layer4[2*i], layer4[2*i+1]); 
    }
    for (var i=0; i<4; i++) {
        layer2[i] <== HashLR()(secret, layer3[2*i], layer3[2*i+1]); 
    }
    for (var i=0; i<2; i++) {
        layer1[i] <== HashLR()(secret, layer2[2*i], layer2[2*i+1]); 
    }
    root <== HashLR()(secret, layer1[0], layer1[1]); 
}

// Flattens an R-Board into a list of length 128 = 2^7
template RFlatten() {
    signal input nullBasis;
    signal input board[10][10];
    signal output list[128];

    for (var k=0; k<10; k++) {
        for (var h=0; h<10; h++) {
            list[10*k + h] <== board[k][h];
        }
    }
    for (var i=100; i<128; i++) {
        list[i] <== nullBasis;
    }
}

// Combines the other templates to hashes an R-Board from start to finish
template HashRBoard() {
    signal input secret;
    signal input nullBasis;
    signal input board[10][10];
    signal output layer7[128];
    signal output layer6[64];
    signal output layer5[32];
    signal output layer4[16];
    signal output layer3[8];
    signal output layer2[4];
    signal output layer1[2];
    signal output root;

    signal list[128] <== RFlatten()(nullBasis, board);
    (layer7, layer6, layer5, layer4, layer3, layer2, layer1, root) <== HashList()(secret, list); 
}