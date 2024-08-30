// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { console2 } from "forge-std/console2.sol";

import { Test } from "forge-std/Test.sol";
import { PrizeVaultAddressBook, ERC20, TpdaLiquidationPair, IRewardsController, PrizePool } from "../script/DeployAaveV3PrizeVault.s.sol";

interface Rewards {
    function getRewardsByAsset(address asset) external view returns (address[] memory);
}

/// @notice Runs some basic fork tests against a deployment
contract PrizeVaultPostDeployTest is Test {

    uint256 deployFork;
    PrizeVaultAddressBook addressBook;
    address alice;

    constructor() {
        deployFork = vm.createFork(vm.envString("SCRIPT_RPC_URL"));
        addressBook = abi.decode(
            vm.parseBytes(
                vm.readFile(
                    string.concat("config/addressBook.txt")
                )
            ),
            (PrizeVaultAddressBook)
        );
    }
    
    function setUp() public {
        vm.selectFork(deployFork);
        alice = makeAddr("Alice");
    }

    function testAddressBook() public view {
        assertNotEq(address(0), address(addressBook.prizeVault));
        assertNotEq(address(0), address(addressBook.yieldVault));
        assertNotEq(address(0), address(addressBook.rewardLiquidator));
    }

    function testContractConnections() public view {
        assertEq(address(addressBook.prizeVault.yieldVault()), address(addressBook.yieldVault));
        assertEq(addressBook.yieldVault.rewardRecipient(), address(addressBook.rewardLiquidator));
        assertEq(addressBook.rewardLiquidator.vaultBeneficiary(), address(addressBook.prizeVault));
    }

    function testDepositAndWithdrawWithYield() public {
        ERC20 asset = ERC20(addressBook.prizeVault.asset());
        uint256 amount = 10 ** asset.decimals();
        uint256 maxAmount = asset.balanceOf(address(addressBook.aToken));
        assertGt(maxAmount, 1);
        if (amount >= maxAmount) amount = maxAmount / 2;

        // The aToken address should hold lots of the asset, so we can spoof that address as our "dealer"
        vm.startPrank(address(addressBook.aToken));
        asset.transfer(alice, amount);
        vm.stopPrank();

        assertEq(asset.balanceOf(alice), amount);

        // Test deposit and withdraw
        vm.startPrank(alice);
        asset.approve(address(addressBook.prizeVault), amount);
        uint256 shares = addressBook.prizeVault.deposit(amount, alice);
        vm.stopPrank();
        assertEq(shares, amount); // 1:1

        // Let yield accrue over time
        uint256 totalAssetsBefore = addressBook.prizeVault.totalAssets();
        assertApproxEqAbs(totalAssetsBefore, amount + addressBook.prizeVault.yieldBuffer(), 1);
        vm.warp(block.timestamp + 10 days);
        uint256 totalAssetsAfter = addressBook.prizeVault.totalAssets();
        assertGt(totalAssetsAfter, totalAssetsBefore);

        // Withdraw full amount
        assertEq(addressBook.prizeVault.balanceOf(alice), amount);
        vm.startPrank(alice);
        uint256 assets = addressBook.prizeVault.redeem(amount, alice, alice);
        vm.stopPrank();
        assertEq(assets, amount);

        // Test that yield still exists in prize vault
        assertGt(addressBook.prizeVault.totalAssets(), totalAssetsBefore - amount);
        assertGt(addressBook.prizeVault.liquidatableBalanceOf(address(addressBook.prizeVault)), 0);
    }

    function testAaveRewardLp() public {
        // spoof `asset` rewards to the yield vault and test that the LP picks them up
        ERC20 asset = ERC20(addressBook.prizeVault.asset());
        uint256 amount = 10 ** asset.decimals();
        uint256 maxAmount = asset.balanceOf(address(addressBook.aToken));
        assertGt(maxAmount, 1);
        if (amount >= maxAmount) amount = maxAmount / 2;

        // The aToken address should hold lots of the asset, so we can spoof that address as our "dealer"
        vm.startPrank(address(addressBook.aToken));
        asset.transfer(address(addressBook.rewardLiquidator), amount);
        vm.stopPrank();

        // Create new reward LP
        TpdaLiquidationPair aaveRewardLp = addressBook.rewardLiquidator.initializeRewardToken(address(asset));

        // Check if rewards are picked up
        address[] memory rewardsList = new address[](1);
        rewardsList[0] = address(asset);
        uint256[] memory claimedAmounts = new uint256[](1);
        claimedAmounts[0] = amount;
        vm.mockCall(
            address(addressBook.yieldVault.rewardsController()),
            abi.encodeWithSelector(IRewardsController.claimAllRewards.selector),
            abi.encode(rewardsList, claimedAmounts)
        );
        uint256 liquid = addressBook.rewardLiquidator.liquidatableBalanceOf(address(asset));
        assertEq(liquid, amount);

        // Check if LP can liquidate
        vm.warp(block.timestamp + aaveRewardLp.targetAuctionPeriod());
        uint256 maxAmountOut = aaveRewardLp.maxAmountOut();
        assertGt(maxAmountOut, 0);
        assertLe(maxAmountOut, amount);
        assertApproxEqAbs(aaveRewardLp.computeExactAmountIn(maxAmountOut), uint256(aaveRewardLp.lastAuctionPrice()), 1);
    }

    function testExistingRewards() public {
        // deposit and let rewards accrue
        address asset = addressBook.prizeVault.asset();
        uint256 depositAmount = 10000 * 10 ^ ERC20(asset).decimals();
        deal(asset, alice, depositAmount);
        vm.startPrank(alice);
        ERC20(asset).approve(address(addressBook.prizeVault), depositAmount);
        addressBook.prizeVault.deposit(depositAmount, alice);
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days);

        // get the current rewards
        address[] memory rewardTokens = Rewards(address(addressBook.yieldVault.rewardsController())).getRewardsByAsset(address(addressBook.aToken));

        // set up lp pairs for each reward
        for (uint i = 0; i < rewardTokens.length; i++) {
            TpdaLiquidationPair aaveRewardLp = addressBook.rewardLiquidator.initializeRewardToken(address(rewardTokens[i]));

            uint256 liquid = addressBook.rewardLiquidator.liquidatableBalanceOf(rewardTokens[i]);
            assertEq(liquid, ERC20(rewardTokens[i]).balanceOf(address(addressBook.rewardLiquidator)));
            if (liquid > 0) {
                
                // Check if LP can liquidate
                vm.warp(block.timestamp + aaveRewardLp.targetAuctionPeriod());
                uint256 maxAmountOut = aaveRewardLp.maxAmountOut();
                assertGt(maxAmountOut, 0);
                uint256 exactAmountIn = aaveRewardLp.computeExactAmountIn(maxAmountOut);
                assertApproxEqAbs(exactAmountIn, uint256(aaveRewardLp.lastAuctionPrice()), 1);

                // liquidate
                PrizePool prizePool = addressBook.prizeVault.prizePool();
                ERC20 prizeToken = ERC20(address(prizePool.prizeToken()));
                deal(address(prizeToken), alice, exactAmountIn);
                prizeToken.approve(address(addressBook.lpRouter), exactAmountIn);
                uint256 amountIn = addressBook.lpRouter.swapExactAmountOut(
                    aaveRewardLp,
                    alice,
                    maxAmountOut,
                    exactAmountIn,
                    block.timestamp
                );
                assertEq(amountIn, exactAmountIn);
                assertEq(ERC20(rewardTokens[i]).balanceOf(alice), maxAmountOut);
                uint24 openDrawId = prizePool.getOpenDrawId();
                assertEq(prizePool.getContributedBetween(address(addressBook.prizeVault), openDrawId, openDrawId), exactAmountIn);
            }
        }
    }

}