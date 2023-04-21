pragma circom 2.1.5;

include "./mimcsponge.circom";

template MiladyHash() {
    signal input pre_image;
    signal output hash;
    signal y;

    component mimc = MiMCSponge(1, 220, 1);
    mimc.ins[0] <== pre_image;
    mimc.k <== 0;

    hash <== mimc.outs[0];
}

component main = MiladyHash();