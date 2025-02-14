// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    uint256 constant ENTRY_FEE = 1 ether;
    uint256 constant INTERVAL_BETWEEN_DRAWS = 5 minutes;
    uint8 constant NUMBERS_LENGTH = 6;
    uint8 constant MIN_NUMBER = 1;
    uint8 constant MAX_NUMBER = 49;
    uint8 constant LOTTO_TAX_PERCENT = 5;

    uint256 constant SUBSCRIPTION_ID = 0;
    address constant VRF_COORDINATOR = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B; // Mock address
    bytes32 constant KEY_HASH = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;  // Mock Hash
    uint32 constant CALLBACK_GAS_LIMIT = 40000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS =  10;
}

contract HelperConfig is Script, CodeConstants {
    struct NetworkConfig {
        uint256 entryFee;
        uint256 intervalBetweenDraws;
        uint8 numbersLength;
        uint8 maxNumber;
        uint8 minNumber;
        uint8 lottoTaxPercent;
    }

    mapping(uint256 networkId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
        networkConfigs[LOCAL_CHAIN_ID] = getOrCreateAnvilNetworkConfig();
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return networkConfigs[block.chainid];
    }

    function getSepoliaNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryFee: ENTRY_FEE,
            intervalBetweenDraws: INTERVAL_BETWEEN_DRAWS,
            numbersLength: NUMBERS_LENGTH,
            maxNumber: MAX_NUMBER,
            minNumber: MIN_NUMBER,
            lottoTaxPercent: LOTTO_TAX_PERCENT
        });
    }

    function getOrCreateAnvilNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entryFee: ENTRY_FEE,
            intervalBetweenDraws: INTERVAL_BETWEEN_DRAWS,
            numbersLength: NUMBERS_LENGTH,
            maxNumber: MAX_NUMBER,
            minNumber: MIN_NUMBER,
            lottoTaxPercent: LOTTO_TAX_PERCENT
        });
    }
}
