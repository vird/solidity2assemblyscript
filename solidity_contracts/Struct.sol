pragma solidity ^0.5.11;

contract Struct {
  uint public value;
  
    struct User {
        uint experience;
        uint level;
        uint dividends;
    }

  function ifer() public {
    User memory u = User(1, 2, 3);
  }
}
