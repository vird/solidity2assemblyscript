pragma solidity ^0.5.11;

contract Arith {
  int public value;
  
  function arith() public returns (int yourMom) {
    int a = 5;
    int b = 1;
    int c = 9;
    c = -c;
    c = a + b;
    c = a - b;
    c = a * b;
    c = a / b;
    return c;
  }
}
