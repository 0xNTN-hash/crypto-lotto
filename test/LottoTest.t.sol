// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Lotto} from "../src/Lotto.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";

contract LottoTest is Test, CodeConstants {
    Lotto lotto;
    address PLAYER = makeAddr('player');
    uint8[6] playerNumbers = [1, 2, 3, 4, 5, 6];


    function setUp() public {
        lotto = new Lotto(ENTRY_FEE, INTERVAL_BETWEEN_DRAWS, NUMBERS_LENGTH, MAX_NUMBER, MIN_NUMBER, LOTTO_TAX_PERCENT, VRF_COORDINATOR, SUBSCRIPTION_ID, KEY_HASH, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT);

        vm.deal(PLAYER, ENTRY_FEE*2);
    }

    function testSuccessfulEntrance() public {
        uint256 initialBalance = address(lotto).balance;
        vm.prank(PLAYER);
        lotto.enter{value: ENTRY_FEE}(playerNumbers);

        uint256 numberOfParticipants = lotto.getNumberOfParticipants();

        assertEq(address(lotto).balance, initialBalance + ENTRY_FEE);
        assertEq(numberOfParticipants, 1);

        Lotto.Ticket memory ticket = lotto.getTicket(PLAYER);

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
        lotto.enter{value: ENTRY_FEE}([1, 2, 54, 4, 5, 0]);
    }
}
