pragma solidity ^0.5.16;

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}
