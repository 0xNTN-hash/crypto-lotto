// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Lotto} from "../src/Lotto.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";

contract TestLotto is Lotto, CodeConstants {
    constructor(uint256 _entryFee, uint256 _intervalBetweenDraws, uint32 _numbersLength, uint8 _maxNumber, uint8 _minNumber, uint8 _lottoTaxPercent, address vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash, uint16 _requestConfirmations, uint32 _callbackGasLimit) Lotto(_entryFee, _intervalBetweenDraws, _numbersLength, _maxNumber, _minNumber, _lottoTaxPercent, vrfCoordinator, _subscriptionId, _keyHash, _requestConfirmations, _callbackGasLimit) {}

    function testFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) public{
        fulfillRandomWords(requestId, randomWords);
    }
}
