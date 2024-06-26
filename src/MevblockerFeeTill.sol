// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract MevBlockerFeeTill {
    // --- key invariant ---
    // this.balance == earned + sum(bonds)

    // --- events ---
    event Passed(address indexed previousOwner, address newOwner);
    event Relied(address indexed usr);
    event Denied(address indexed usr);
    event Joined(address indexed usr, uint256 amt);
    event Price(uint256 fee);
    event Billed(address indexed usr, uint256 amt);
    event Unbilled(address indexed usr, uint256 amt);
    event Paid(address indexed usr, uint256 amt);
    event Drafted(address indexed usr, uint256 amt);
    event Fined(address indexed usr, uint256 amt, address to);
    event Noped(address indexed usr);
    event Exited(address indexed usr, uint256 bond);
    event Reaped(uint256 amt);

    // --- auth ---
    address payable public owner;
    mapping (address => bool) public billers;
    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }
    modifier onlyBiller {
        require(billers[msg.sender] == true, "not biller");
        _;
    }
    constructor(address _owner) {
        owner = payable(_owner);
    }
    function pass(address whom) external onlyOwner {
        address previousOwner = owner;
        owner = payable(whom);
        emit Passed(previousOwner, whom);
    }
    function rely(address whom) external onlyOwner {
        billers[whom] = true;
        emit Relied(whom);
    }
    function deny(address whom) external onlyOwner {
        billers[whom] = false;
        emit Denied(whom);
    }

    // --- bonding ---
    uint256 public wait = 7 days;
    mapping (address => uint256) public bonds;
    mapping (address => uint256) public noped;

    function join() payable external {
        bonds[msg.sender] += msg.value;
        noped[msg.sender] = 0;
        emit Joined(msg.sender, msg.value);
    }

    // --- billing ---
    mapping (address => uint256) public dues;
    uint256 public price;
    uint256 public earned;

    function bill(address[] calldata ids, uint256[] calldata due, uint256 newPrice) external onlyBiller {
        for (uint256 i = 0; i < ids.length; i++) {
            dues[ids[i]] += due[i];
            emit Billed(ids[i], due[i]);
        }
        price = newPrice;
        emit Price(newPrice);
    }
    function unbill(address[] calldata ids, uint256[] calldata undue) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            dues[ids[i]] -= undue[i];
            emit Unbilled(ids[i], undue[i]);
        }
    }
    function pay(address id) payable external {
        dues[id] -= msg.value;
        earned += msg.value;
        emit Paid(id, msg.value);
    }

    // --- forced payments ---
    function draft(address id, uint256 amt) external onlyOwner {
        bonds[id] -= amt;
        dues[id] -= amt;
        earned += amt;
        emit Drafted(id, amt);
    }
    function fine(address id, uint256 amt, address to) external onlyOwner {
        bonds[id] -= amt;
        payable(to).transfer(amt);
        emit Fined(id, amt, to);
    }

    // --- withdrawing ---
    function nope() external {
        noped[msg.sender] = block.timestamp;
        emit Noped(msg.sender);
    }
    function exit() external {
        require(noped[msg.sender] != 0, "didn't nope");
        require(block.timestamp > noped[msg.sender] + wait, "too early");
        require(dues[msg.sender] == 0, "didn't pay");
        uint256 bond = bonds[msg.sender];
        bonds[msg.sender] = 0;
        payable(msg.sender).transfer(bond);
        emit Exited(msg.sender, bond);
    }
    function reap() external onlyOwner {
        uint256 amt = earned;
        earned = 0;
        payable(msg.sender).transfer(amt);
        emit Reaped(amt);
    }
}
