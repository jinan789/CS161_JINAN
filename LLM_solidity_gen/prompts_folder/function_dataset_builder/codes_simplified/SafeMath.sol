// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
<FUNCTION_DELIMINATOR_JINAN789>
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>s
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
