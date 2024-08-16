// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./MevblockerFeeTill.sol";

interface Hevm {
    function warp(uint256) external;
    function expectRevert(bytes memory) external;
}

contract Usr {
    receive() external payable {
    }
    function join(MevBlockerFeeTill till, uint256 bond) public {
        till.join{value: bond}();
    }
    function pay(MevBlockerFeeTill till, uint256 amt) public {
        till.pay{value: amt}(address(this));
    }
    function nope(MevBlockerFeeTill till) public {
        till.nope();
    }
    function exit(MevBlockerFeeTill till) public {
        till.exit();
    }

}

contract MevBlockerFeeTillTest is DSTest {
    Hevm hevm;

    MevBlockerFeeTill till;
    Usr builder1;

    receive() external payable {
    }

    function setUp() public {
        // enable hevm cheatcode and init timestamp
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        till = new MevBlockerFeeTill(address(this));
        builder1 = new Usr();

        payable(address(builder1)).transfer(20 ether);

        till.rely(address(this));
    }

    function test_happy_path() public {
        builder1.join(till, 10 ether);
        assertEq(till.bonds(address(builder1)), 10 ether);

        address[] memory ids = new address[](1);
        uint256[] memory due = new uint256[](1);
        ids[0] = address(builder1);
        due[0] = 1 ether;
        till.bill(ids, due, 0.001 ether);
        assertEq(till.dues(address(builder1)), 1 ether);
        assertEq(till.price(), 0.001 ether);

        builder1.pay(till, 1 ether);
        assertEq(till.dues(address(builder1)), 0 ether);
        assertEq(till.earned(), 1 ether);

        hevm.expectRevert(bytes("didn't nope"));
        builder1.exit(till);

        builder1.nope(till);
        hevm.expectRevert(bytes("too early"));
        builder1.exit(till);

        hevm.warp(block.timestamp + 7 days + 1);
        builder1.exit(till);
        assertEq(address(builder1).balance, 19 ether);

        uint256 old_balance = address(this).balance;
        till.reap();
        assertEq(address(this).balance, old_balance + 1 ether);
    }

    function test_draft() public {
        builder1.join(till, 10 ether);

        address[] memory ids = new address[](1);
        uint256[] memory due = new uint256[](1);
        ids[0] = address(builder1);
        due[0] = 1 ether;
        till.bill(ids, due, 0.001 ether);

        till.draft(address(builder1), 1 ether);
        assertEq(till.bonds(address(builder1)), 9 ether);
        assertEq(till.dues(address(builder1)), 0 ether);
        assertEq(till.earned(), 1 ether);
    }

    function test_fine() public {
        builder1.join(till, 10 ether);

        uint256 old_balance = address(this).balance;
        till.fine(address(builder1), 1 ether, address(this));
        assertEq(till.bonds(address(builder1)), 9 ether);
        assertEq(address(this).balance, old_balance + 1 ether);
    }

    function test_correction() public {
        builder1.join(till, 10 ether);

        address[] memory ids = new address[](1);
        uint256[] memory due = new uint256[](1);
        ids[0] = address(builder1);
        due[0] = 1 ether;
        till.bill(ids, due, 0.001 ether);
        assertEq(till.dues(address(builder1)), 1 ether);

        till.unbill(ids, due);
        assertEq(till.dues(address(builder1)), 0 ether);
    }
}
