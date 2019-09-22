pragma solidity ^0.5.11;

contract Reverter { 
    function f() public {
        revert();
    }
}
