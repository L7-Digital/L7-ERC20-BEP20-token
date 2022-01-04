// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./interfaces/IL7Token.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract L7InGameExchange is Ownable {
    using SafeERC20 for IL7Token;
    
    /*
     *  Events
     */
    event ExchangeDeposit(address indexed account, address indexed erc20, uint256 amount, uint256 timestamp);
    event ExchangeBurn(address indexed account, address indexed erc20, uint256 amount, uint256 timestamp);

    constructor() Ownable() { }
    
    function deposit(address erc20, uint256 amount) external {
        require(amount > 0, "L7InGameExchange: Invalid Amount");
        require(erc20 != address(0), "L7InGameExchange: Invalid ERC20 Address");
        IL7Token token = IL7Token(erc20);
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit ExchangeDeposit(msg.sender, erc20, amount, block.timestamp);
    }

    function burn(address erc20, uint256 amount) onlyOwner external {
        require(amount > 0, "L7InGameExchange: Invalid Amount");
        require(erc20 != address(0), "L7InGameExchange: Invalid ERC20 Address");
        IL7Token token = IL7Token(erc20);
        token.burn(amount);
        emit ExchangeBurn(msg.sender, erc20, amount, block.timestamp);
    }
}