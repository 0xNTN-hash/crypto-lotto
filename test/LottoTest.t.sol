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

        vm.deal(PLAYER, ENTRY_FEE*2);
    }

    function testSuccessfulEntrance() public {
        uint256 initialBalance = address(lotto).balance;
        vm.prank(PLAYER);
        lotto.enter{value: ENTRY_FEE}(playerNumbers);

        uint256 numberOfParticipants = lotto.getNumberOfParticipants();

        assertEq(address(lotto).balance, initialBalance + ENTRY_FEE);
        assertEq(numberOfParticipants, 1);

        TestLotto.Ticket memory ticket = lotto.getTicket(PLAYER);

        for (uint256 i = 0; i < playerNumbers.length; i++) {
            assertEq(ticket.numbers[i], playerNumbers[i]);
        }
    }

    function testLottoRevertsIfLowerEntryFee() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__WrongFee.selector, string(abi.encodePacked("Entry fee must be ", ENTRY_FEE))));

        vm.prank(PLAYER);
        lotto.enter{value: ENTRY_FEE - 1}(playerNumbers);
    }

    function testLottoRevertsIfHigherEntryFee() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__WrongFee.selector, string(abi.encodePacked("Entry fee must be ", ENTRY_FEE))));

        vm.prank(PLAYER);
        lotto.enter{value: ENTRY_FEE + 10}(playerNumbers);
    }

    function testLottoRevertsIfEnterInvalidNumber() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__InvalidNumber.selector, string(abi.encodePacked("Numbers must be between ", MIN_NUMBER, " and ", MAX_NUMBER))));

        vm.prank(PLAYER);
        lotto.enter{value: ENTRY_FEE}(playerNumbers);
    }

    // function testRandomNumbersConversion() public {
    //     uint8[6] memory expectedNumbers = [5, 43, 12, 15, 29, 8];
    //     uint8[] memory numbers = lotto._parseNumbers(randomNumbers);

    //     for (uint256 i = 0; i < numbers.length; i++) {
    //         assertEq(numbers[i], expectedNumbers[i]);
    //     }
    // }
}
