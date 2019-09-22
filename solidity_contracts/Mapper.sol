pragma solidity ^0.5.11;

contract Mapper {
  mapping (address => uint) private balances; 
  function ifer() public payable {
    uint x = 333;
    balances[msg.sender] = 5;
    uint balance = balances[msg.sender];
    balances[msg.sender] += x;
  }
}
