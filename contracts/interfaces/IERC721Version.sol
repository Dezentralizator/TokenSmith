// SPDX-License-Identifier: MIT
// An add-on to NFTs to make them able to grow in Metadata over time.

/**
@author Lorenz Schmidlin
@notice Extension based on openZeppelin's implementation of the ERC721 Token standard to generate improvable metadata.
@dev The main bonus is to create ways to fetch metadata of an NFT so that it can be upgraded as the community implements better source file.
- BaseURI is upgradeable and can generate improvements of the NFT.
- FileURI represents various type of files for the system not used for procedural generation.


 */
pragma solidity ^0.8.0;
interface IERC721Version{

    /**
    @dev Access to the various procedurally generated core files and their upgraded version  
    */
    function tokenURI(uint256 tokenId, uint256 version) external view returns (string memory);

    /** 
    @dev Access to the complete list of files for project development
    */
    function allFileURI() external view returns (string[] memory);

    /**
    @dev Retrieve a specific file.
     */
    function fileURI(uint256 fileIndex) external view returns (string memory);

    /**
    @dev Add the coreURI of the new core generative base.
     */
    function addNewVersion(string calldata _newBaseURI) external;

    /** 
    @dev Add the URI of any form of file to the development of the project
    */
    function addNewFile(string calldata _FileURI) external;

    
    /**
    @dev Event emitted when a new file is added to the core
     */

    event NewFile(address deliveryAddress, string newFile, uint256 fileID);

    event NewVersion(address deliveryAddress, string newVersion, uint256 versionID);

}