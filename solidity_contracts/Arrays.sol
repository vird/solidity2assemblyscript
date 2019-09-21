pragma solidity ^0.5.11;

contract Array { 
    function f(uint len) public {
        uint[] memory a = new uint[](7);
        bytes memory b = new bytes(len);
        a[6] = 8;
    }
}
