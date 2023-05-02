# zkBattleship

Zero-knowledge Ethereum-based Battleship game proof-of-concept

Running everything from scratch requires:

-   Having [Circom 2 installed on your machine](https://docs.circom.io/getting-started/installation/)
-   Running `npm install` in this repository, all credit to iden3 for the ZK primitives from [circomlib](https://github.com/iden3/circomlib) and for the [snarkjs](https://github.com/iden3/snarkjs) tooling.

The arcade contract is currently located on the Goerli testnet at [0xA4317660f19210707fB39595b872500B1476AFa0](https://goerli.etherscan.io/address/0xa4317660f19210707fb39595b872500b1476afa0), and can be called by anyone to generate a new game contract.

To generate the correct parameters for an initialize board call, perform the following steps:

1. Following the template in `init.json`, define your input ship placements and auxilary initialization parameters.
2. Run the command `snarkjs groth16 fullprove init.json circuits/compiled/state_init/state_init_js/state_init.wasm circuits/trusted_setup/phase_2/state_init/init_beacon.zkey init_proof.json init_public.json` to generate the zk proof.
3. Run the command `snarkjs zkey export soliditycalldata init_public.json init_proof.json` and copy each of the outputted lists into the appropriate parameter in your smart-contract-calling tool (I do it directly in remix ide, with all of the contracts in this repo uploaded so that it knows the functions' formats)

A similar pattern would follow for an process move call.

## Project Structure

The first section of the project is the circom circuits, located in `/circuits`. While separated into 4 files (+1 for utilities) for logical separation, they fundamentally boil down to 2 main circuits: `InitState()` and `UpdateState()`.

-   `InitState()`: This is all about proving in a zero knowledge manner that you have information that defines a Battleship board placement, that such placement is valid given the definition of the game (10x10 board, no ships overlap, ships are either vertical or horizontal, ships must be entirely on the board), and then commiting to hashes that characterize that placement, such that you will have to abide by it for the rest of this game.
-   `UpdateState()`: This is all about responding to your opponents shot at your board, by proving whether or not it was a hit or a miss, and updating your internal, committed-to state in a provably correct manner such that the sunken status of all 5 ships can also be proven, but in a zero knowledge manner such that no space is revealed to be occupied or empty unless fired at, and no information about any ship as a whole is revealed until it is sunk.

Then, each of these were compiled into usable constraint systems, as stored in `/circuits/compiled`, and then I manually performed the `groth16` trusted setup ceremony to generate the verification key for each, as in `/circuits/trusted_setup`. While this is a limitation as it reduces trustlessness (you would have to trust that I did the process correctly and destroyed the "toxic waste"), this use case has little financial implications, and as a testnet demo has none, so I feel that I was justified in doing that in order to expedite the process.

Then, to conclude the zk portion of the project, all of the pieces up to this point could be used with `snarkjs` to automatically generate proof-validating solidity code for both circuits, which are `/contracts/init_verifier.sol` and `/contracts/move_verifier.sol`.

Finally, the last section of the project is the two remaining contracts in `/contracts`, `arcade.sol` and `game.sol`. The arcade contract is what actually gets deployed, but it is incredibly simple and just provides a reusable interface for quickly generating new games. The game contract, though, is where everything comes together to actually facilitate gameplay. It manages the order of turns (both for firing and responding to the opponet's shot), recieving and paying out the prize pool, handling forfeit/inactivity-based abnormal end-conditions, and validating both the inital game setup and each state transition with the zk circuits defined previously.

## Limitations

In addition to the trusted ceremony being 100% centralized with me, there are a few other limitations worth pointing out. At the moment, the front end UX is horrendous, as one has to manually interact with the smart contracts and generate the zk proofs in order to play a game. I think a key priority, should I continue iterating on this project in the future, would be to first get a basic command-line cli working that could handle the smart contract interactions and zk proof generation complexity a bit more seemlessly, and after that eventually integrate it into a basic website that could use Metamask, etc. to handle user-blockchain interactions and totally hide all of the zk-stuff going on in the background. Another current limitation is that this code has not been tested extensively. I am fairly confident that everything up through both players proving their initial boards to the smart contract works right, but I am much less so about the game-state-updating parts. I will say that actually getting the hang of circom, and operating in the zk-circuit-programming realm with all of the restrictions it places on you took a fair bit longer than I was expecting, and so while I have learned a lot in getting my hands dirty with zk to the extent I now have, the other aspects of my projects definitely didn't get quite as far along as I would've hoped.

## Definitions

### What is a board?

As per the game of Battleship, the board is a 10x10 grid of spaces, however for simplicity (and zk type restrictions) I generally refer to both directions as going from 1-10, rather than having one be A-J. Additionally, in many contexts a "position code" is used instead. These codes just map each square on the board with a number from 1-100, starting with 1 in the top-left and counting up as you move left to right, and then top to bottom.

### What are the ships?

As per the version of Battleship I'm most familiar with, there are 5 ships, each of which have the corresponding lengths (number of board spaces they occupy):

-   Patrol Boat [2]
-   Submarine [3]
-   Destroyer [3]
-   Battleship [4]
-   Carrier [5]

### What is a ship placement?

I determined that the simplest way to define an inital placement of ships would be to enumerate each ship's upper-left-most coordinate position, and it's direction as either horizontal or vertical. I made this choice because it allows all unique ship placements, while also restricting "for free" many of the requirements that the game imposes, such as ships having to be either horizontal or vertical, and ships having to occupy contiguous spaces. With this format, it is also fairly easy to check that no part of the ship is "hanging off" the edge of the board. However, as this format is not conducive to ensuring that no ships overlap, nor actually registering ship hits vs. misses, after being validate as good as it can this format is converted into the fleet format, which is validated against those last tricky issues and used going forward.

### What is a fleet?

A fleet is the derived description of ship placements that is used for ensuring no-overlaps, and for determining how a move should be processed. It simply gives each ship a list of position codes as long as it's ship length, so that each position the ship occupies is directly enumerated. Sometimes this is also flattened into a single list of length 17, which just concatenates the ships together in the order shown above.
