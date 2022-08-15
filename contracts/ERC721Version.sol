// SPDX-License-Identifier: MIT
// An add-on to NFTs to make them able to grow in Metadata over time.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/governance/utils/Votes.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC721Version.sol";


/**
@dev This is the core NFT. It is designed to be a self-upgrading NFT.
ERC721Version adds versioning to the Metadata.
The uri metadata can now point to different files added over time.
The limitations for adding new files should be derived in the inheriting contract
ERC721Enumerable is used to organize voting system

 */

contract ERC721Version is ERC721Enumerable, ERC721Royalty, Votes, Ownable, IERC721Version {

    using Strings for uint256;

    uint128 public  maxSupply = 10000;
    uint128 public  mintingPrice = 0;
    string[] public coreFiles = [""];
    address public creatorAddress;
    address public treasuryAddress;
    

    constructor(string memory name, string memory symbol)ERC721(name,symbol) EIP712(name, "1" ){

    creatorAddress = msg.sender;



    }

    function mint(address _address, uint256 tokenId) external payable {
        require(msg.value == mintingPrice);
        _mint(_address, tokenId);
        payable(creatorAddress).transfer(msg.value*80/100);
        payable(treasuryAddress).transfer(msg.value*20/100);

    }

    function setTreasuryAddress(address _addressTreasury) public onlyOwner {
        treasuryAddress = _addressTreasury;
    }


    // Declares all previous interface, if a new one is created it should be added here
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721Royalty) returns (bool) {
        return interfaceId == type(IERC721Version).interfaceId || 
        super.supportsInterface(interfaceId);
    }

    function fileURI(uint256 fileId) public view returns (string memory) {
        return coreFiles[fileId];
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return coreFiles[0];
    }

    function addNewFile(string calldata _fileURI) public virtual{

        coreFiles.push(_fileURI);
        emit NewFile(msg.sender, _fileURI, coreFiles.length-1);
    }


    // Selects the _beforeTokenTransfer function from Enumerable extension
    function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal virtual override (ERC721,ERC721Enumerable) {
        super._beforeTokenTransfer(from,to,tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(tokenId < maxSupply, "Max supply has already been achieved");
        super._mint(to, tokenId);
    }

  

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }

 }