// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Script } from "forge-std/Script.sol";
import { UD2x18, ud2x18 } from "prb-math/UD2x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";
import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { IPool, IRewardsController, AaveV3ERC4626, ERC20 } from "yield-daddy/aave-v3/AaveV3ERC4626.sol";

import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { TpdaLiquidationPairFactory, TpdaLiquidationPair } from "pt-v5-tpda-liquidator/TpdaLiquidationPairFactory.sol";
import { TpdaLiquidationRouter } from "pt-v5-tpda-liquidator/TpdaLiquidationRouter.sol";
import { RewardLiquidatorFactory, RewardLiquidator, IPrizePool } from "pt-v5-yield-daddy-liquidators/RewardLiquidatorFactory.sol";
import { PrizeVaultFactory, PrizeVault, IERC4626 } from "pt-v5-vault/PrizeVaultFactory.sol";
import { VaultBoosterFactory, VaultBooster } from "pt-v5-vault-boost/VaultBoosterFactory.sol";

struct Configuration {
    // LP Config
    TpdaLiquidationPairFactory lpFactory;
    uint64 prizeVaultLpTargetAuctionPeriod;
    uint192 prizeVaultLpTargetAuctionPrice;
    uint256 prizeVaultLpSmoothingFactor;

    // Reward LP Config
    RewardLiquidatorFactory aaveRewardLiquidatorFactory;
    uint64 aaveRewardLpTargetAuctionPeriod;
    uint192 aaveRewardLpTargetAuctionPrice;
    uint256 aaveRewardLpSmoothingFactor;

    // Yield Vault Config
    address yieldVaultComputedAddress;
    IPool aaveV3Pool;
    IRewardsController aaveV3RewardsController;
    ERC20 aaveV3Asset;

    // Prize Vault Config
    PrizePool prizePool;
    PrizeVaultFactory prizeVaultFactory;
    VaultBoosterFactory vaultBoosterFactory;
    address claimer;
    string prizeVaultName;
    string prizeVaultSymbol;
    address prizeVaultOwner;
    address prizeVaultYieldFeeRecipient;
    uint32 prizeVaultYieldFeePercentage;

    // LP Router
    TpdaLiquidationRouter lpRouter;
}

contract ScriptBase is Script {
    using SafeCast for uint256;

    function loadConfig(string memory filepath) internal view returns (Configuration memory config) {
        string memory file = vm.readFile(filepath);

        // LP Config
        config.lpFactory                    = TpdaLiquidationPairFactory(vm.parseJsonAddress(file, "$.lpFactory"));
        config.prizeVaultLpTargetAuctionPeriod        = vm.parseJsonUint(file, "$.prizeVaultLpTargetAuctionPeriod").toUint64();
        config.prizeVaultLpTargetAuctionPrice         = vm.parseJsonUint(file, "$.prizeVaultLpTargetAuctionPrice").toUint192();
        config.prizeVaultLpSmoothingFactor            = vm.parseJsonUint(file, "$.prizeVaultLpSmoothingFactor");

        // Reward LP Config
        config.aaveRewardLiquidatorFactory              = RewardLiquidatorFactory(vm.parseJsonAddress(file, "$.aaveRewardLiquidatorFactory"));
        config.aaveRewardLpTargetAuctionPeriod  = vm.parseJsonUint(file, "$.aaveRewardLpTargetAuctionPeriod").toUint64();
        config.aaveRewardLpTargetAuctionPrice   = vm.parseJsonUint(file, "$.aaveRewardLpTargetAuctionPrice").toUint192();
        config.aaveRewardLpSmoothingFactor      = vm.parseJsonUint(file, "$.aaveRewardLpSmoothingFactor");

        // Yield Vault Config
        config.yieldVaultComputedAddress    = vm.parseJsonAddress(file, "$.yieldVaultComputedAddress");
        config.aaveV3Pool                   = IPool(vm.parseJsonAddress(file, "$.aaveV3Pool"));
        config.aaveV3RewardsController      = IRewardsController(vm.parseJsonAddress(file, "$.aaveV3RewardsController"));
        config.aaveV3Asset                  = ERC20(vm.parseJsonAddress(file, "$.aaveV3Asset"));

        // Prize Vault
        config.prizePool                    = PrizePool(vm.parseJsonAddress(file, "$.prizePool"));
        config.prizeVaultFactory            = PrizeVaultFactory(vm.parseJsonAddress(file, "$.prizeVaultFactory"));
        config.vaultBoosterFactory          = VaultBoosterFactory(vm.parseJsonAddress(file, "$.vaultBoosterFactory"));
        config.claimer                      = vm.parseJsonAddress(file, "$.claimer");
        config.prizeVaultName               = vm.parseJsonString(file, "$.prizeVaultName");
        config.prizeVaultSymbol             = vm.parseJsonString(file, "$.prizeVaultSymbol");
        config.prizeVaultOwner              = vm.parseJsonAddress(file, "$.prizeVaultOwner");
        config.prizeVaultYieldFeeRecipient  = vm.parseJsonAddress(file, "$.prizeVaultYieldFeeRecipient");
        config.prizeVaultYieldFeePercentage = vm.parseJsonUint(file, "$.prizeVaultYieldFeePercentage").toUint32();

        // LP Router
        config.lpRouter                     = TpdaLiquidationRouter(vm.parseJsonAddress(file, "$.lpRouter"));
    }

}