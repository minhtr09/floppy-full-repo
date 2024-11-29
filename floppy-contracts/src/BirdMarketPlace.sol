pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BirdMarketPlace is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    IERC721Enumerable private _nft;
    IERC20 private _token;
    uint256 private _tax = 10; // percentage
    struct ListDetail {
        address payable author;
        uint256 price;
        uint256 tokenId;
    }
    event ListNFT(address indexed from, uint256 tokenId, uint256 price);
    event UnListNFT(address indexed from, uint256 tokenId);
    event BuyNFT(address indexed from, uint256 tokenId, uint256 price);
    event UpdateListingNFTPrice(uint256 tokenId, uint256 price);
    event SetToken(IERC20 token);
    event SetTax(uint256 tax);
    event SetNFT(IERC721Enumerable nft);

    mapping(uint256 => ListDetail) listDetail;

    constructor(
        address initialOwner,
        IERC20 token,
        IERC721Enumerable nft
    ) Ownable(initialOwner) {
        _token = token;
        _nft = nft;
    }

    function setTax(uint256 tax) public onlyOwner {
        _tax = tax;
        emit SetTax(tax);
    }

    function setToken(IERC20 token) public onlyOwner {
        _token = token;
        emit SetToken((token));
    }

    function setNft(IERC721Enumerable nft) public onlyOwner {
        _nft = nft;
        emit SetNFT(nft);
    }

    function getListedNfts() public view returns (ListDetail[] memory) {
        uint256 balance = _nft.balanceOf(address(this));
        ListDetail[] memory myNfts = new ListDetail[](balance);
        for (uint256 i = 0; i < balance; i++) {
            myNfts[i] = listDetail[_nft.tokenOfOwnerByIndex(address(this), i)];
        }

        return myNfts;
    }

    function listNft(uint256 tokenId, uint256 price) public {
        require(
            msg.sender == _nft.ownerOf(tokenId),
            "You are not the owner of this NFT"
        );
        require(
            _nft.getApproved(tokenId) == address(this),
            "Market does not approved to transfer this NFT"
        );
        listDetail[tokenId] = ListDetail(payable(msg.sender), price, tokenId);
        _nft.safeTransferFrom(msg.sender, address(this), tokenId);
        emit ListNFT(msg.sender, tokenId, price);
    }

    function updateListedNftPrice(uint256 tokenId, uint256 new_price) public {
        require(
            _nft.ownerOf(tokenId) == address(this),
            "This NFT does not exist on market place"
        );
        require(
            msg.sender == listDetail[tokenId].author,
            "Only owner can update the price of this NFT"
        );

        listDetail[tokenId].price = new_price;
        emit UpdateListingNFTPrice(tokenId, new_price);
    } 
    
    function unlistNft(uint256 tokenId) public {
        require(
            _nft.ownerOf(tokenId) == address(this),
            "This NFT does not exist on market place"
        );
        require(
            msg.sender == listDetail[tokenId].author,
            "Only owner can unlist this NFT"
        );
        delete listDetail[tokenId];
        _nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit UnListNFT(msg.sender, tokenId);
    }

    function buyNFT(uint256 tokenId) public {
        require(
            _token.balanceOf(msg.sender) >= listDetail[tokenId].price,
            "Insufficient account balance"
        );
        require(
            _nft.ownerOf(tokenId) == address(this),
            "This NFT does not exist on market place"
        );
        SafeERC20.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            listDetail[tokenId].price
        );
        _token.transfer(
            listDetail[tokenId].author,
            (listDetail[tokenId].price * (100 - _tax)) / 100
        );
        _nft.safeTransferFrom(address(this), msg.sender, tokenId);
        emit BuyNFT(msg.sender, tokenId, listDetail[tokenId].price);
    }

    function withdrawToken(uint256 amount) public onlyOwner {
        require(
            _token.balanceOf(address(this)) >= amount,
            "Insufficient account balance"
        );
        _token.transfer(msg.sender, amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
