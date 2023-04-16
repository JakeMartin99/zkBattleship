pragma circom 2.0.5;

include "CheckBoardHash.circom";

template ValidateBoard() {
    signal input board[10][10];
    signal input userSecret;
    signal output boardHash;

    component CheckHash = CheckBoardHash();
    CheckHash.board = board;
    CheckHash.userSecret = userSecret;
    boardHash <== CheckHash.boardHash;
}

component main {public [boardMerkelRoot]} = CheckInitialBoard();