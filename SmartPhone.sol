//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Smartphone {
    string public make;
    string public model;
    string public osVersion;
    constructor(string memory _make, string memory _model, string memory _osVersion) {
        make = _make;
        model = _model;
        osVersion = _osVersion;
        }       
    }   


contract SmartphoneFactory {
    Smartphone[] public smartphones;
    event SmartphoneCreated(address indexed smartphoneAddress, string make, string model, string osVersion, uint index);
    function createSmartphone(string memory _make, string memory _model, string memory _osVersion) public {
        Smartphone smartphone = new Smartphone(_make, _model, _osVersion);
        smartphones.push(smartphone);
        uint index = smartphones.length - 1;
        emit SmartphoneCreated(address(smartphone), _make, _model, _osVersion, index);
        }
        
    function getSmartphone(uint _index) public view returns (string memory make, string memory model, string memory osVersion) {
        Smartphone smartphone = smartphones[_index];
        return (smartphone.make(), smartphone.model(), smartphone.osVersion());
        }
    }