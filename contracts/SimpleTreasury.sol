// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "./ERC721Version.sol";
import "./interfaces/ISimpleTreasury.sol";


contract SimpleTreasury is ISimpleTreasury, Ownable {

    // The amount of Ether within the treasury.
    uint256 balance;
    // The token representing the NFT collection.
    IERC721Version private immutable mainTokenOfProject;



    constructor (IERC721Version _mainCollection) {
        mainTokenOfProject =  _mainCollection;
        // from ownable owner = msg.sender;
        emit TreasuryInstantiated(msg.sender, address(this), address(mainTokenOfProject));     
    }
    
 
    receive() payable external{
        balance += msg.value;
        emit EthTransferReceived(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {return balance;}

    function getMainToken() external view returns (IERC721Version) {return mainTokenOfProject;}


    function sendETH(address payable _addr, uint256 _amount) public onlyOwner {
      _withdraw(_addr, _amount);
    }

    function _withdraw( address payable destAddr, uint256 amount) private{
        require(amount <=  balance, "Insufficient funds");
        destAddr.transfer(amount);
        balance -= amount;
        emit EtherWithdrawal(destAddr, amount);
    }

}