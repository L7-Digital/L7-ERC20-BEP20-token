// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSigWallet is Ownable {
    using SafeERC20 for IERC20;

     /*
     *  Constants
     */
    //uint constant public MAX_OWNER_COUNT = 50;

    /*
     *  Storage
     */
    // transactionId => compressed Transaction txData
    mapping (bytes32 =>  uint256) private transactions;
    // transactionId => address destination
    mapping (bytes32 =>  address payable) private destinations;
    mapping (bytes32 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;   
    uint public threshold;

    address[] private owners;

    /*
    *  Modifiers
    */
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "MultiSigWallet: not valid Owner");
        _;
    }

    modifier transactionExists(bytes32 transactionId) {
        require(transactions[transactionId] != 0);
        _;
    }

    modifier confirmed(bytes32 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(bytes32 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(bytes32 transactionId) {
        require(!(uint8(transactions[transactionId]) == 1));
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    constructor() Ownable(){
    }
    
    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    fallback() external payable {}

    receive() external payable { }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        external
        onlyOwner
        ownerDoesNotExist(owner)
        notNull(owner)
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
        confirmations[transactionId][msg.sender] = true;
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
        confirmations[transactionId][msg.sender] = false;
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(bytes32 transactionId)
        internal
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            uint256 _txData = transactions[transactionId];
       
            if(uint8(_txData) == 0){
                _txData = _txData | uint8(1);
            }
            
            uint256 _amount = uint256(uint88(_txData >> 8));
            address _erc20Address =  address(uint160(_txData >> 96));
            if(!external_submit(_erc20Address, destinations[transactionId], _amount)){
                _txData = _txData ^ uint8(1);
            }
            transactions[transactionId] = _txData;
        }
    }

    function external_submit(address erc20Address, address payable destination, uint256 amount) internal returns (bool result) {
        if(erc20Address == address(0)){
            // transfer ETH
            destination.transfer(amount);
        }else{
            // transfer ERC20
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
        if(transactions[transactionId] == 0){
            destinations[transactionId] = destination;

            uint256 _txData = uint256(uint160(erc20Address)); //160 bits
            _txData = (_txData << 88) | amount;
            _txData = (_txData << 8) | uint8(0);
       
            transactions[transactionId] = _txData; 
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

    function isConfirmed(bytes32 transactionId)
        public view
        returns (bool result)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == threshold)
                result = true;
                break;
        }
    }

    function transactionInfoOf(address _erc20Address, address payable _destination, uint256 _code, uint256 _amount)
        external view
    returns (bytes32 transactionId, address erc20Address, address payable destination, uint256 code, uint256 amount, bool executed)
    {
        transactionId = keccak256(abi.encodePacked(erc20Address, destination, code, amount));
        destination = destinations[transactionId];
        code = _code;
        uint256 _txData = transactions[transactionId];
        executed = uint8(_txData) == 1;
        amount = uint256(uint88(_txData>>8));
        erc20Address =  address(uint160(_txData>>96));
    }
}