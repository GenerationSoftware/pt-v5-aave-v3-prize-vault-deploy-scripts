# Aave V3 - Prize Vault Deployment Scripts

PoolTogether V5 production Aave V3 prize vault deployment scripts.

## Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Deployment](#deployment)

## Installation

### Dependencies

You may have to install the following tools to use this repository:

- [Node.js](https://nodejs.org/) to run scripts
- [yarn](https://yarnpkg.com/) to install node.js dependencies
- [Foundry](https://github.com/foundry-rs/foundry) to compile and test contracts
- [direnv](https://direnv.net/) (or a similar tool) to set environment variables

Install dependencies:

```
yarn install
```

### Env

Make a copy of `.envrc.example` and write down the env variables needed to run this project.

```
cp .envrc.example .envrc
```

Once your env variables are setup, load them with:

```
direnv allow
```

### Compile

Run the following command to compile the contracts:

```
yarn compile
```

## Configuration

Each Aave V3 prize vault deployment share some configuration parameters across each chain, but have some unique params that must be set on deployment time such as the prize vault name, symbol, owner, and deposit asset.

All chain-specific configurable parameters are located in the [config](./config/) folder and are separated by chain name. If the target chain does not have it's own configuration file, then a new one can be created an modified based on the deployment requirements.

All deployment-specific config parameters will be input on deployment through the CLI.

The following is a list of each final parameter (chain-specific and deployment-specific params).

--------------------------------------------------------------------------------

### `lpFactory`

The LP Factory is the TPDA Liquidation Pair factory that will be used to deploy the liquidation pair for the prize vault ***AND*** each reward liquidation pair that will be deployed through the associated reward liquidator.

--------------------------------------------------------------------------------

### `prizeVaultLpTargetAuctionPeriod`

This is the target liquidation frequency for the ***prize vault*** liquidations.

--------------------------------------------------------------------------------

### `prizeVaultLpTargetAuctionPrice`

This is the starting target liquidation price for the ***prize vault*** liquidations.

--------------------------------------------------------------------------------

### `prizeVaultLpSmoothingFactor`

This is the liquidation smoothing factor for the ***prize vault*** liquidations.

--------------------------------------------------------------------------------

### `aaveRewardLiquidatorFactory`

This is the `RewardLiquidatorFactory` contract that will be used to deploy a new reward liquidator for the new Aave yield vault.

--------------------------------------------------------------------------------

### `aaveRewardLpTargetAuctionPeriod`

This is the target liquidation frequency for the ***reward liquidations***.

--------------------------------------------------------------------------------

### `aaveRewardLpTargetAuctionPrice`

This is the starting target liquidation price for the ***reward liquidations***.

--------------------------------------------------------------------------------

### `aaveRewardLpSmoothingFactor`

This is the smoothing factor for the ***reward liquidations***.

--------------------------------------------------------------------------------

### `aaveV3Pool`

This is the the Aave `IPool` contract that will be used to generate yield with the deposit asset.

--------------------------------------------------------------------------------

### `aaveV3RewardsController`

This is the Aave rewards controller that will be used to harvest rewards for the yield vault.

--------------------------------------------------------------------------------

### `prizePool`

This is the prize pool that the prize vault will contribute to.

--------------------------------------------------------------------------------

### `prizeVaultFactory`

This is the factory that will be used to deploy the new prize vault.

--------------------------------------------------------------------------------

### `claimer`

This is the claimer contract that will be permitted to claim prizes for the prize vault.

--------------------------------------------------------------------------------

### `aaveV3Asset`

This is the deposit asset that will be used to generate yield on Aave V3.

--------------------------------------------------------------------------------

### `prizeVaultName`

This is the name of the new prize vault share token.

--------------------------------------------------------------------------------

### `prizeVaultSymbol`

This is the symbol of the new prize vault share token.

--------------------------------------------------------------------------------

### `prizeVaultOwner`

This is the owner of the new prize vault contract. Ownership will have to be accepted after the contract is deployed to complete the transfer from the deployer address.

--------------------------------------------------------------------------------

### `prizeVaultYieldFeePercentage`

This is the 9 decimal fraction that represents how much yield will be reserved for the yield fee recipient. 

--------------------------------------------------------------------------------

### `prizeVaultYieldFeeRecipient`

This is the address that will receive the accrued yield fee.

--------------------------------------------------------------------------------

## Deployment

To deploy a new prize vault, first ensure the following steps have been completed:

1. set relevant environment variables (RPC URLs, deployer address and private key, etherscan API key)
2. configure the chain-specific deployment parameters in a JSON file
3. deploy a new reward liquidator factory (if one does not exist on the target chain)
    1. Copy the `deploy:optimism:aaveRewardLiquidatorFactory` NPM script and modify it for your target chain before running the new script. Then set the reward liquidation factory param in the corresponding config JSON file.
4. Transfer at least 1e5 assets to the deployer address so they can be donated to the prize vault to fill the yield buffer on deployment. (Exactly 1e5 assets will be donated on deployment. These funds are not recoverable.)

### Deploy a New Prize Vault

To deploy a new prize vault and supporting contracts, first follow the steps above and then run the NPM command in the `package.json` file that corresponds to the chain you wish to deploy on. For example, to deploy on optimism, run `npm run deploy:optimism:prizeVault`.

If a script is not setup for your target chain, first create a new config file for the chain and then copy one of the existing NPM commands and modify it to match your desired configuration.

After deployment, contracts will automatically be verified on etherscan using your set etherscan API key for the relevant chain.
