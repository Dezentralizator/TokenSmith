// SPDX-License-Identifier: MIT
// An add-on to NFTs to make them able to grow in Metadata over time.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
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

contract ERC721Version is ERC721Enumerable, ERC721Royalty, ERC721URIStorage, ERC721Votes, IERC721Version, Ownable {

    using Strings for uint256;

    uint256 public immutable maxSupply;
    uint256 public immutable mintingPrice;
    string[] public versionBaseURI;
    mapping(uint256 => uint256) public preferredVersionForOwner;
    string[] public usefulFiles;
    address creatorAddress;
    address treasuryAddress;
    

    constructor(string memory name, string memory symbol, address _creatorAddress, uint256 _maxSupply, uint256 _mintingPrice, string memory _baseURI)ERC721(name,symbol) EIP712(name, "1" ){

    maxSupply = _maxSupply;
    mintingPrice = _mintingPrice;
    creatorAddress = _creatorAddress;

    }

    function mint() external payable {
        require(msg.value == mintingPrice);
        _mint(msg.sender, this.totalSupply());
        payable(creatorAddress).transfer(msg.value*80/100);
        payable(treasuryAddress).transfer(msg.value*20/100);

    }

    function setTreasuryAddress(address _addressTreasury) public onlyOwner {
        treasuryAddress = _addressTreasury;
    }


    // Declares all previous interface, if a new one is created it should be added here
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721Royalty, ERC721) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || 
        ERC721Royalty.supportsInterface(interfaceId) || ERC721Version.supportsInterface(interfaceId) ||
        ERC721.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURIfromVersion(preferredVersionForOwner[tokenId]);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function tokenURI(uint256 tokenId, uint256 version) public view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURIfromVersion(version);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setPreferredVersion(uint256 tokenId, uint256 version) public {
        require(msg.sender == ownerOf(tokenId), "You are not allowed to select set preferred version for this token");
        preferredVersionForOwner[tokenId] = version;

    }

    function allFileURI() public view returns (string[] memory) {
        return usefulFiles;
    }

    function fileURI(uint256 fileId) public view returns (string memory) {
        return usefulFiles[fileId];
    }

    function addNewVersion(string calldata _newBaseURI) public virtual{
        
        versionBaseURI.push(_newBaseURI);
        emit NewVersion(msg.sender,_newBaseURI, versionBaseURI.length-1);     
    }

    function addNewFile(string calldata _fileURI) public virtual{

        usefulFiles.push(_fileURI);
        emit NewFile(msg.sender, _fileURI, usefulFiles.length-1);
    }


    // Selects the _beforeTokenTransfer function from Enumerable extension
    function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal virtual override (ERC721,ERC721Enumerable) {
        super._beforeTokenTransfer(from,to,tokenId);
    }


    // Selects the _burn function from Royalty and URIStorage extension, super.burn (ERC721) is called twice though..
    // Super.burn risks only invoking one of the inherited functions.
    // Super.burn(tokenId) should be sufficient alone due to the recursive calls within Royalty and URIStorage 
    // To check in test file.
    function _burn(uint256 tokenId) internal virtual override (ERC721,ERC721Royalty, ERC721URIStorage) {
        ERC721Royalty._burn(tokenId);
        ERC721URIStorage._burn(tokenId);
    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
        ) internal virtual override (ERC721, ERC721Votes){
        super._afterTokenTransfer(from,to,tokenId);
    }


    function _mint(address to, uint256 tokenId) internal virtual override {
        require(tokenId < maxSupply, "Max supply has already been achieved");
        super._mint(to, tokenId);
    }

    function _baseURIfromVersion(uint256 version) internal view returns ( string memory) {
        require(version < versionBaseURI.length, "No versions at this index yet");
        return versionBaseURI[version];
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

 }