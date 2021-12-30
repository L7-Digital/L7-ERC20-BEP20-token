// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract L7Token is ERC20, AccessControl {
    uint8 constant private decimal              = 18;
    uint256 constant private maxSupply          = 1000000000 * 10**decimal;
    string constant tokenName                   = "L7 Token";
    string constant tokenSymbol                 = "L7";

    bytes32 public constant GENESIS_ROLE = keccak256("GENESIS_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address burner;

    event Burn(address indexed burner, uint256 amount);
    event ChangeBurner(address oldBurner, address newBurner);

    constructor (
        address _genesis,
        address _burner
    ) 
        ERC20(tokenName, tokenSymbol)
    {
        _setupRole(GENESIS_ROLE, _genesis);
        _setupRole(BURNER_ROLE, _burner);
        
        burner = _burner;

        super._mint(_genesis, maxSupply);
    }

    function deposit(uint256 amount) external 
    {
        super._transfer(msg.sender, burner, amount);
    }

    function burn() onlyRole(BURNER_ROLE) external
    {
        super._burn(msg.sender, balanceOf(msg.sender));
        emit Burn(msg.sender, balanceOf(msg.sender));
    }

    function changeBurner(address _newBurner) onlyRole(BURNER_ROLE) external
    {
        require(_newBurner != burner, "L7Token: burner exists");
        super._transfer(msg.sender, _newBurner, balanceOf(msg.sender));
        super._revokeRole(BURNER_ROLE, burner);
        super._setupRole(BURNER_ROLE, _newBurner);
        emit ChangeBurner(burner, _newBurner);
    }
}