pragma solidity ^0.5.11;

contract Globals {
  uint public value;
  
  function ifer() public returns (uint) {
    uint x = uint(keccak256(abi.encode(0x26)));
    return x;
  }
}
