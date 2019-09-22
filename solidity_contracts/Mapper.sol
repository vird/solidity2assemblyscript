pragma solidity ^0.5.11;

contract Mapper {
  mapping (address => uint) private balances; 
  function ifer() public payable {
    require(balances[msg.sender] + msg.value >= balances[msg.sender]);
    balances[msg.sender] += msg.value;
  }
}
