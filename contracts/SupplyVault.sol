// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

import {IPool} from "contracts/interfaces/IPool.sol";
import {ISupplyVault} from "contracts/interfaces/ISupplyVault.sol";
import {ISupplyRouter} from "contracts/interfaces/ISupplyRouter.sol";

import {PoolAddress} from "contracts/libraries/PoolAddress.sol";
import {BytesLib, POOL_OFFSET} from "contracts/libraries/BytesLib.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeTransferLib, ERC20 as ERC20Solmate} from "@solmate/utils/SafeTransferLib.sol";

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20, ERC20, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract SupplyVault is ISupplyVault, ERC4626, Ownable2Step {
    using SafeTransferLib for ERC20Solmate;
    using EnumerableSet for EnumerableSet.AddressSet;

    ISupplyRouter private immutable _ROUTER;

    address private _riskManager;

    Config private _config;

    constructor(address router, string memory name_, string memory symbol_, IERC20 asset_)
        ERC4626(asset_)
        ERC20(name_, symbol_)
    {
        _ROUTER = ISupplyRouter(router);
    }

    modifier onlyRiskManager() {
        _checkRiskManager();
        _;
    }

    /* EXTERNAL */

    function setCollateralEnabled(address collateral, bool enabled) external virtual onlyRiskManager {
        _setCollateralEnabled(collateral, enabled);
    }

    function reallocate(bytes calldata withdrawn, bytes calldata supplied) external virtual onlyRiskManager {
        _reallocate(withdrawn, supplied);
    }

    /* PUBLIC */

    function riskManager() public view virtual returns (address) {
        return _riskManager;
    }

    function config(address collateral) public view virtual returns (CollateralConfig memory) {
        return _collateralConfig(collateral);
    }

    /**
     * @dev See {IERC4626-totalAssets}.
     */
    function totalAssets() public view virtual override returns (uint256 assets) {
        EnumerableSet.AddressSet storage collaterals = _config.collaterals;

        uint256 nbCollaterals = collaterals.length();
        for (uint256 i; i < nbCollaterals; ++i) {
            address collateral = collaterals.at(i);
            CollateralConfig storage collateralConfig = _collateralConfig(collateral);

            assets += collateralConfig.pool.supplyBalanceOf(address(this), collateralConfig.bucket);
        }
    }

    /* INTERNAL */

    function _checkRiskManager() internal view virtual {
        if (riskManager() != _msgSender()) revert OnlyRiskManager();
    }

    function _collateralConfig(address collateral) internal view virtual returns (CollateralConfig storage) {
        return _config.collateralConfig[collateral];
    }

    function _setCollateralEnabled(address collateral, bool enabled) internal virtual {
        if (enabled) {
            _config.collaterals.add(collateral);

            ERC20Solmate(asset()).safeApprove(address(_ROUTER), type(uint256).max);
        } else {
            _config.collaterals.remove(collateral);
        }
    }

    function _reallocate(bytes calldata withdrawn, bytes calldata supplied) internal virtual {
        address _asset = asset();

        _ROUTER.withdraw(_asset, withdrawn, address(this));
        _ROUTER.supply(_asset, supplied, address(this));
    }
}
