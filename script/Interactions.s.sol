// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "@foundryDevops/DevOpsTools.sol";

import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address account = helperConfig.getConfig().account;

        (uint256 subId, ) = createSubscription(vrfCoordinator, account);

        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
        console.log("Creating a subscriotnio with chainID: ", block.chainid);
        console.log("With account: ", account);
        console.log("With vrfCoordinator: ", vrfCoordinator);

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription ID is: ", subId);
        console.log("Please update the subscription ID in the HelperConfig contract");

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 20 ether; // 20 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().linkToken;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinator, subId, linkToken, account);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken, address account) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chainId: ", block.chainid);
        console.log("Using account: ", account);

        if(block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;

        addConsumer(vrfCoordinator, subId, mostRecentlyDeployed, account);
    }

    function addConsumer(address vrfCoordinator, uint256 subId, address mostRecentlyDeployed, address account) public {
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, mostRecentlyDeployed);
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Lotto", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
