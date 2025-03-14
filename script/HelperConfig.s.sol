// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    /* Mock VRF Values */
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE = 1e9;
    int256 public MOCK_WEI_PER_UNIT_LINK = 1e16;

    uint16 public REQUEST_CONFIRMATIONS = 3;
    uint32 public NUMBER_OF_WORDS = 10;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    uint256 constant ENTRY_FEE = 1 ether;
    uint256 constant INTERVAL_BETWEEN_DRAWS = 5 minutes;
    uint8 constant NUMBERS_LENGTH = 6;
    uint8 constant MIN_NUMBER = 1;
    uint8 constant MAX_NUMBER = 49;
    uint8 constant LOTTO_TAX_PERCENT = 5;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId(uint256 chainId);

    struct NetworkConfig {
        uint256 entryFee;
        uint8 lottoTaxPercent;
        uint256 subscriptionId;
        bytes32 gasLane;
        address vrfCoordinator;
        uint32 callbackGasLimit;
        address linkToken;
        uint16 requestConfirmations;
        uint32 numberOfWords;
        address account;
    }
    
    mapping(uint256 networkId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if(networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilNetworkConfig();
        } else {
            revert HelperConfig__InvalidChainId(chainId);
        }
    }

    function getConfig() public returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaNetworkConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryFee: 1 ether,
            lottoTaxPercent: LOTTO_TAX_PERCENT,
            subscriptionId: 34042810828593219769144622732293790626710322245458304082360765885856430959261,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            callbackGasLimit: 500000,
            numberOfWords: NUMBER_OF_WORDS,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x08392a7567C21d9E3CFAB81AA2CAe89a2D7285d7
        });
    }

    function getOrCreateAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if(networkConfigs[LOCAL_CHAIN_ID].vrfCoordinator != address(0)) {
            return networkConfigs[LOCAL_CHAIN_ID];
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_UNIT_LINK);
        LinkToken linkTokenMock = new LinkToken();
        vm.stopBroadcast();


        return NetworkConfig({
            entryFee: 1 ether,
            lottoTaxPercent: LOTTO_TAX_PERCENT,
            subscriptionId: 0,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            vrfCoordinator: address(vrfCoordinatorMock),
            numberOfWords: NUMBER_OF_WORDS,
            callbackGasLimit: 500000,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            linkToken: address(linkTokenMock),
            account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });
    }
}
