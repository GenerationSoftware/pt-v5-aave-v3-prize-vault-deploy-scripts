// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/console2.sol";

import { ScriptBase } from "./ScriptBase.sol";

import { RewardLiquidatorFactory } from "pt-v5-yield-daddy-liquidators/RewardLiquidatorFactory.sol";

contract DeployRewardLiquidatorFactory is ScriptBase {

    function run() public virtual {
        vm.startBroadcast();

        console2.log("Deploying Aave V3 ERC4626 Reward Liquidator Factory...");
        RewardLiquidatorFactory factory = new RewardLiquidatorFactory();
        console2.log("Deployed Address: ", address(factory));

        vm.stopBroadcast();
    }

}
