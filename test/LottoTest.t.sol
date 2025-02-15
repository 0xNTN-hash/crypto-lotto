// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {console} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {TestLotto} from "./TestLotto.sol";
import {Lotto} from "../src/Lotto.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";

contract LottoTest is Test, CodeConstants {
    TestLotto lotto;
    address PLAYER = makeAddr('player');
    uint8[6] playerNumbers = [27, 45, 36, 9, 26, 48];
    uint8[6] playerInvalidNumbers = [27, 45, 36, 9, 0, 48];
    uint256[] randomNumbers = [
        1345678901234567890,
        987654321987654321,
        123456789123456789123,
        987654123987654123,
        192837465192837465,
        563728491563728491,
        827364819827364819,
        10293847561029384756,
        675849302675849302,
        483920176483920176
      ];


    function setUp() public {
        lotto = new TestLotto(ENTRY_FEE, INTERVAL_BETWEEN_DRAWS, NUMBERS_LENGTH, MAX_NUMBER, MIN_NUMBER, LOTTO_TAX_PERCENT, VRF_COORDINATOR, SUBSCRIPTION_ID, KEY_HASH, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT);

        vm.deal(PLAYER, ENTRY_FEE*10);
    }

    function testCorrectJackpot() public {
        uint256 initialBalance = lotto.getTotalJackpot();
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        vm.stopPrank();

        uint256 totalJackpot = lotto.getTotalJackpot();

        assertEq(totalJackpot, initialBalance + ENTRY_FEE * 2);
    }

    function testCorrectNumberOfParticipants() public {
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        vm.stopPrank();

        uint256 numberOfParticipants = lotto.getNumberOfParticipants();

        assertEq(numberOfParticipants, 2);
    }

    function testSuccessfulEntrance() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);

        uint256 numberOfParticipants = lotto.getNumberOfParticipants();
        TestLotto.Ticket memory ticket = lotto.getTicket(PLAYER);

        assertEq(numberOfParticipants, 1);

        for (uint256 i = 0; i < playerNumbers.length; i++) {
            assertEq(ticket.numbers[i], playerNumbers[i]);
        }
    }

    function testLottoRevertsIfLowerEntryFee() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__WrongFee.selector, string(abi.encodePacked("Entry fee must be ", ENTRY_FEE))));

        vm.prank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE - 1}(playerNumbers);
    }

    function testLottoRevertsIfHigherEntryFee() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__WrongFee.selector, string(abi.encodePacked("Entry fee must be ", ENTRY_FEE))));

        vm.prank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE + 10}(playerNumbers);
    }

    function testLottoRevertsIfEnterInvalidNumber() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__InvalidNumber.selector, string(abi.encodePacked("Numbers must be between ", MIN_NUMBER, " and ", MAX_NUMBER))));

        vm.prank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE}(playerInvalidNumbers);
    }

    function testRandomNumbersConversion() public {
        uint8[6] memory expectedNumbers = [5, 43, 12, 15, 29, 8];
        uint8[6] memory numbers = lotto.test_ParseNumbers(randomNumbers);

        for (uint256 i = 0; i < numbers.length; i++) {
            assertEq(numbers[i], expectedNumbers[i]);
        }
    }

    function testCalculatedPrizesTwoPeopleWinJackpot() public {
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        vm.stopPrank();

        (, , , uint256 sixNumbersPrizePercent) = lotto.getPrizePercentages();
        uint256 totalJackpot = lotto.getTotalJackpot();
        uint256 totalParticipants = lotto.getNumberOfParticipants();


        (, , , uint256 prizeAmountByLevelSix) = lotto.test_CalculatePrizeByLevel(0, 0, 0, totalParticipants);


        assertEq(prizeAmountByLevelSix, ((totalJackpot * sixNumbersPrizePercent) / 100) / totalParticipants);
    }

    function testCalculatedPrizesThreePeopleWinLevelThree() public {
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        lotto.enterLotto{value: ENTRY_FEE}(playerNumbers);
        vm.stopPrank();

        (uint256 threeNumbersPrizePercent, , , ) = lotto.getPrizePercentages();
        uint256 totalJackpot = lotto.getTotalJackpot();
        uint256 totalParticipants = lotto.getNumberOfParticipants();


        (uint256 prizeAmountByLevelThree, , , ) = lotto.test_CalculatePrizeByLevel(totalParticipants, 0, 0, 0);

        // 3 eth * 5% / 3 = 0.05 eth
        assertEq(prizeAmountByLevelThree, ((totalJackpot * threeNumbersPrizePercent) / 100) / totalParticipants);
    }

    function testCalculateNumberOfMatchingAllNumbers() public {
        uint8[6] memory userNumbers = [27, 45, 36, 9, 26, 48];
        uint8[6] memory winningNumbers = [27, 45, 36, 9, 26, 48];

        uint8 numberOfMatchingNumbers = lotto.test_CalculateMatchCount(userNumbers, winningNumbers);

        assertEq(numberOfMatchingNumbers, 6);
    }

    function testCalculateNumberOfMatchingNoNumbers() public {
        uint8[6] memory userNumbers = [27, 45, 36, 9, 26, 48];
        uint8[6] memory winningNumbers = [1, 2, 3, 4, 5, 6];

        uint8 numberOfMatchingNumbers = lotto.test_CalculateMatchCount(userNumbers, winningNumbers);

        assertEq(numberOfMatchingNumbers, 0);
    }
}
