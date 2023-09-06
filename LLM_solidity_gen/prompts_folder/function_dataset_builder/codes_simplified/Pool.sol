// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './access/roles/Admin.sol';
import './access/roles/Dao.sol';
import './interfaces/IERC20Detailed.sol';

/// @notice DETF pool smart contract
/// @author D-ETF.com
/// @dev The Pool contract keeps all underlaying tokens of DETF token.
/// Contract allowed to do swaps and change the ratio of the underlaying token, after governance contract approval.
contract Pool is AdminRole, DaoRole {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;

    address public oneInchAddr;

    address internal constant _ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant _ETH_DECIMALS = 18;
    uint256 internal constant _MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant _MAX_DECIMALS = 18;
    uint256 internal constant _PRECISION = (10**18);

    event Swapped(address srcToken, address destToken, uint256 actSrcAmount, uint256 actDestAmount);
    event Transferred(address asset, address receiver, uint256 amount);

<FUNCTION_DELIMINATOR_JINAN789>
    constructor (address oneInchAddr_) {
        require(oneInchAddr_ != address(0), "Pool: Invalid 1inch address!");
        oneInchAddr = oneInchAddr_;
    }


<FUNCTION_DELIMINATOR_JINAN789>
    function swap(
        address srcToken,
        uint256 srcAmount,
        uint256 minPrice,
        uint256 maxPrice,
        address destToken,
        bytes memory oneInchData
    ) public onlyDao returns (
        uint256 actualDestAmount,
        uint256 actualSrcAmount
    ) {
        require(minPrice < maxPrice, "swap: Incorrect min/max prices!");
        require(srcToken != destToken, "swap: Incorrect path of swap!");

        uint256 dInS; // price of dest token denominated in src token
        uint256 sInD; // price of src token denominated in dest token

        // 1inch trading
        (
            dInS,
            sInD,
            actualDestAmount,
            actualSrcAmount
        ) = _oneInchTrade(
            srcToken,
            srcAmount,
            destToken,
            oneInchData
        );
        
        // NOTE: Slippage is the part of 1Inch data.
        // require(minPrice <= dInS && dInS <= maxPrice, "swap: Incorrect min/max output!");

        emit Swapped(srcToken, destToken, actualSrcAmount, actualDestAmount);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function transfer(address token, address receiver, uint256 amount) public onlyAdmin {
        if (token == _ETH_ADDRESS) {
            (bool success, ) = receiver.call{value: amount}("");
            require(success, "transfer: Failed to send Ether!");
        }

        IERC20Detailed(token).safeTransfer(receiver, amount);

        emit Transferred(token, receiver, amount);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function updateOneInchAddress(address newOneInch) public onlyAdmin {
        require(newOneInch != address(0), "updateOneInchAddress: Invalid oneInch address!");

        oneInchAddr = newOneInch;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function getPoolBalance(address asset) public view returns (uint256) {
        return _getBalance(asset, address(this));
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _oneInchTrade(
        address _srcToken,
        uint256 _srcAmount,
        address _destToken,
        bytes memory _calldata
    )
        internal
        returns (
            uint256 _destPriceInSrc,
            uint256 _srcPriceInDest,
            uint256 _actualDestAmount,
            uint256 _actualSrcAmount
        )
    {
        uint256 beforeSrcBalance = _getBalance(_srcToken, address(this));
        uint256 beforeDestBalance = _getBalance(_destToken, address(this));
        // Note: _actualSrcAmount is being used as msgValue here, because otherwise we'd run into the stack too deep error
        if (_srcToken != _ETH_ADDRESS) {
            _actualSrcAmount = 0;
            IERC20Detailed(_srcToken).approve(oneInchAddr, 0);
            IERC20Detailed(_srcToken).approve(oneInchAddr, _srcAmount);
        } else {
            _actualSrcAmount = _srcAmount;
        }

        // trade through 1inch proxy
        (bool success, ) = oneInchAddr.call{value: _actualSrcAmount}(_calldata);
        require(success, "_oneInchTrade: External 1inch issue!");

        // calculate trade amounts and price
        _actualDestAmount = _getBalance(_destToken, address(this)).sub(
            beforeDestBalance
        );
        _actualSrcAmount = beforeSrcBalance.sub(
            _getBalance(_srcToken, address(this))
        );
        require(_actualDestAmount > 0 && _actualSrcAmount > 0);
        _destPriceInSrc = _calcRateFromQty(
            _actualDestAmount,
            _actualSrcAmount,
            _getDecimals(_destToken),
            _getDecimals(_srcToken)
        );
        _srcPriceInDest = _calcRateFromQty(
            _actualSrcAmount,
            _actualDestAmount,
            _getDecimals(_srcToken),
            _getDecimals(_destToken)
        );
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= _MAX_QTY && destAmount <= _MAX_QTY, "_calcRateFromQty: More then allowed max!");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= _MAX_DECIMALS);
            return ((destAmount * _PRECISION) /
                ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= _MAX_DECIMALS);
            return ((destAmount *
                _PRECISION *
                (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _getBalance(address token, address addr)
        internal
        view
        returns (uint256)
    {
        if (token == _ETH_ADDRESS) {
            return uint256(addr.balance);
        }

        return uint256(IERC20Detailed(token).balanceOf(addr));
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _getDecimals(address token) internal view returns (uint256) {
        if (token == _ETH_ADDRESS) {
            return uint256(_ETH_DECIMALS);
        }

        return uint256(IERC20Detailed(token).decimals());
    }
}