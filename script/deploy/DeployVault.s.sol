// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC4626 } from "openzeppelin/interfaces/IERC4626.sol";
import { ERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import { ud2x18 } from "prb-math/UD2x18.sol";
import { SD59x18, convert } from "prb-math/SD59x18.sol";
import { sd1x18 } from "prb-math/SD1x18.sol";

import { TwabController } from "pt-v5-twab-controller/TwabController.sol";
import { Claimer } from "pt-v5-claimer/Claimer.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { LiquidationPair } from "pt-v5-cgda-liquidator/LiquidationPair.sol";
import { LiquidationPairFactory } from "pt-v5-cgda-liquidator/LiquidationPairFactory.sol";
import { LiquidationRouter } from "pt-v5-cgda-liquidator/LiquidationRouter.sol";
import { PrizePool, SD59x18 } from "pt-v5-prize-pool/PrizePool.sol";
import { Vault } from "pt-v5-vault/Vault.sol";
import { VaultFactory } from "pt-v5-vault/VaultFactory.sol";

import { ScriptHelpers } from "../helpers/ScriptHelpers.sol";

contract DeployVault is ScriptHelpers {
  function _deployVault(
    IERC4626 _yieldVault,
    uint104 _virtualReserveOut
  ) internal returns (Vault vault) {
    ERC20 _underlyingAsset = ERC20(_yieldVault.asset());

    PrizePool prizePool = _getPrizePool();

    // TODO: check if VaultFactory has already been deployed
    VaultFactory vaultFactory = new VaultFactory();

    address _vaultAddress = vaultFactory.deployVault(
      _underlyingAsset,
      string.concat("PoolTogether ", _underlyingAsset.name(), " Prize Token"),
      string.concat("PT", _underlyingAsset.symbol(), "T"),
      _getTwabController(),
      _yieldVault,
      prizePool,
      address(_getClaimer()),
      address(0), // Yield fee recipient
      YIELD_FEE_PERCENTAGE,
      EXECUTIVE_TEAM_OPTIMISM_ADDRESS
    );

    vault = Vault(_vaultAddress);

    vault.setLiquidationPair(_createPair(prizePool, vault, _virtualReserveOut));
  }

  function _createPair(
    PrizePool _prizePool,
    Vault _vault,
    uint104 _virtualReserveOut
  ) internal returns (LiquidationPair pair) {
    uint32 _drawPeriodSeconds = _prizePool.drawPeriodSeconds();

    pair = _getLiquidationPairFactory().createPair(
      ILiquidationSource(_vault),
      address(_getToken("POOL")),
      address(_vault),
      _drawPeriodSeconds,
      uint32(_prizePool.firstDrawStartsAt()),
      _getTargetFirstSaleTime(_drawPeriodSeconds),
      _getDecayConstant(),
      VIRTUAL_RESERVE_IN,
      _virtualReserveOut,
      _virtualReserveOut
    );
  }

  function run() public {
    vm.startBroadcast();

    /* USDC */
    _deployVault(_getAaveV3YieldVault(OPTIMISM_USDC_ADDRESS), _getExchangeRate(USDC_PRICE, 12));

    /* wETH */
    _deployVault(_getAaveV3YieldVault(OPTIMISM_WETH_ADDRESS), _getExchangeRate(ETH_PRICE, 0));

    vm.stopBroadcast();
  }
}
