# milady-zk-swap

A silly escrow swap example contract which verifies a proof before a swap can be accepted. The circuit used for generating the witness is made in Circom.

THIS CODE HAS NOT BEEN AUDITED AND SHOULD NOT BE USED IN PRODUCTION. USE AT YOUR OWN RISK.

## Setup

This project is made using Foundry. Therefore, make sure you have it installed:

`curl -L https://foundry.paradigm.xyz | bash`

You will also need the Circom compiler. Follow the [Circom guide](https://docs.circom.io/getting-started/installation/) to install it, as you'll need to build the compiler from source, and also install the additional packages for generating proofs.

## Testing out Milady ZK Swap

Run `forge t -vvvv` to run the test. This deploys a milady mock token, ZK Verifier contract and the swapper itself to foundry's in-memory test runner, and runs an example exchange. Due to `-vvvv` you'll be able to see the traces and how the verifier contract works in terms of low level calls.

Here are the instructions for generating all the Circom-related files from scratch:

### Generating the proof

First, compile the circuit using the following command:

`circom multiplier2.circom --r1cs --wasm --sym --c --output ./circom-out`

This will generate the `R1CS` constraint system in binary format, and the `wasm` code necessary to create the witness. It will also produce some extra files, but we won't need them. To generate the witness, we'll use this command:

`node generate_witness.js MiladyHash.wasm ../../circuits/input.json witness.wtns`

This will modify the `witness.wtns` file with a snark.js compatible format.

After this, we'll proceed to use the `GROTH16` ZK-SNARK protocol to generate a proof and a verifier for our input. This is a multistep process, so make sure you don't make a mistake with the inputs. Starting from the same folder as before, first, we need to generate the Powers of Tau. Start by using this command:

`snarkjs powersoftau new bn128 12 pot12_0000.ptau -v`

Now we can contribute to the ceremony, by using this command:

`snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v`

Now we're done with phase 1 of the ceremony. We can go to phase 2, which deals with our specific circuit:

`snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v`

After this, we'll generate a `.zkey` file: It will contain both proving and verification keys together. We're almost there!

`snarkjs groth16 setup ../MiladyHash.r1cs pot12_final.ptau miladyhash.zkey`

Now, we can contribute to phase 2 of the ceremony:

`snarkjs zkey contribute miladyhash.zkey miladyhash_01.zkey --name="milady" -v`

Finally, we'll export the verification key that resulted from contributing to the phase 2 of the ceremony.

`snarkjs zkey export verificationkey miladyhash_01.zkey verification_key.json`

And we can finally generate our ZKP associated to the circuit!

`snarkjs groth16 prove miladyhash_01.zkey witness.wtns proof.json public.json`

And, we can verify it using the following command:

`snarkjs groth16 verify verification_key.json public.json proof.json`

Once this is all done, we're set. We can now export a verifier in Solidity, which we can then deploy on the blockchain:

`snarkjs zkey export solidityverifier miladyhash_01.zkey ../../src/verifier.sol`

And we're finally done! We compiled our Circom circuit, and we've got a ZKP that we can use on-chain.
