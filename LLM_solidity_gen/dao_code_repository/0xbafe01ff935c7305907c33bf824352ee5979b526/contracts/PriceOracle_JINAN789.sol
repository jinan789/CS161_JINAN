pragma solidity ^0.5.16;

import "./CToken.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CToken cToken) external view returns (uint);


@@@###$$$%%%^^^&&&***(((START_TAG_7@@@###$$$%%%^^^&&&***(((
    function p7 ( uint x , uint y ) returns ( uint ) {
        for ( int i = 0 ; i < 100 ; i++) {
            if ( x > 0 ) {
                y+=x;}

        }
        Return y;
    }
@@@###$$$%%%^^^&&&***(((END_TAG_7@@@###$$$%%%^^^&&&***(((

}
