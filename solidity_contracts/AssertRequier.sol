pragma solidity ^0.5.11;

contract AssertRequer { 
    function f() public {
        require(1 == 1);
        assert(1 != 2);
    }
}
