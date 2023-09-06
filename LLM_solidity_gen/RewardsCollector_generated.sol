pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "input_codes/interfaces/IRewardsCollector.sol";
import "input_codes/RewardsCollector.sol";
import "input_codes/solmate/src/utils/SafeTransferLib.sol";

contract ProportionalRewardDistributor {
    using SafeTransferLib for IERC20;

    address public rewardsCollector;

    constructor(address _rewardsCollector) {
        rewardsCollector = _rewardsCollector;
    }

    event ProportionalRewardsDistributed(address[] receivers, uint256[] proportions, uint256 totalAmount);

    function claimAndDistributeRewards(bytes calldata looksRareClaim, address[] calldata receivers, uint256[] calldata proportions) external {
        require(receivers.length == proportions.length, "Mismatched input lengths");

        // Collect rewards from LooksRare rewards distributor
        IRewardsCollector(rewardsCollector).collectRewards(looksRareClaim);

        // Get the token
        IERC20 token = IERC20(RewardsCollector(rewardsCollector).rewardToken());

        // Calculate total proportions
        uint256 totalProportions = 0;
        for (uint256 i = 0; i < proportions.length; i++) {
            totalProportions += proportions[i];
        }

        // Distribute rewards proportionally
        uint256 totalAmount = token.balanceOf(address(this));
        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 receiverAmount = totalAmount * proportions[i] / totalProportions;
            token.safeTransfer(receivers[i], receiverAmount);
        }

        emit ProportionalRewardsDistributed(receivers, proportions, totalAmount);
    }
}