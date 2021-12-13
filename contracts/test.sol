// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract Test {
    struct AA {
        int a;
        int b;
    }

    mapping(int => AA) data;

    // function addnew() public  {
    //     AA storage newdata = (storage)AA({
    //         a: 1,
    //         b: 2
    //     });
    // }

    function divide(int a) public pure returns (int c) {
        return a * 2 /3;
    }
}

