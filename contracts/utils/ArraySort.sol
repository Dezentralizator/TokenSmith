// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
@author Inspired from subhodi github and transferred to  by Lorenz Schmidlin
@notice There are many sorting algorithms for array but they only operate on the core contract.
@dev By simply defining in the storage of your main contract a mapping whose values are the ones to use for ordering
the sortAddres library
 */

library Sorter{

    function quickSort(address[] memory arr, mapping(address => uint256) storage sorter, int left, int right) public view  {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = sorter[arr[uint(left + (right - left) / 2)]];
        while (i <= j) {
            while (sorter[arr[uint(i)]] < pivot) i++;
            while (pivot < sorter[arr[uint(j)]]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(arr, sorter, left, j);
        if (i < right)
            quickSort(arr, sorter, i, right);
    }

    function sort(address[] memory data, mapping(address => uint256) storage sorter) public view returns(address[] memory){
        quickSort(data, sorter, 0, int(data.length-1));
        return data;
    }
 
}
/**
Example use case 


contract QuickSort {

    mapping(address => uint256) addressToValue;
    function sort(address[] memory data) public view returns (address[] memory) {
        sortAddress.quickSort(data, addressToValue, int(0), int(data.length - 1));
        return data;
    }

    or 
    using sortAddress for address[]
    mapping(address => uint256) addressToValue;
    function sort(address[] memory data) public view returns (address[] memory) {
        data.quickSort(addressToValue, int(0), int(data.length - 1));
        return data;
    }



}


*/




