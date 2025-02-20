// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Lotto} from "../src/Lotto.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";

contract TestLotto is Lotto, CodeConstants {
    constructor(LottoConfig memory _config) Lotto(_config) {}

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
