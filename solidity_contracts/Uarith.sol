pragma solidity ^0.5.11;

contract Arith {
  uint public value;
  
  function arith() public returns (uint yourMom) {
    uint a = 1;
    uint b = 2;
    uint c = 3;
    c = a + b;
    c = a * b;
    c = a / b;
    c = a | b;
    c = a & b;
    c = a ^ b;
    return c;
  }
}
