// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ContestGovernor.sol";
import "./ERC721Version.sol";
import "./SimpleTreasury.sol";

contract Masterpiece {

    
    ERC721Version immutable token;
    ContestGovernor immutable governor;
    address immutable treasuryAddress;
    
    
   
    constructor(string memory _name, string memory _symbol) {
        token =  new ERC721Version(_name,_symbol);
        governor = new ContestGovernor(token);
        treasuryAddress = address(governor.treasury());
        token.setTreasuryAddress(treasuryAddress);
        token.setDefaultRoyalty(treasuryAddress, 8);
        token.transferOwnership(address(governor));
        /**
        Note It could have a lot of sense to add onlyOwner modifier to fileUpgrades in ERC721Version
        Similarily a royalty deleter could make sense to in the Governor Contract
        Finally parameters for the MyGovernor contract concerning delays could be a great add-on to this constructor and allow to move further away from hard-coded values.
         */

    }    

}