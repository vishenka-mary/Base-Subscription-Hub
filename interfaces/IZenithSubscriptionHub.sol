// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IZenithSubscriptionHub {
    function buySubscription(uint256 tierId) external payable;
    function subscriptionExpiry(uint256 tierId, address user) external view returns (uint256);
}
