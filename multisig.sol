//SPDX-License-Identifier:MIT

pragma solidity ^0.5.0;

contract MultiSigWallet {
    
    // -- contract deployer's address
    address private owner;
    
    //-- mapping to hold addresses of authorized signers.  Uint8 is used to determine is the address enabled or disabled
    mapping(address => uint8) private _owners;    
    
    // number of signatures required to sign the transaction so that funds can be transferred.
    uint constant MIN_SIGNATURES = 2;
    
    // incremental transaction counter
    uint private _transactionIdx;
    
    // -- struct to represent a transaction submitted for others to approve.  
    // -- capture how many people signed the Transaction
    // -- track the accounts of the signers
    struct Transaction {
        address from;
        address payable to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }
    
    // mapping of transaction ID to a transaction.  
    mapping (uint => Transaction) private _transactions;
    
    //create a dynamic array containing pending transactions that need to be processed
    uint[] private _pendingTransactions;
    
    
    // to interact with the wallet you must be the owner
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // require owner or an enabled owner
    modifier validOwner() {
        require(msg.sender == owner || _owners[msg.sender] == 1);
        _;
    }
    
    // Events
    event DepositFunds(address from, uint amount);
    event WithdrawFunds(address from, uint amount);
    event TransferFunds(address from, address to, uint amount);
    event TransactionCreated(address by, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);
    
    
    //the creator of the contract is the owner of the wallet
    constructor() public {
        owner = msg.sender;
    }
    
    //this function is used to add owners of the wallet.  Only the isOwner can add addresses.  1 means enabled
    function addOwner(address _owner) isOwner public {
        _owners[_owner] = 1;
    }
    
    //remove an owner from the wallet.  0 means disabled
    function removeOwner(address _owner) isOwner public {
        _owners[_owner] = 0;   
    }
    
    //anyone can deposit funds into the wallet
    function () external payable {
        emit DepositFunds(msg.sender, msg.value);
    }

      
    function transferTo(address payable _to, uint _amount) validOwner public {
        //balance must be >= the amount of the transaction
        require(address(this).balance >= _amount);        
        // each Transaction needs a transactionId -->
        // create a transactionId by adding a number to the last id created (hence the use of ++)
        uint transactionId = _transactionIdx++;        
        //create a transaction using the struct, then add the information to the struct in memory
        //set the signature count to 0 which means it has not been signed yet
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to  = _to;
        transaction.amount = _amount;
        transaction.signatureCount = 0;        
        //add the transaction to the _transactions data structure (transaction map)
        //Transaction ID to the actual transaction
        //Add this transaction to the dynamic array using the push mechanism using the transactionId
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        //create an event that the transaction was created
        emit TransactionCreated(msg.sender, _to, _amount, transactionId);
    
    }
    
    //get a list of pending transactions 
    //you need to be an owner
    //returns the array of pending transactions
    function getPendingTransactions() validOwner public view returns (uint[] memory) {
        return _pendingTransactions;
    }
    
    // Sign the transaction. If minimum required signatures met then execute the transaction    
    function signTransaction(uint _transactionId) validOwner public payable{        
        //because the transaction was in "memory" to reference it we use storage
        //go to _transactions and get the transactionId and give it the variable name transaction
        Transaction storage transaction = _transactions[_transactionId];    
        //Transaction must exist (not the zero address)
        require(transaction.from != address(0));
        //creator cannot sign the transaction
        require(msg.sender != transaction.from);
        //cannot sign the transaction more then once 
        require(transaction.signatures[msg.sender] != 1);        
        //sign the tranaction
        transaction.signatures[msg.sender] = 1;
        //increment the signatureCount by 1
        transaction.signatureCount++;

        //emit event
        emit TransactionSigned(msg.sender, _transactionId);    
        // if the transaction has a signature count >= the minimum signatures we can process the transaction
        if (transaction.signatureCount >= MIN_SIGNATURES) {
            //check sufficient balance in contract
            require(address(this).balance >= transaction.amount);          
            // Call returns a boolean value indicating success or failure. This is the current recommended method to use.
           
            transaction.to.transfer(transaction.amount);
            
            
            //emit an event
            emit TransactionCreated(transaction.from, transaction.to, transaction.amount, _transactionId);
            //delete the transaction id
            deleteTransaction(_transactionId);
        }
    }
        
    function deleteTransaction(uint _transactionId) validOwner public {
        // to delete from a dynamic array, delete the element from array and reshuffle
        uint8 replace = 0;
        for(uint i = 0; i < _pendingTransactions[i]; i++) {
            //find the transaction 
            _pendingTransactions[i-1] = _pendingTransactions[i];
            if (_transactionId == _pendingTransactions[i]) {
                replace = 1;
            }
        }
        // delete the final element in the array 
        delete _pendingTransactions[_pendingTransactions.length -1];
        // decrement the array by 1
        _pendingTransactions.length--;
        // delete the transaction from the map
        delete _transactions[_transactionId];
    }
    
    //
    function walletBalance() view public returns (uint) {
        return address(this).balance;
        }
}

