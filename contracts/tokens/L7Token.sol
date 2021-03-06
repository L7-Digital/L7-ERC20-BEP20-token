// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract L7Token is ERC20, ERC20Burnable {
    uint8 constant private decimal              = 18;
    uint256 constant private maxSupply          = 1000000000 * 10**decimal;
    string constant tokenName                   = "L7 Token";
    string constant tokenSymbol                 = "L7";

    constructor (address wallet) ERC20(tokenName, tokenSymbol)
    {
        super._mint(wallet, maxSupply);
    }
}