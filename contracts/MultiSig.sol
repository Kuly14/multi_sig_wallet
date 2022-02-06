// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MultiSig {
    event Deposit(address indexed sender, address indexed _token,  uint amount);
    event Submit(uint indexed txId);
    event Aproove(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    address[] public owners;
    // Checks if address is one of the owners.
    mapping(address => bool) public isOwner;
    // Num of owner that have to aproove the tx.
    uint public required;

    struct Transaction {
        address to;
        uint value;
        address token; 
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx doesnt exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "tx already aprooved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }



    constructor(address[] memory _owners, uint _requiered) {
        require(_owners.length > 0, "You have to add some owners.");
        require(_requiered > 0 && _requiered <= _owners.length, "invalid number of requiered");
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid Owner");
            require(!isOwner[owner], "owner is not uniquie");

            isOwner[owner] = true;
            owners.push(owner);

        }
    }


    // To call this function you will first have to aproove the amount. 
    function receiveErc20(address _token, uint _amount) external {
        require(IERC20(_token).balanceOf(msg.sender) >= _amount);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _token, _amount);

    }


    function submit(address _to, uint _value, address _token) external {
        require(checkIfIsOwner() == true);

        transactions.push(Transaction({
            to: _to, 
            value: _value,
            token: _token,
            executed: false
        }));

        emit Submit(transactions.length - 1);    
    }

    function aproove(uint _txId) external txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        require(checkIfIsOwner() == true, "Only of of the owners can call this function");
        approved[_txId][msg.sender] = true;
        emit Aproove(msg.sender, _txId);
    }

    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "every owner has to aproove the tx");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        uint amount = transaction.value;
        address receiver = transaction.to;
        address ercToken = transaction.token;
        
        IERC20(ercToken).transfer(receiver, amount);
        emit Execute(_txId);
    }


    // Helper functions

    function checkIfIsOwner() internal view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                return true;
            }
        }
        return false;
    }

    function _getApprovalCount(uint _txId) internal view returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
        return count;
    }
}