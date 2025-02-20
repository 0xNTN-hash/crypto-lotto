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

        Lotto.LottoConfig memory lottoConfig = Lotto.LottoConfig({
            entryFee: networkConfig.entryFee,
            lottoTaxPercent: networkConfig.lottoTaxPercent,
            vrfCoordinator: networkConfig.vrfCoordinator,
            subscriptionId: networkConfig.subscriptionId,
            gasLane: networkConfig.gasLane,
            requestConfirmations: networkConfig.requestConfirmations,
            callbackGasLimit: networkConfig.callbackGasLimit,
            numberOfWords: networkConfig.numberOfWords
        });

        vm.startBroadcast();
        Lotto lotto = new Lotto(lottoConfig);
        vm.stopBroadcast();

        return (lotto, config);
    }

    function deployTestLotto() public returns (TestLotto, HelperConfig) {
        HelperConfig config = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = config.getNetworkConfig();

        if(networkConfig.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            networkConfig.subscriptionId = createSubscription.createSubscription(networkConfig.vrfCoordinator, networkConfig.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.linkToken, networkConfig.account);
        }

        Lotto.LottoConfig memory lottoConfig = Lotto.LottoConfig({
            entryFee: networkConfig.entryFee,
            lottoTaxPercent: networkConfig.lottoTaxPercent,
            vrfCoordinator: networkConfig.vrfCoordinator,
            subscriptionId: networkConfig.subscriptionId,
            gasLane: networkConfig.gasLane,
            requestConfirmations: networkConfig.requestConfirmations,
            callbackGasLimit: networkConfig.callbackGasLimit,
            numberOfWords: networkConfig.numberOfWords
        });

        vm.startBroadcast(networkConfig.account);
        TestLotto lotto = new TestLotto(lottoConfig);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(networkConfig.vrfCoordinator, networkConfig.subscriptionId, address(lotto), networkConfig.account);

        return (lotto, config);
    }

    function createSubscription() public {

    }

    function run() public {
        deployLotto();
    }
}
