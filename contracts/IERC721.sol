//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _nftId
    ) external;
}
