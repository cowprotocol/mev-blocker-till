all    :; dapp build
clean  :; dapp clean
test   :; forge test
deploy = OWNER=$(owner) forge script 'src/MevblockerFeeTill.s.sol:Deploy' -vvvv --rpc-url $(rpc-url) --private-key $(private-key)
deploy-dry-run :; $(deploy)
deploy :; $(deploy) --broadcast --verify --etherscan-api-key $(etherscan_api_key)
verify :; forge verify-contract --watch --rpc-url $(rpc-url) --etherscan-api-key $(etherscan_api_key) --constructor-args $$(cast abi-encode 'f(address)' $(owner)) -- $(address) 'src/MevblockerFeeTill.sol:MevBlockerFeeTill'
