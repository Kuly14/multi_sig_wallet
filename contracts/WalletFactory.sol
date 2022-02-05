// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiSig.sol";

contract WalletFactory {

    MultiSig[] public multiSigArray;
    // Mapping that tracks the addresses of the contract. TraderAddress => ContractAddress.
    mapping(address => address) public contractAddress;
    
    function createMultiSigContract(address[] memory _owners, uint _numOfSigners) public {
        // Always put traders address first into the array.
        MultiSig multisig = new MultiSig(_owners, _numOfSigners);
        multiSigArray.push(multisig);
        contractAddress[_owners[0]] = address(multisig);
    }
}
