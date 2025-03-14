// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {TestLotto} from "./TestLotto.sol";
import {Lotto} from "../src/Lotto.sol";
import {CodeConstants} from "../script/HelperConfig.s.sol";
import {DeployLotto} from "../script/DeployLotto.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract LottoTest is Test, CodeConstants {
    TestLotto lotto;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    DeployLotto deployer;

    uint256 entryFee;
    uint256 intervalBetweenDraws;
    uint8 numbersLength;
    uint8 maxNumber;
    uint8 minNumber;
    uint8 lottoTaxPercent;

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
        563728491563728491,
        827364819827364819,
        10293847561029384756,
        675849302675849302,
        483920176483920176
      ];


    function setUp() public {
        deployer = new DeployLotto();
        (lotto, helperConfig) = deployer.deployTestLotto();
        networkConfig = helperConfig.getNetworkConfig();
        entryFee = CodeConstants.ENTRY_FEE;
        intervalBetweenDraws = CodeConstants.INTERVAL_BETWEEN_DRAWS;
        numbersLength = CodeConstants.NUMBERS_LENGTH;
        maxNumber = CodeConstants.MAX_NUMBER;
        minNumber = CodeConstants.MIN_NUMBER;
        lottoTaxPercent = CodeConstants.LOTTO_TAX_PERCENT;

        vm.deal(PLAYER, entryFee*10);
    }

    function testLottoIsOpenOnDeployment() public view {
        assert(lotto.getLottoState() == Lotto.LottoState.OPEN);
    }

    function testCorrectJackpot() public {
        uint256 initialBalance = lotto.getTotalJackpot();
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        vm.stopPrank();

        uint256 totalJackpot = lotto.getTotalJackpot();

        assertEq(totalJackpot, initialBalance + entryFee * 2);
    }

    function testCorrectNumberOfParticipants() public {
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        vm.stopPrank();

        uint256 numberOfParticipants = lotto.getNumberOfParticipants();

        assertEq(numberOfParticipants, 2);
    }

    function testSuccessfulEntrance() public {
        vm.prank(PLAYER);
        lotto.enterLotto{value: entryFee}(playerNumbers);

        uint256 numberOfParticipants = lotto.getNumberOfParticipants();
        TestLotto.Ticket memory ticket = lotto.getTicket(PLAYER);

        assertEq(numberOfParticipants, 1);

        for (uint256 i = 0; i < playerNumbers.length; i++) {
            assertEq(ticket.numbers[i], playerNumbers[i]);
        }
    }

    function testLottoRevertsIfLowerEntryFee() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__WrongFee.selector, string(abi.encodePacked("Entry fee must be ", entryFee))));

        vm.prank(PLAYER);
        lotto.enterLotto{value: entryFee - 1}(playerNumbers);
    }

    function testLottoRevertsIfHigherEntryFee() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__WrongFee.selector, string(abi.encodePacked("Entry fee must be ", entryFee))));

        vm.prank(PLAYER);
        lotto.enterLotto{value: entryFee + 10}(playerNumbers);
    }

    function testLottoRevertsIfEnterInvalidNumber() public {
        vm.expectRevert(abi.encodeWithSelector(Lotto.LOTTO__InvalidNumber.selector, string(abi.encodePacked("Numbers must be between ", minNumber, " and ", maxNumber))));

        vm.prank(PLAYER);
        lotto.enterLotto{value: entryFee}(playerInvalidNumbers);
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
        lotto.enterLotto{value: entryFee}(playerNumbers);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        vm.stopPrank();

        (, , , uint256 sixNumbersPrizePercent) = lotto.getPrizePercentages();
        uint256 totalJackpot = lotto.getTotalJackpot();
        uint256 totalParticipants = lotto.getNumberOfParticipants();

        (, , , uint256 prizeAmountByLevelSix) = lotto.test_CalculatePrizeByLevel(0, 0, 0, totalParticipants);

        assertEq(prizeAmountByLevelSix, ((totalJackpot * sixNumbersPrizePercent) / 100) / totalParticipants);
    }

    function testCalculatedPrizesThreePeopleWinLevelThree() public {
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        vm.stopPrank();

        (uint256 threeNumbersPrizePercent, , , ) = lotto.getPrizePercentages();
        uint256 totalJackpot = lotto.getTotalJackpot();
        uint256 totalParticipants = lotto.getNumberOfParticipants();


        (uint256 prizeAmountByLevelThree, , , ) = lotto.test_CalculatePrizeByLevel(totalParticipants, 0, 0, 0);

        // 3 eth * 5% / 3 = 0.05 eth
        assertEq(prizeAmountByLevelThree, ((totalJackpot * threeNumbersPrizePercent) / 100) / totalParticipants);
    }

    function testCalculateNumberOfMatchingAllNumbers() public view {
        uint8[6] memory userNumbers = [27, 45, 36, 9, 26, 48];
        uint8[6] memory winningNumbers = [27, 45, 36, 9, 26, 48];

        uint8 numberOfMatchingNumbers = lotto.test_CalculateMatchCount(userNumbers, winningNumbers);

        assertEq(numberOfMatchingNumbers, 6);
    }

    function testCalculateNumberOfMatchingNoNumbers() public view {
        uint8[6] memory userNumbers = [27, 45, 36, 9, 26, 48];
        uint8[6] memory winningNumbers = [1, 2, 3, 4, 5, 6];

        uint8 numberOfMatchingNumbers = lotto.test_CalculateMatchCount(userNumbers, winningNumbers);

        assertEq(numberOfMatchingNumbers, 0);
    }

    function testWholeFlow() public {
        vm.startPrank(PLAYER);
        lotto.enterLotto{value: entryFee}(playerNumbers);
        vm.stopPrank();

        vm.recordLogs();
        lotto.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.log(logs.length, 'LOGS LENGTH');
        bytes32 requestId = logs[1].topics[1];

        vm.recordLogs();
        VRFCoordinatorV2_5Mock(networkConfig.vrfCoordinator).fulfillRandomWords(uint256(requestId), address(lotto));
        logs = vm.getRecordedLogs();
        console.log(logs.length, 'LOGS LENGTH');

        for (uint256 i = 0; i < logs.length; i++) {
            bytes32[] memory topics = logs[i].topics;
            console.logBytes32(topics[0]);
            emit log_bytes32(topics[0]); // Event signature
        }
    }

    /*//////////////////////////////////////////////////////////////
                          TEST GETTERS
    //////////////////////////////////////////////////////////////*/
    function testEntranceFee() public view {
        console.log("entryFee: ", entryFee);
        assertEq(lotto.getLottoEntranceFee(), entryFee);
    }
}
