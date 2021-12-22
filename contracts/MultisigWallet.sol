// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MultisigWallet is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    /*
     *  Storage
     */
    struct TransactionData {
        uint256 amount;
        uint256 code;
        address erc20Address;
        address payable destination;
        bool isExecuted;
        mapping(address => bool) confirmations;
    }
    mapping (bytes32 => TransactionData) private transactions;

    mapping (address => bool) public isOwner;   
    uint public threshold;
    address[] private owners;

    /*
    *  Modifiers
    */
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Wallet: already owner");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Wallet: not valid Owner");
        _;
    }

    modifier transactionExists(bytes32 transactionId) {
        require(transactions[transactionId].amount != 0 || transactions[transactionId].destination != address(0), "Wallet: Tx not exist");
        _;
    }

    modifier confirmed(bytes32 transactionId, address owner) {
        require(transactions[transactionId].confirmations[owner], "Wallet: Tx is not confirmed");
        _;
    }

    modifier notConfirmed(bytes32 transactionId, address owner) {
        require(!transactions[transactionId].confirmations[owner], "Wallet: Tx already confirmed");
        _;
    }

    modifier notExecuted(bytes32 transactionId) {
        require(!transactions[transactionId].isExecuted, "Wallet: Tx already executed");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier isNotSentFromContract(address _address) {
        require(!_address.isContract());
        _;
    }

    constructor() Ownable() payable { }
    
    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    fallback() external payable { }

    receive() external payable { }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        external
        onlyOwner
        ownerDoesNotExist(owner)
        notNull(owner)
        isNotSentFromContract(owner)
    {
        isOwner[owner] = true;
        owners.push(owner);
        changeRequirement();
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        external
        onlyOwner
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i < owners.length - 1; i++){
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];                
                break;
            }
        }  
        owners.pop();          
        changeRequirement();
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        external
        onlyOwner
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
    }

    function changeRequirement()
        internal
    {
        uint _threshold = (owners.length * 2) / 3;            
        if (_threshold == 0)
            _threshold = 1;
        threshold = _threshold;
    }

    function submitTransaction(address erc20Address, address payable destination, uint256 code, uint256 amount)
        external
        returns (bytes32 transactionId)
    {
        transactionId = addTransaction(erc20Address, destination, code, amount);
        confirmTransaction(transactionId);
    }

    function submitTransaction(address payable destination, uint256 code, uint256 amount)
        external
        returns (bytes32 transactionId)
    {
        transactionId = addTransaction(address(0), destination, code, amount);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(bytes32 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        transactions[transactionId].confirmations[msg.sender] = true;
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(bytes32 transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        transactions[transactionId].confirmations[msg.sender] = false;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(bytes32 transactionId)
        internal
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {        
        if (hasEnoughConfirmations(transactionId)) {
            TransactionData storage currTransaction = transactions[transactionId];
            if(external_submit(currTransaction.erc20Address, currTransaction.destination, currTransaction.amount)){
                currTransaction.isExecuted = true;
            }
        }
    }

    function external_submit(address erc20Address, address payable destination, uint256 amount) 
        internal 
        returns (bool result) 
    {
        if(erc20Address == address(0)){
            // transfer ETH, throws error on fail
            destination.transfer(amount);
        } else {
            // transfer ERC20, throws error on fail
            IERC20(erc20Address).safeTransfer(destination, amount);
        }
        result = true;
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    function addTransaction(address erc20Address, address payable destination, uint256 code, uint256 amount)
        internal
        returns (bytes32 transactionId)
    {
        transactionId = keccak256(abi.encodePacked(erc20Address, destination, code, amount));
        if (transactions[transactionId].amount == 0) {
            TransactionData storage newTransaction = transactions[transactionId];
            newTransaction.erc20Address = erc20Address;
            newTransaction.destination = destination;
            newTransaction.amount = amount;
            newTransaction.code = code;
        }
    }

    /// @dev Returns list of validators.
    /// @return List of owner addresses.
    function getOwners()
        external view
        returns (address[] memory)
    {
        return owners;
    }

    function hasEnoughConfirmations(bytes32 transactionId)
        public view
        returns (bool result)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (transactions[transactionId].confirmations[owners[i]])
                count += 1;
            if (count == threshold){
                result = true;
                break;
            }                
        }
    }

    function transactionInfoOf(address _erc20Address, address payable _destination, uint256 _code, uint256 _amount)
        external 
        view
        returns (bytes32 transactionId, address erc20Address, address payable destination, uint256 code, uint256 amount, bool isExecuted)
    {
        transactionId = keccak256(abi.encodePacked(_erc20Address, _destination, _code, _amount));
        
        TransactionData storage currTransaction = transactions[transactionId];
        erc20Address = currTransaction.erc20Address;
        destination = currTransaction.destination;
        code = currTransaction.code;
        amount = currTransaction.amount;
        isExecuted = currTransaction.isExecuted;
    }

    function getBalance() 
        public
        view 
        returns (uint256) 
    {
        return address(this).balance;
    }
}