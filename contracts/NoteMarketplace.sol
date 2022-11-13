// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NoteMarketplace is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    //_tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIds;
    //Keeps track of the number of items sold on the marketplace
    Counters.Counter private _itemsSold;
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 listPrice = 0.001 ether;

    // the structure to store info about a listed token
    struct ListedNote {
      uint256 tokenId;
      address payable owner;
      address payable seller;
      uint256 price;
      bool currentlyListed;
    }

    // the event emitted when a token is successfully listed
    event NoteListedSuccess (
      uint256 indexed tokenId,
      address owner,
      address seller,
      uint256 price,
      bool currentlyListed
    );

    // This mapping tokenId to token info and is helpful when retrieving details a tokenId
    mapping(uint256 => ListedNote) private idToListedNote;

    constructor() ERC721("NoteMarketplace", "NMP") {
      owner = payable(msg.sender);
    }

    function noteMint(string memory uri, uint256 price) public {
        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        // Helper function to update Global variables and emit an event
        createListedToken(tokenId, price);
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
      // Make sure the sender sent enough ether ETH to pay for listing
      require(msg.value == listPrice, "Not enough ETH to list");
      require(price > 0, "Make sure that the price isn't negative");

      // Update the mapping of tokenId's to Token details, useful for retrieval functions
      idToListedNote[tokenId] = ListedNote(
        tokenId,
        payable(address(this)),
        payable(msg.sender),
        price,
        true
      );
    }

    // 出品している投稿を取得
    function getAllListedNotes() public view returns (ListedNote[] memory) {
      uint nftCount = _tokenIds.current();
      ListedNote[] memory notes = new ListedNote[](nftCount);
      uint currentIndex = 0;

      // currentlyListedの真偽で分ける
      for (uint256 i = 0; i < nftCount; i++) {
        if(idToListedNote[i].currentlyListed) {
          ListedNote storage currentItem = idToListedNote[i];
          notes[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return notes;
    }

    function getMyNotes() public view returns (ListedNote[] memory) {
      uint256 totalNftsCount = _tokenIds.current();
      uint256 myNoteCount = 0;

      for (uint256 i = 0; i < totalNftsCount; i++) {
        if (idToListedNote[i].owner == msg.sender) {
          myNoteCount += 1;
        }
      }

      ListedNote[] memory myNotes = new ListedNote[](myNoteCount);

      for (uint256 i = 0; i < totalNftsCount; i++) {
        if (idToListedNote[i].seller == msg.sender) {
          ListedNote storage currentItem = idToListedNote[i];
          myNotes[0] = currentItem;
          myNoteCount += 1;
        } else {
          myNoteCount += 1;
        }
      }
      return myNotes;
    }

    function executeSale(uint256 tokenId) public payable {
      uint price = idToListedNote[tokenId].price;
      address seller = idToListedNote[tokenId].seller;
      require(msg.value == price, "Please submit the asking price in order to complete the purchase");

      // update the details of the token
      idToListedNote[tokenId].currentlyListed = true;
      idToListedNote[tokenId].seller = payable(msg.sender);
      _itemsSold.increment();

        //Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);

        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        //Transfer the listing fee to the marketplace creator
        payable(owner).transfer(listPrice);
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(msg.value);
    } 

    function updateListPrice(uint256 _listPrice) public payable {
    require(owner == msg.sender, "Only owner can update listing price");
    listPrice = _listPrice;
    }

    function getListPrice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestIdToListedNote() public view returns (ListedNote memory) {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedNote[currentTokenId];
    }

    function getListedNoteForId(uint256 tokenId) public view returns (ListedNote memory) {
        return idToListedNote[tokenId];
    }

    function getCurrentNote() public view returns (uint256) {
        return _tokenIds.current();
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}