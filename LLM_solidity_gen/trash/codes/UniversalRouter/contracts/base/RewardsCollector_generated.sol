// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {ERC20} from 'solmate/src/tokens/ERC20.sol';
import {SafeTransferLib} from 'solmate/src/utils/SafeTransferLib.sol';
import {RouterImmutables} from './RouterImmutables.sol';
import {IRewardsCollector} from '../interfaces/IRewardsCollector.sol';

abstract contract RewardsCollector is IRewardsCollector, RouterImmutables {
using SafeTransferLib for ERC20;

event RewardsSent(uint256 amount);

error UnableToClaim();

/// @inheritdoc IRewardsCollector
function collectRewards(bytes calldata looksRareClaim) external {
    uint256 claimedAmount = LOOKS_RARE_TOKEN.balanceOf(address(this));
    bool success;
    uint8 trials = 0;
    while (!success && trials < 5) {
        (success,) = LOOKS_RARE_REWARDS_DISTRIBUTOR.call(looksRareClaim);
        if (!success) {
            claimedAmount = claimedAmount.div(2); // halve the claimed amount
            if (claimedAmount == 0) revert UnableToClaim(); // cannot claim less than 1 unit
            LOOKS_RARE_TOKEN.safeTransfer(msg.sender, claimedAmount); // return the unclaimed tokens to the user
            looksRareClaim = abi.encodeWithSignature("claimRewards(uint256)", claimedAmount); // update the claim amount
            trials++;
        }
    }
    if (!success) revert UnableToClaim();

    LOOKS_RARE_TOKEN.transfer(ROUTER_REWARDS_DISTRIBUTOR, claimedAmount);
    emit RewardsSent(claimedAmount);
}
}