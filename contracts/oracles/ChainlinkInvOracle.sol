// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseOracle} from "./BaseOracle.sol";
import {StaticCollateralAdapter} from "./adapters/StaticCollateralAdapter.sol";
import {ChainlinkBorrowableAdapter} from "./adapters/ChainlinkBorrowableAdapter.sol";

contract ChainlinkInvOracle is BaseOracle, StaticCollateralAdapter, ChainlinkBorrowableAdapter {
    constructor(uint256 scaleFactor, address feed, uint256 boundOffsetFactor)
        BaseOracle(scaleFactor)
        ChainlinkBorrowableAdapter(feed, boundOffsetFactor)
    {}
}
