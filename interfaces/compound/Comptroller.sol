// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Comptroller {
    function claimComp(address holder) external;
}
