pragma solidity ^0.8.5;

contract MultiRewarderPerSec {

    /// @notice Info of the rewardInfo.
    uint256[] public rewardInfo;

    function updateReward(uint256 totalShare) internal {

            uint256 length = rewardInfo.length;
            for (uint256 i; i < length; ++i) {
                uint256 reward = rewardInfo[i];
                
            }

    }
}