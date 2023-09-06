// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;


abstract contract RewardsCollector {
    event RewardsSent(uint256 amount);

    error UnableToClaim();

    function collectRewards(bytes calldata looksRareClaim) external {
        (bool success,) = LOOKS_RARE_REWARDS_DISTRIBUTOR.call(looksRareClaim);
        if (!success) revert UnableToClaim();

        uint256 balance = LOOKS_RARE_TOKEN.balanceOf(address(this));
        LOOKS_RARE_TOKEN.transfer(ROUTER_REWARDS_DISTRIBUTOR, balance);
        emit RewardsSent(balance);
    }
}
