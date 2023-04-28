/*
    Jake Martin
    2023
    CSCI 4240 Project
    zkBattleship

    Templates for validating an initial ship placement and creating a valid board with it.
*/
pragma circom 2.1.5;

include "./utilities/comparators2.circom";

/*
    Converts a ship's 2D coordinates into a uniquely identifying position code.

    input signals:
        x: the ship's top-left horizontal coordinate, in [1, 10]
        y: the ship's top-left vertical coordinate, in [1, 10]
    output signals:
        out: the position code p = x + 10(y-1), by definition in [1, 100]
*/
template CoordToPos() {
    signal input x;
    signal input y;
    signal output out;

    // Ensure both coordinates are on the board, i.e. in [1, 10]
    signal xValid <== InInterval(1, 1, 5)(1, x, 10);
    xValid === 1;
    signal yValid <== InInterval(1, 1, 5)(1, y, 10);
    yValid === 1;

    out <== x + 10*(y-1);
}

/*
    Converts a ship placement into a collection of its position codes,
    with the constraint that a single ship's placement keeps it entirely on the board.

    parameters:
        len: the length of the ship
    input signals:
        ship: the ship's tuple (x, y, dir)
            -x: the ship's top-left horizontal coordinate, in [1, 10]
            -y: the ship's top-left vertical coordinate, in [1, 10]
            -dir: the ship's orientation, 1 => horizontal | 0 => vertical
    output signals:
        positions: the ship's collection of position codes
*/
template PlaceShip(len) {
    signal input ship[3];
    signal output positions[len];

    // Require parameter validity
    assert(2 <= len && len <= 5);

    signal (x, y, dir) <== (ship[0], ship[1], ship[2]);

    // Ensure the direction is binary
    RequireBinary()(dir);

    // Perform validated conversion from (x,y) to position code for each coordinate on the ship
    for (var i=0; i<len; i++){
        positions[i] <== CoordToPos()(
            x + (dir)*i,
            y + (1-dir)*i
        );
    }
}

/*
    Converts a ship fleet of placements into a ship fleet of position code collections,
    while also validating that the inputs lead to a valid board construction.
    
    input signals:
        patrol: the patrol boat's ship tuple (x, y, dir)
        submarine: the submarine's ship tuple (x, y, dir)
        destroyer: the destroyer's ship tuple (x, y, dir)
        battleship: the battleship's ship tuple (x, y, dir)
        carrier: the aircraft carrier's ship tuple (x, y, dir)
    output signals:
        patrol_p: the patrol boat's collection of position codes
        submarine_p: the submarine's collection of position codes
        destroyer_p: the destroyer's collection of position codes
        battleship_p: the battleship's collection of position codes
        carrier_p: the aircraft carrier's collection of position codes
*/
template PlaceFleet() {
    signal input patrol[3];
    signal input submarine[3];
    signal input destroyer[3];
    signal input battleship[3];
    signal input carrier[3];
    signal output patrol_p[2];
    signal output submarine_p[3];
    signal output destroyer_p[3];
    signal output battleship_p[4];
    signal output carrier_p[5];

    // Perform validated placement of each ship
    patrol_p <== PlaceShip(2)(patrol);
    submarine_p <== PlaceShip(3)(submarine);
    destroyer_p <== PlaceShip(3)(destroyer);
    battleship_p <== PlaceShip(4)(battleship);
    carrier_p <== PlaceShip(5)(carrier);

    // Require that the patrol boat doesn't overlap the other ships
    Requrie2DontOverlap(2, 3)(patrol_p, submarine_p);
    Requrie2DontOverlap(2, 3)(patrol_p, destroyer_p);
    Requrie2DontOverlap(2, 4)(patrol_p, battleship_p);
    Requrie2DontOverlap(2, 5)(patrol_p, carrier_p);

    // Require that the submarine doesn't overlap the other ships
    Requrie2DontOverlap(3, 3)(submarine_p, destroyer_p);
    Requrie2DontOverlap(3, 4)(submarine_p, battleship_p);
    Requrie2DontOverlap(3, 5)(submarine_p, carrier_p);

    // Require that the destroyer doesn't overlap the other ships
    Requrie2DontOverlap(3, 4)(destroyer_p, battleship_p);
    Requrie2DontOverlap(3, 5)(destroyer_p, carrier_p);

    // Require that the battleship doesn't overlap the other ships
    Requrie2DontOverlap(4, 5)(battleship_p, carrier_p);
}