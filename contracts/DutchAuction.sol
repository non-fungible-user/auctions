//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IERC721.sol";

contract DutchAuction {
    IERC721 public immutable nft;

    uint256 public immutable nftId;
    uint256 public immutable startingPrice;
    uint256 public immutable startsAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;

    address payable public immutable seller;

    uint256 private constant DURATION = 7 days;

    constructor(
        address _nft,
        uint256 _nftId,
        uint256 _startingPrice,
        uint256 _discountRate
    ) {
        require(_discountRate > 0, "wrong start price");
        require(
            _startingPrice >= _discountRate * DURATION,
            "wrong start price"
        );

        startsAt = block.timestamp;
        expiresAt = block.timestamp + DURATION;

        seller = payable(msg.sender);

        nft = IERC721(_nft);
        nftId = _nftId;

        startingPrice = _startingPrice;
        discountRate = _discountRate;
    }

    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startsAt;
        uint256 discount = discountRate * timeElapsed;

        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp <= expiresAt, "expired");
        uint256 price = getPrice();

        require(msg.value >= price, "wrong price");

        nft.transferFrom(seller, msg.sender, nftId);

        uint256 refund = msg.value - price;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        selfdestruct(seller);
    }
}
