// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IUniversalRewardsDistributor} from "@universal-rewards-distributor/interfaces/IUniversalRewardsDistributor.sol";

import {ErrorsLib} from "./libraries/ErrorsLib.sol";

import {BaseBundler} from "./BaseBundler.sol";

/// @title URDBudnler
/// @author Morpho Labs
/// @custom:contact security@morpho.xyz
/// @notice Bundler that allows to claim token rewards on the Universal Rewards Distributor.
contract URDBundler is BaseBundler {
    IUniversalRewardsDistributor public immutable URD;

    constructor(address urd) {
        require(urd != address(0), ErrorsLib.ZERO_ADDRESS);

        URD = IUniversalRewardsDistributor(urd);
    }

    function claim(uint256 distributionId, address account, address reward, uint256 claimable, bytes32[] calldata proof)
        external
        payable
    {
        require(account != address(0), ErrorsLib.ZERO_ADDRESS);
        require(account != address(this), ErrorsLib.BUNDLER_ADDRESS);

        URD.claim(distributionId, account, reward, claimable, proof);
    }
}
