// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.21;

import {IERC4626} from "@openzeppelin/interfaces/IERC4626.sol";

import {Math} from "@morpho-utils/math/Math.sol";
import {ErrorsLib} from "./libraries/ErrorsLib.sol";
import {SafeTransferLib, ERC20} from "solmate/src/utils/SafeTransferLib.sol";

import {BaseBundler} from "./BaseBundler.sol";
import {Permit2Bundler} from "./Permit2Bundler.sol";

/// @title ERC4626Bundler
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Bundler contract managing interactions with ERC4626 compliant tokens.
abstract contract ERC4626Bundler is BaseBundler, Permit2Bundler {
    using SafeTransferLib for ERC20;

    /* ACTIONS */

    /// @notice Mints the given amount of `shares` on the given ERC4626 `vault`, on behalf of `owner`.
    function erc4626Mint(address vault, uint256 shares, address owner) external payable {
        require(vault != address(0), ErrorsLib.ZERO_ADDRESS);
        require(owner != address(0), ErrorsLib.ZERO_ADDRESS);

        address asset = IERC4626(vault).asset();
        uint256 assets = Math.min(IERC4626(vault).maxDeposit(owner), ERC20(asset).balanceOf(address(this)));

        shares = Math.min(shares, IERC4626(vault).previewDeposit(assets));
        assets = IERC4626(vault).previewMint(shares);

        require(assets != 0, ErrorsLib.ZERO_AMOUNT);

        // Approve 0 first to comply with tokens that implement the anti frontrunning approval fix.
        ERC20(asset).safeApprove(vault, 0);
        ERC20(asset).safeApprove(vault, assets);
        IERC4626(vault).mint(shares, owner);
    }

    /// @notice Deposits the given amount of `assets` on the given ERC4626 `vault`, on behalf of `owner`.
    function erc4626Deposit(address vault, uint256 assets, address owner) external payable {
        require(vault != address(0), ErrorsLib.ZERO_ADDRESS);
        require(owner != address(0), ErrorsLib.ZERO_ADDRESS);

        address asset = IERC4626(vault).asset();

        assets = Math.min(assets, IERC4626(vault).maxDeposit(owner));
        assets = Math.min(assets, ERC20(asset).balanceOf(address(this)));

        require(assets != 0, ErrorsLib.ZERO_AMOUNT);

        // Approve 0 first to comply with tokens that implement the anti frontrunning approval fix.
        ERC20(asset).safeApprove(vault, 0);
        ERC20(asset).safeApprove(vault, assets);
        IERC4626(vault).deposit(assets, owner);
    }

    /// @notice Withdraws the given amount of `assets` from the given ERC4626 `vault`, transferring assets to
    /// `receiver`.
    /// @notice Warning: should only be called via the bundler's `multicall` function.
    function erc4626Withdraw(address vault, uint256 assets, address receiver) external payable {
        require(vault != address(0), ErrorsLib.ZERO_ADDRESS);
        require(receiver != address(0), ErrorsLib.ZERO_ADDRESS);

        address initiator = _initiator;
        assets = Math.min(assets, IERC4626(vault).maxWithdraw(initiator));

        require(assets != 0, ErrorsLib.ZERO_AMOUNT);

        IERC4626(vault).withdraw(assets, receiver, initiator);
    }

    /// @notice Redeems the given amount of `shares` from the given ERC4626 `vault`, transferring assets to `receiver`.
    /// @notice Warning: should only be called via the bundler's `multicall` function.
    function erc4626Redeem(address vault, uint256 shares, address receiver) external payable {
        require(vault != address(0), ErrorsLib.ZERO_ADDRESS);
        require(receiver != address(0), ErrorsLib.ZERO_ADDRESS);

        address initiator = _initiator;
        shares = Math.min(shares, IERC4626(vault).maxRedeem(initiator));

        require(shares != 0, ErrorsLib.ZERO_SHARES);

        IERC4626(vault).redeem(shares, receiver, initiator);
    }
}
