//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;

    function transfer(address _to, uint256 _value) external;
}
