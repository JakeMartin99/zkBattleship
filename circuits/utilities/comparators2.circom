/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Utility templates for more advanced comparators.
*/
pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/gates.circom";

/*
    Adds a constraint that a signal must be binary.

    input signals:
        in: the signal to constrain
*/
template RequireBinary() {
    signal input in;
    
    // If in == 0: in*(in-1) = 0*(!0) = 0
    // If in == 1: in*(in-1) = !0*(0) = 0
    // If in > 1: in*(in-1) = !0*!(0) = !0
    in * (in-1) === 0;
}

/*
    Determines whether or not an input resides between a lower and upper boundary pair.

    parameters:
        lowerInclusive: 1 if the lower bound of the interval is inclusive, 0 if exclusive
        upperInclusive: 1 if the upper bound of the interval is inclusive, 0 if exclusive
        n: the number of bits to encode the values with, including sign bit
    input signals:
        lowerBound: the lower bound for the interval
        in: the signal to check against the interval
        upperBound: the upper bound for the interval
    output signals:
        out: 1 if the bounds are obeyed, 0 otherwise
*/
template InInterval(lowerInclusive, upperInclusive, n) {
    signal input lowerBound;
    signal input in;
    signal input upperBound;
    signal output out;

    // Require parameter validity
    assert(lowerInclusive == 0 || lowerInclusive == 1);
    assert(upperInclusive == 0 || upperInclusive == 1);

    // Binary for whether the lower bound is obeyed
    signal lowerGT;
    if (lowerInclusive) {
        lowerGT <== GreaterEqThan(n)([in, lowerBound]);
    }
    else {
        lowerGT <== GreaterThan(n)([in, lowerBound]);
    }

    // Binary for whether the upper bound is obeyed
    signal upperLT;
    if (upperInclusive) {
        upperLT <== LessEqThan(n)([in, upperBound]);
    }
    else {
        upperLT <== LessThan(n)([in, upperBound]);
    }
    
    // Combined condition
    RequireBinary()(lowerGT);
    RequireBinary()(upperLT);
    out <== AND()(lowerGT, upperLT);
}

/*
    Adds a constraint that two signal arrays must have no element overlap.

    parameters:
        len1, len2: the lengths of the input arrays 
    input signals:
        arr1, arr2: the arrays to be compared
*/
template Requrie2DontOverlap(len1, len2) {
    signal input arr1[len1];
    signal input arr2[len2];

    component Eqs[len1][len2];
    for (var i=0; i<len1; i++) {
        for (var j=0; j<len2; j++) {
            Eqs[i][j] = parallel IsEqual();
            Eqs[i][j].in <== [arr1[i], arr2[j]];
            Eqs[i][j].out === 0;
        }
    }
}