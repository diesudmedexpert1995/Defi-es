// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address, address, uint256) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address indexed bidder, uint256 amount);


    IERC721 public nft;
    uint256 public nftId;

    address payable public seller;
    uint256 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address=>uint256) public bids;
    
    constructor(address _nft, uint256 _nftId, uint256 _startingBid){
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable (msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        require(!started, "Auction started");
        require(msg.sender == seller, "Is not seller");

        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp;
        emit Start();
    }

    function bid() external payable {
        require(started, "Auction not started");
        require(block.timestamp < endAt, "Auction ended");
        require(msg.value > highestBid, "value < highest");

        if(highestBidder != address(0)){
            bids[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 balance = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit Withdraw(msg.sender, balance);
    }

    function end() external{
        require(started, "Auction not started");
        require(block.timestamp > endAt, "Auction not ended");
        require(!ended, "Auction ended");
        ended = true;

        if(highestBidder != address(0)){
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        }else{
            nft.safeTransferFrom(address(this), seller, nftId);
        }
        emit End(highestBidder, highestBid);
    }
}