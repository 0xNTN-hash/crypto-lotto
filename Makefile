-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

clean  :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit && forge install transmissions11/solmate@v6 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.2.0 --no-commit

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy-anvil:
	@forge script script/DeployLotto.s.sol:DeployLotto --rpc-url $(ANVIL_RPC_URL) --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
