/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Circuits for managing R-Board Merkle Trees.
*/
pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/gates.circom";
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

// Copies a list with the element at 1 index altered
template replaceOne(n) {
    signal input lst[n];
    signal input ind;
    signal input val;
    signal output out[n];

    component eqs[n];
    for (val i=0; i<n; i++) {
        eqs[i] = IsEqual();
        eqs[i].in[0] <== i;
        eqs[i].in[1] <== ind;
        out[i] <== (eqs[i].out)*(val) + (1 - eqs[i].out)*(lst[i]);
    }
}

// Combines the other templates to efficiently update an R-Board with a single entry change
template UpdateRBoard() {
    signal input secret;
    signal input x;
    signal input y;
    signal input val;
    signal input oldval;
    signal input oldlayer7[128];
    signal input oldlayer6[64];
    signal input oldlayer5[32];
    signal input oldlayer4[16];
    signal input oldlayer3[8];
    signal input oldlayer2[4];
    signal input oldlayer1[2];
    signal input oldroot;
    signal output layer7[128];
    signal output layer6[64];
    signal output layer5[32];
    signal output layer4[16];
    signal output layer3[8];
    signal output layer2[4];
    signal output layer1[2];
    signal output root;

    signal ind7 <== 10*y + x
    component hashed[1] <== MiMCSponge(1, 220, 1)([val], secret);
    layer7[ind7] <== replaceOne(128)(oldlayer7, ind7, hashed[0]);
    signal ind6 <== ind7 \ 2;
    layer6[ind6] <== replaceOne(64)(oldlayer6, ind6, HashLR()(secret, layer7[2*ind6], layer7[2*ind6+1])); 
    oldlayer6[ind6] === HashLR()(secret, oldlayer7[2*ind6], oldlayer7[2*ind6+1]);
    signal ind5 <== ind6 \ 2;
    layer5[ind5] <== replaceOne(32)(oldlayer5, ind5, HashLR()(secret, layer6[2*ind5], layer6[2*ind5+1]));
    oldlayer5[ind5] === HashLR()(secret, oldlayer6[2*ind5], oldlayer6[2*ind5+1]);
    signal ind4 <== ind5 \ 2;
    layer4[ind4] <== replaceOne(16)(oldlayer4, ind4, HashLR()(secret, layer5[2*ind4], layer5[2*ind4+1])); 
    oldlayer4[ind4] === HashLR()(secret, oldlayer5[2*ind4], oldlayer5[2*ind4+1]);
    signal ind3 <== ind4 \ 2;
    layer3[ind3] <== replaceOne(8)(oldlayer3, ind3, HashLR()(secret, layer4[2*ind3], layer4[2*ind3+1])); 
    oldlayer3[ind3] === HashLR()(secret, oldlayer4[2*ind3], oldlayer4[2*ind3+1]);
    signal ind2 <== ind3 \ 2;
    layer2[ind2] <== replaceOne(4)(oldlayer2, ind2, HashLR()(secret, layer3[2*ind2], layer3[2*ind2+1]));
    oldlayer2[ind2] === HashLR()(secret, oldlayer3[2*ind2], oldlayer3[2*ind2+1]);
    signal ind1 <== ind2 \ 2;
    layer1[ind1] <== replaceOne(2)(oldlayer1, ind1, HashLR()(secret, layer2[2*ind1], layer2[2*ind1+1]));
    oldlayer1[ind1] === HashLR()(secret, oldlayer2[2*ind1], oldlayer2[2*ind1+1])
    root <== HashLR()(secret, layer1[0], layer1[1]); 
    oldroot === HashLR()(secret, oldlayer1[0], oldlayer1[1])
}