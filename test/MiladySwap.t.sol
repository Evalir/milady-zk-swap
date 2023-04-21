// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {MiladyMock} from "test/mock/MiladyMock.sol";
import {MiladySwap} from "src/MiladySwap.sol";
import {Verifier} from "src/verifier.sol";

contract Helpers is Test {
    function account(string memory label) internal returns (address addr) {
        (addr,) = accountAndKey(label);
    }

    function accountAndKey(string memory label) internal returns (address addr, uint256 pk) {
        pk = uint256(keccak256(abi.encodePacked(label)));
        addr = vm.addr(pk);
        vm.label(addr, label);
    }
}

contract MiladySwapTest is Helpers {
    MiladyMock milady;
    MiladySwap miladySwap;
    Verifier verifier;

    address alice;
    address bob;

    function setUp() public {
        milady = new MiladyMock();
        verifier = new Verifier();
        miladySwap = new MiladySwap(address(milady), address(verifier));
        alice = account("alice");
        bob = account("bob");
        milady.mint(alice, 1);
        milady.mint(bob, 2);
    }

    function test_swapMilady() public {
        // set up approvals for the swap
        vm.prank(alice);
        milady.approve(address(miladySwap), 1);
        vm.prank(bob);
        milady.approve(address(miladySwap), 2);

        // start the swap
        vm.prank(alice);
        miladySwap.startZKSwap(bob, 1, 2);

        // accept the swap
        vm.prank(bob);
        miladySwap.acceptZKSwap(
            [
                0x1bd38429c69927cebd30d9645831b017e456e73227e893b1abb07dd278f2cb4b,
                0x1fb688937119612adb991a36f062dac73079d4506aec45782264a13cd648bf24
            ],
            [
                [
                    0x12da2a5b80a5f7d686a43d21e3063050669956d05e4a914987398ad0c39f9aa6,
                    0x1e809fe759631c5281661cfe0eaed0feef3a6388be7ee11d3c79bab74f21398b
                ],
                [
                    0x211294d7b252e10d500db8fb983558de83d0dfef329493d5ddb53b90ee66e468,
                    0x14437fbf33a7db3450b14d6221c82102379a0980df0a174ef2af68ba0dddebf9
                ]
            ],
            [
                0x1b2f7d1034995c077fcedd988c09b39a826c882389e238df5514c168b5ff62ec,
                0x24ee346f918c3a85facc36de4ab901d099d59ca250b7ac407c1eb525373f8e4f
            ],
            [0x14e72640c0f984d23cb1fd1815a9a54c70d0d542fd3e2141bbc7c4d02cdd5e18],
            alice
        );

        // finish the swap
        miladySwap.finishZKSwap(alice, bob);

        // assert that the swap was successful
        assert(milady.ownerOf(1) == bob);
        assert(milady.ownerOf(2) == alice);
    }
}
