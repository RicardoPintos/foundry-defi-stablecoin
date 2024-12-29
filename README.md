# Foundry DEFI Stablecoin

With this Foundry project you can create a stablecoin with these properties:

- **Relative Stability**: Anchored to the USD.
- **Stability Mechanism**: Algorithmic. 200% Overcollateralized.
- **Collateral Location**: Exogenous. wETH and wBTC.

<br>

It was made for the Advanced Foundry course of Cyfrin Updraft.

<br>

- [Foundry DEFI Stablecoin](#foundry-defi-stablecoin)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Libraries](#libraries)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
  - [Estimate gas](#estimate-gas)
  - [Formatting](#formatting)
- [Deploy](#deploy)
  - [Private Key Encryption](#private-key-encryption)
  - [Deployment to local Anvil](#deployment-to-local-anvil)
  - [Deployment to Sepolia testnet](#deployment-to-sepolia-testnet)
- [Acknowledgments](#acknowledgments)
- [Thank you](#thank-you)

<br>

![EthereumBanner](https://github.com/user-attachments/assets/8a1c6e53-2e66-4256-9312-252a0360b7df)

<br>

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```
git clone https://github.com/RicardoPintos/foundry-defi-stablecoin
cd foundry-defi-stablecoin
forge build
```

<br>

# Usage

## Libraries

This project uses the following libraries:

- [Chainlink-brownie-contracts (version 0.6.1)](https://github.com/smartcontractkit/chainlink-brownie-contracts)
- [Openzeppelin-contracts (version 4.8.3)](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Foundry-forge-std (version 1.8.2)](https://github.com/foundry-rs/forge-std)

You can install all of them with the following Makefile command:

```
make install
```

## Testing

To run every test:

```
forge test
```

**NOTICE:** This project has invariants testing, so after running `forge test` it will take longer than usual to finish. You can modify the runs and depth of the invariants test on the `foundry.toml`.

### Test Coverage

To check the test coverage of this project, run:

```
forge coverage
```

This is the current coverage of the tests:

![forgeCoverage](https://github.com/user-attachments/assets/2460b414-bcf8-4254-9b25-777353174fe9)

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

## Formatting

To run code formatting:

```
forge fmt
```

<br>

# Deploy

## Private Key Encryption

It is recommended to work with encrypted private keys for both Anvil and Sepolia. The following method is an example for Anvil. If you want to deploy to Sepolia, repeat this process with the private key and address of your **test wallet**.

In your local terminal, run this:

```
cast wallet import <Choose_Your_Anvil_Account_Name> --interactive
```

Paste your private key, hit enter and then create a password for that key. 

<br>

**NOTICE:** If you use the **first** Anvil private key there is no need to modify the code. If you use a different Anvil key, you'll need to modify the `anvilAccount` variable in the HelperConfig.s.sol contract. If you want to deploy to Sepolia, you'll need to change the `sepoliaAccount` variable of that contract to the address of your **test** wallet.

<br>

Now, you can use the `--account` flag instead of `--private-key`. You'll need to type your password when is needed. To check all of your encrypted keys, run this:

```
cast wallet list
```

<br>

## Deployment to local Anvil

First you need to run Anvil on your terminal:

```
anvil
```

Then you open another terminal and run this:

```
forge script script/DeployDSC.s.sol:DeployDSC --rpc-url http://127.0.0.1:8545 --account <Your_Encrypted_Anvil_Private_Key_Account_Name> --broadcast -vvvv
```

## Deployment to Sepolia testnet

To deploy to Sepolia run this:

```
forge script script/DeployDSC.s.sol:DeployDSC --rpc-url <Your_Alchemy_Sepolia_Node_Url> --account <Your_Encrypted_Sepolia_Private_Key_Account_Name> --broadcast -vvvv
```

If you have an Etherscan API key, you can verify your contract alongside the deployment by running this instead:

```
forge script script/DeployDSC.s.sol:DeployDSC --rpc-url <Your_Alchemy_Sepolia_Node_Url> --account <Your_Encrypted_Sepolia_Private_Key_Account_Name> --broadcast --verify --etherscan-api-key <Your_Etherscan_Api_Key> -vvvv
```

# Acknowledgments

Thanks to the Cyfrin Updraft team and to Patrick Collins for their amazing work. Please check out their courses on [Cyfrin Updraft](https://updraft.cyfrin.io/courses).

<br>

# Thank you

If you appreciated this, feel free to follow me!

[![Ricardo Pintos Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=x&logoColor=white)](https://x.com/pintosric)
[![Ricardo Pintos Linkedin](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ricardo-mauro-pintos/)
[![Ricardo Pintos YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@PintosRic)