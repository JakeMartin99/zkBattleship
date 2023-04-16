pragma circom 2.0.5;

include "node_modules/circomlib/circuits/mimicsponge.circom";

template ValidateBoard() {
    signal input board[10][10];
    signal input userSecret;
    signal output boardHash;
    
    component boardHasher = MiMCSponge(100, 220, 1);
    hasher.k = userSecret;

    for (var i=0; i<10; i++) {
        for (var j=0; j<10; j++) {
            hasher.ins[10*i + j] = board[i][j];
        }
    }
    boardHash <== boardHasher.outs[0]
}

component main {public [boardMerkelRoot]} = ValidateBoard();