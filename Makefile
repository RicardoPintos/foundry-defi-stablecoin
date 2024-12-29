-include .env

.PHONY: build test fork install deploy anvil sepolia

build :; forge build

test :; forge test

install :; forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit

deploy-anvil:
	@forge script script/DeployDSC.s.sol:DeployDSC --rpc-url $(LOCAL_RPC_URL) --account anvilKey --broadcast -vvvv

deploy-sepolia:
	@forge script script/DeployDSC.s.sol:DeployDSC --rpc-url $(SEPOLIA_RPC_URL) --account testKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv