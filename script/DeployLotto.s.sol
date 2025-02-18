// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Lotto} from "src/Lotto.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {TestLotto} from "test/TestLotto.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract DeployLotto is Script {
    function deployLotto() public returns (Lotto, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        vm.startBroadcast();
        Lotto lotto = new Lotto(networkConfig.entryFee, networkConfig.intervalBetweenDraws, networkConfig.numbersLength, networkConfig.maxNumber, networkConfig.minNumber, networkConfig.lottoTaxPercent, networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.gasLane, networkConfig.requestConfirmations, networkConfig.callbackGasLimit, networkConfig.numberOfWords);
        vm.stopBroadcast();

        return (lotto, config);
    }

    function deployTestLotto() public returns (TestLotto, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        if(networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            networkConfig.subscriptionId = createSubscription.createSubscription(networkConfig.vrfCoordinator);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.linkToken);
        }

        vm.startBroadcast();
        TestLotto lotto = new TestLotto(
            networkConfig.entryFee,
            networkConfig.intervalBetweenDraws,
            networkConfig.numbersLength,
            networkConfig.maxNumber,
            networkConfig.minNumber,
            networkConfig.lottoTaxPercent,
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.gasLane,
            networkConfig.requestConfirmations,
            networkConfig.callbackGasLimit,
            networkConfig.numberOfWords);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(networkConfig.vrfCoordinator, networkConfig.subscriptionId, address(lotto));

        return (lotto, config);
    }

    function createSubscription() public {

    }

    function run() public {
        deployLotto();
    }
}
