pragma solidity >=0.4.23 <0.6.0;

contract StructInStruct {
    struct User {
        uint experience;
        uint level;
        uint dividends;
    }

    struct King {
        address contender;
        User user;
        uint betPerCoin;
    }

    function play() public returns(bool isIndeed) {
        King memory k = King(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c, User(1,1,2), 4);
        return true;
    }
}