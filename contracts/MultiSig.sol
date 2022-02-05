// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract MultiSig {
    event Deposit(address indexed sender, uint amount);
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
        bytes data; 
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

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external {
        require(checkIfIsOwner() == true);

        transactions.push(Transaction({
            to: _to, 
            value: _value,
            data: _data,
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

        (bool sucess, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(sucess, "tx failed");

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