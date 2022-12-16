//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IERC721.sol";

contract EnglishAuction {
    event Start();
    event Bid(address indexed _address, uint256 value);
    event Withdrowal(address indexed _address, uint256 value);
    event End(address _address, uint256 value);

    IERC721 public immutable nft;

    address payable public immutable seller;
    address public highestBidded;

    uint256 public immutable nftId;
    uint256 public highestBid;

    uint32 public endAt;
    bool public started;
    bool public ended;

    mapping(address => uint256) public bids;

    constructor(
        address _nft,
        uint256 _nftId,
        uint256 _startPrice
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);

        highestBid = _startPrice;
    }

    function start() external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");
        started = true;

        endAt = uint32(block.timestamp + 1 days);

        nft.transferFrom(seller, address(this), nftId);

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value not enought");

        highestBid = msg.value;
        highestBidded = msg.sender;

        bids[msg.sender] += msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdrowal() external payable {
        uint256 amount = bids[msg.sender];
        bids[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit Withdrowal(msg.sender, amount);
    }

    function end() external {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "Not ended");

        ended = true;

        if (highestBidded != address(0)) {
            nft.transferFrom(address(this), highestBidded, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidded, highestBid);
    }
}
