all    :; dapp build
clean  :; dapp clean
test   :; forge test
deploy = OWNER=$(owner) forge script 'src/MevblockerFeeTill.s.sol:Deploy' -vvvv --rpc-url $(rpc-url) --private-key $(private-key)
deploy-dry-run :; $(deploy)
deploy :; $(deploy) --broadcast --verify --etherscan-api-key $(etherscan_api_key)
