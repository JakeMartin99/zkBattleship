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

Finally, the last section of the project is the two remaining contracts in `/contracts`, `arcade.sol` and `game.sol`. The arcade contract is what actually gets deployed, but it is incredibly simple and just provides a reusable interface for quickly generating new games. The game contract, though, is where everything comes together to actually facilitate gameplay.
