// SPDX-License-Identifier: MIT
// Simplest Treasury possible for add-on to NFTs to make them able to grow in Metadata over time.

/**
@author Lorenz Schmidlin
@notice Very simple treasury for earlier test and versions. 
@dev This vault will be instantiated by a governorContest contract to create self-upgrading NFTs.
 */

pragma solidity ^0.8.0;

import "../ERC721Version.sol";

interface ISimpleTreasury {
    function getMainToken() external view returns(IERC721Version);

    // Announces the creation of treasury along with its ERC20.
    event TreasuryInstantiated(address treasuryOwner, address treasury, address token);
    event EthTransferReceived(address indexed _from, uint256 _value);
    event EtherWithdrawal(address indexed _to, uint256 _value);

}