// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Script.sol";

import "./MevblockerFeeTill.sol";

contract Deploy is Script {
    function run() public {
        address owner = vm.envAddress("OWNER");
        vm.broadcast();
        new MevBlockerFeeTill(owner);
    }
}
