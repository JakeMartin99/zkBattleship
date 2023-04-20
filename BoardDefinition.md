# Mathematical Definition of a Game Board

## Raw Board

The board is a 10 x 10 positive integer array, `int board[10][10];`
There are a series of integer codes that can be placed into the array, subject to constraints, which encode the placement of ships and where shots have been fired.

-   In general there are two subclasses of space, `REVEALED` and `HIDDEN`, where the former corresponds to spaces that has been shot at and thereby revealed, and the latter corresponds to unexplored spaces. The class `HIDDEN` is assigned a ones-place code of `0`, while `HIT` is assigned a ones-place code of `1`. At the start of gameplay, all spaces should be `HIDDEN`, and on each turn from the opponent they convert 1 space to `HIT`.
-   There are then 6 overarching classes of space which define the occupation status of a space, which are given tens-place codes as follows, and which will never be modified during play:
    -   `EMPTY` => 0: An empty space belonging to no ship.
    -   `PATROL` => 1: An occupied space belonging to the 2-long Patrol Boat.
    -   `SUBMARINE` => 2: An occupied space belonging to the 3-long Submarine.
    -   `BATTLESHIP` => 3: An occupied space belonging to the 3-long Battleship.
    -   `DESTROYER` => 4: An occupied space belonging to the 4-long Destroyer.
    -   `CARRIER` => 5: An occupied space belonging to the 5-long Aircraft Carrier.
-   There are also obvious coherence constraints on the adjacency and quantities of the 6 classes in order for a board to be valid. In particular, the following must hold:
    -   All spaces must have one of the above valid codes. An initial state or state transition that yields a board with any other kind of code should not be accepted.
    -   There must be exactly `len(ship)` spaces with `ship`'s code.
    -   Those `len(ship)` spaces must be along a single contiguous, unbroken line that fits entirely on the 2D board, and is either vertical or horizontal.
    -   Ships cannot "overlap" by having any space correspond to `>1` code.
    -   All remaining non-ship spaces must be valid empty spaces.
-   Given these constraints, it is sometimes helpful to think of the board in terms of an alternate scheme...

## Constructor Board

In order to prove that a 10x10 raw board was constructed correctly, it can be helpful to start from a simpler scheme, and prove that the 10x10 board was generated from it. In particular, while the 10x10 format is beneficial for enforcing the non-overlapping condition, and for modeling how to change the game state throughout gameplay, it is tedious for verifying that the initial setup corresponds to the other conditions for ship placement. As such, we will instead start with a hyper-simple construction:

-   Each of the 5 ship types will get 3 free parameters: horizontol position (`int x;`), vertical position (`int y;`), and direction (`bool dir;`), in addition to a preset parameter for the length of each (`int len;`). This may sometimes be encoded as 5 lists of 3, 1 for each ship, using order `x` -> `y` -> `dir`.
    -   `x` and `y` describe the coordinate position of the upper-left-most corner of the given ship on the 10x10 grid. As such, they will subject to the constraint that they are both `>=0` and `<10`.
    -   `dir` describes whether or not the ship is aligned horizontally (`false` or `0`) or vertically (`true` or `1`). While only directly subjected to the constraint that it be a valid boolean, it also imposes a restriction on either `x` or `y` in order to prevent overflow off the edge of the board, as follows:

```python
if (dir==0):
    assert(x < 10 - len)
else:
    assert(y < 10 - len)
```

-   Using this scheme is beneficial because it is extremely compact and therefore easy to specify a board with, and generally by construction prevents the construction of boards that are invalid due to including non-existent, incorrect-length, incorrectly-placed, or duplicate ships. Really the only check that is hard to do at this stage is for overlapping, but that can be done during conversion to the final 10x10 raw board.
    -   In order to perform construction, we initialize every space on the 10x10 to `00` for an unhit empty space, and then simply go through each of the ship tuples one-by-one and update `len(ship)` spaces to the ship's `n0` unhit space code based on the coordinate and direction specified. We must also ensure that overlapping did not happen by checking for overwrites during this process (as any overlap would result in a ship having its space overwritten).
-   This scheme has an added utility in that it can be used to quickly generate the spaces to investigate on the 10x10 in order to determine whether or not a ship-hit results in that ship sinking.

## Hashed Boards

Both board types need to have a hashed representation that can be committed to, in order to make zk-proofs useful and meaningful in this context. In general, the `MiMCSponge` function provided by [circomlib](https://github.com/iden3/circomlib/blob/master/circuits/mimcsponge.circom) is used for hashing boards as it is a lightweight hash function optimized for zk-related usage.

-   For the constructor board, this can be a simple hashing function, as no updates need to be managed as the locations and directions of ships never changes. As such, the scheme to be used is simply `MiMCSponge` with `1` output from `15=5*3` inputs (each of the 5 ships has a tuple of 3 free parameters). The canonical input ordering shall be to group by ship, with the order of ships being patrol -> submarine -> battleship -> destroyer -> carrier, and within each ship grouping the order of parameters is `x` -> `y` -> `dir`.
-   For the raw 10x10 board, we need to be able to perform updates and correspondingly change the hash with every single move. As such, the scheme to be used is a Merkle Tree built upon binary combinations of `MiMCSponge` with `1` output from `2` inputs. Since we need to construct the binary tree, we will start by flattening the the 10x10 board into a 100-length list (by going row by row and appending). Then, to make it a power of 2 to construct a full binary tree from, we append 28 `0` elements. This then enables us to construct a `8=log(128)+1` deep Merkle Tree, for which the root level hash can be committed to. However, if the intermediate pieces are retained locally, then updating the hash when a single element changes becomes much more efficient.
