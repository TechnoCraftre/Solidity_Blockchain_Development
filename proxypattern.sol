//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract ProxyContract {
    uint public value = 0;
    address implAddr;

    constructor(address implementationAddr) {
        implAddr = implementationAddr;
    }

    function upgradeContract(address newImplementationContractAddress) public {
        implAddr = newImplementationContractAddress;
    }

    // function does not have a name --> fallback function
    // gets called for all unknown function identifiers
    fallback() external  {
        address implementationAddr = implAddr;
        require(implementationAddr != address(0));

        // In-line assembly code
        assembly {
            // the address of the delegate is loaded into storage
            // then copy the function signature and any parameters into memory.
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            // delegatecall to the target address is executed, including the function data that has been stored
            let result := delegatecall(gas(), implementationAddr, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            // execution outcome is returned and stored in the variable --> result
            switch result
            // execution outcome 0 --> revert any state changes
            case 0 {revert(ptr, size)}
            // execution outcome positive --> result is returned to the caller of the proxy
            default {return (ptr, size)}
        }
    }
}

contract ImplementationV1 {
    uint value;
    
    function incrementValue() public payable {
        value++; 
    }

    function decrementValue() public payable {
        value--; 
    }
}

contract ImplementationV2 {
    uint value;
    
    function incrementValue() public payable {
        value+=10; 
    }

    function decrementValue() public payable {
        value-=10; 
    }
}