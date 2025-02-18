// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Lotto} from "../src/Lotto.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";

contract TestLotto is Lotto, CodeConstants {
    constructor(uint256 _entryFee, uint256 _intervalBetweenDraws, uint32 _numbersLength, uint8 _maxNumber, uint8 _minNumber, uint8 _lottoTaxPercent, address vrfCoordinator, uint256 _subscriptionId,  bytes32 _gasLane,  uint16 _requestConfirmations, uint32 _callbackGasLimit, uint32 _numberOfWords) Lotto(_entryFee, _intervalBetweenDraws, _numbersLength, _maxNumber, _minNumber, _lottoTaxPercent, vrfCoordinator, _subscriptionId, _gasLane, _requestConfirmations, _callbackGasLimit, _numberOfWords) {}

    function test_FulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) public{
        fulfillRandomWords(requestId, randomWords);
    }

    function test_ParseNumbers(uint256[] calldata randomWords) public returns (uint8[6] memory) {
        return _parseNumbers(randomWords);
    }

    function test_CalculateMatchCount(uint8[6] memory _userNumbers, uint8[6] memory _winningNumbers) public pure returns (uint8) {
        return _calculateMatchCount(_userNumbers, _winningNumbers);
    }

    function test_CalculatePrizeByLevel(uint256 _numbersOfThree, uint256 _numbersOfFour, uint256 _numbersOfFive, uint256 _numbersOfSix) public returns (uint256, uint256, uint256, uint256) {
        return _calculatePrizeByLevel(_numbersOfThree, _numbersOfFour, _numbersOfFive, _numbersOfSix);
    }
}
