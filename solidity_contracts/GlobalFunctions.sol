pragma solidity ^0.5.11;

contract Globals {
  uint public value;
  
  function ifer() public returns (uint) {
    uint x = block.number;

    return x;
  }
}
