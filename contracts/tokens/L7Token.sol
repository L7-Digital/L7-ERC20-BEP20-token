// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract L7Token is ERC20 {
    uint8 constant private decimal              = 18;
    uint256 constant private maxSupply          = 1000000000 * 10**decimal;
    string constant tokenName                   = "L7 Token";
    string constant tokenSymbol                 = "L7";

    event Burn(address indexed burner, uint256 amount);

    constructor (address wallet) 
        ERC20(tokenName, tokenSymbol)
        //ERC20Capped(maxSupply * 10**decimal)
    {
        super._mint(wallet, maxSupply);
    }

    function deposit(uint256 amount) external 
    {    
        super._burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }
}