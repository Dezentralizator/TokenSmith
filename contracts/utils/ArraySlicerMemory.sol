// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
@author Lorenz Schmidlin
@notice A library to help manage storage arrays when only a small part is relevant for exection.
Esepcially relevant when storing various states in a one common array where ordering mattered.
@dev This library is to be used for address array but could be modified for any other structs.
This allows to pass small cuts of a storage array as memory to allow proper manipulation afterwards without explosing gas.
The startIndex and endIndex are considered INCLUSIVE to the final cut.
 */

library Slicer{

    function startSlicer (address[] storage storageArray, uint256 startIndex) public view returns (address[] memory){

        require(storageArray.length > startIndex,"The starting cut is out of bounds of this array");
        uint256 sliceSize = storageArray.length - startIndex;
        address[] memory slicedArray = new address[](sliceSize);
        for (uint i = 0; i < sliceSize; i++){
            slicedArray[i] = storageArray[i+startIndex];
        }

        return slicedArray;

    }

    function endSlicer (address[] storage storageArray, uint256 endIndex) public view returns (address[] memory){

        require(storageArray.length > endIndex, "Ending cut is out of bounds of this array");
        address[] memory slicedArray = new address[](endIndex+1);
        for (uint i = 0; i < endIndex+1; i++){
            slicedArray[i] = storageArray[i];
        }

        return slicedArray;

    }

    function dualSlicer (address[] storage storageArray, uint256 startIndex, uint256 endIndex) public view returns (address[] memory){

        require(storageArray.length > endIndex,"The cut is out of bounds of this array");
        require(endIndex > startIndex, "The index should be permuted or an error was done");

        uint256 sliceSize = endIndex - startIndex + 1;
        address[] memory slicedArray = new address[](sliceSize);
        for (uint i = 0; i < sliceSize; i++){
            slicedArray[i] = storageArray[i+startIndex];
        }

        return slicedArray;

    }
}





