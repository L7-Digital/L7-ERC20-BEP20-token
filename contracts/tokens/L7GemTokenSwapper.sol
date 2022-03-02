// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract L7GemTokenSwapper is ERC20, ERC20Burnable {
    uint256 public constant INIT_POOL_ALLOCATION = 10000;
    uint8 constant private decimal              = 0;
    string constant tokenName                   = "L7 GEM Token";
    string constant tokenSymbol                 = "GEM";

    constructor () ERC20(tokenName, tokenSymbol)
    {
        super._mint(address(this), INIT_POOL_ALLOCATION);
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }
}