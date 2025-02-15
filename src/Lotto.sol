// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Lotto is VRFConsumerBaseV2Plus {
    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/
    error LOTTO__WrongFee(string);
    error LOTTO__LottoIsNotOpen();
    error LOTTO__InvalidNumbersLength();
    error LOTTO__InvalidNumber(string);
    error LOTTO__NotEnoughUniqueNumbers();
    error LOTTO__ALLREADY_CLAIMED();
    error LOTTO__TicketDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 private constant SIX_NUMBERS_PRIZE_PERCENT = 70;
    uint256 private constant FIVE_NUMBERS_PRIZE_PERCENT = 15;
    uint256 private constant FOUR_NUMBERS_PRIZE_PERCENT = 10;
    uint256 private constant THREE_NUMBERS_PRIZE_PERCENT = 5;

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    enum LottoState {
        OPEN,
        CLOSED,
        CALCULATING_WINNERS
    }

    enum PRIZE_LEVELS {
        ZERO,
        THREE,
        FOUR,
        FIVE,
        SIX
    }

    struct Ticket {
        uint8[6] numbers;
        bool hasClaimedPrize;
        PRIZE_LEVELS prizeLevel;
        uint256 prize;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private immutable i_entryFee;
    uint8 private immutable i_lottoTaxPercent;
    uint256 private immutable i_intervalBetweenDraws;
    uint32 private immutable i_numbersLength;
    uint8 private immutable i_maxNumber;
    uint8 private immutable i_minNumber;

    string private s_version = "1.0.0";
    uint256 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint16 private s_requestConfirmations;
    uint32 private s_callbackGasLimit;
    uint256 private s_totalJackpot;
    uint256 private s_numberOfParticipants;
    LottoState private s_state;
    mapping(address => Ticket) private s_tickets;
    address[] private s_participants;

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event NewParticipantEntered();
    event PrizeLevelCalculated(uint256 prizeAmountByLevelThree, uint256 prizeAmountByLevelFour, uint256 prizeAmountByLevelFive, uint256 prizeAmountByLevelSix);
    event WinningNumbers(uint8[6] winningNumbers);

    constructor(uint256 _entryFee, uint256 _intervalBetweenDraws, uint32 _numbersLength, uint8 _maxNumber, uint8 _minNumber, uint8 _lottoTaxPercent, address vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash, uint16 _requestConfirmations, uint32 _callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entryFee = _entryFee;
        i_intervalBetweenDraws = _intervalBetweenDraws;
        i_numbersLength = _numbersLength;
        i_maxNumber = _maxNumber;
        i_minNumber = _minNumber;
        i_lottoTaxPercent = _lottoTaxPercent;

        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        s_requestConfirmations = _requestConfirmations;
        s_callbackGasLimit = _callbackGasLimit;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function enterLotto(uint8[6] memory _numbers) external payable {
        if(s_state != LottoState.OPEN) {
            revert LOTTO__LottoIsNotOpen();
        }

        if(msg.value != i_entryFee) {
            revert LOTTO__WrongFee(string(abi.encodePacked("Entry fee must be ", i_entryFee)));
        }

        /**
         * @note: Maybe can remove this check because of the fixed array size?
         * @todo: Deduct the lotto tax from the entry fee
         */
        if(_numbers.length != i_numbersLength) {
            revert LOTTO__InvalidNumbersLength();
        }

        for(uint256 i = 0; i < _numbers.length; i++) {
            if(_numbers[i] < i_minNumber || _numbers[i] > i_maxNumber) {
                revert LOTTO__InvalidNumber(string(abi.encodePacked("Numbers must be between ", i_minNumber, " and ", i_maxNumber)));
            }
        }

        s_tickets[msg.sender] = Ticket({
            numbers: _numbers,
            hasClaimedPrize: false,
            prizeLevel: PRIZE_LEVELS.ZERO,
            prize: 0
        });
        s_participants.push(msg.sender);

        s_numberOfParticipants++;
        s_totalJackpot += msg.value;
        emit NewParticipantEntered();
    }

    // function checkMyNumbers() external view returns(bool) {
    //     if(s_state != LottoState.OPEN) {
    //         revert LOTTO__LottoIsNotOpen();
    //     }

    //     Ticket memory ticket = s_tickets[msg.sender];

    //     if(ticket.numbers[0] == 0) {
    //         revert LOTTO__TicketDoesNotExist();
    //     }

    //     if(ticket.hasClaimedPrize) {
    //         revert LOTTO__ALLREADY_CLAIMED();
    //     }
    // }

    /*
     * @TODO: Save the requestId
     */
    function pickNumbers( ) external {
        if(s_state == LottoState.CALCULATING_WINNERS) {
            revert LOTTO__LottoIsNotOpen();
        }

        s_state = LottoState.CALCULATING_WINNERS;

        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: s_requestConfirmations,
                callbackGasLimit: s_callbackGasLimit,
                numWords: i_numbersLength,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override{
        uint8[6] memory winningNumbers = _parseNumbers(randomWords);
        emit WinningNumbers(winningNumbers);
        _destibutePrizesToTickets(winningNumbers);
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Parse the random words to numbers in range from 1 to i_maxNumber and save them to the state
     * @param _randomWords The random words to parse
     */
    function _parseNumbers(uint256[] calldata _randomWords) internal returns(uint8[6] memory) {
        s_state = LottoState.CALCULATING_WINNERS;

        bool[] memory pickedNumbers = new bool[](i_maxNumber + 1);
        uint8[6] memory winningNumbers;
        uint16 counter = 0;

        for(uint256 i = 0; i < _randomWords.length; i++) {
            uint8 number = uint8(_randomWords[i] % i_maxNumber) + 1;

            if(counter == i_numbersLength) {
                break;
            }

            if(!pickedNumbers[number]) {
                pickedNumbers[number] = true;
                winningNumbers[counter] = number;
                counter++;
            }
        }

        if(counter != i_numbersLength) {
            revert LOTTO__NotEnoughUniqueNumbers();
        }

        return winningNumbers;
    }

    /**
     * @dev Destributes the prizes to the tickets
     */
    function _destibutePrizesToTickets(uint8[6] memory _winningNumbers) internal {
        uint256 numberOfParticipants = s_participants.length;
        uint256 numbersOfThree = 0;
        uint256 numbersOfFour = 0;
        uint256 numbersOfFive = 0;
        uint256 numbersOfSix = 0;

        for(uint256 i = 0; i < numberOfParticipants; i++) {
            Ticket storage ticket = s_tickets[s_participants[i]];
            uint matchCount = _calculateMatchCount(ticket.numbers, _winningNumbers);

            if (matchCount == 0 || matchCount == 1 || matchCount == 2) {
                ticket.prize = 0;
            } else if (matchCount == 3) {
                ticket.prizeLevel = PRIZE_LEVELS.THREE;
                numbersOfThree++;
            } else if (matchCount == 4) {
                ticket.prizeLevel = PRIZE_LEVELS.FOUR;
                numbersOfFour++;
            } else if (matchCount == 5) {
                ticket.prizeLevel = PRIZE_LEVELS.FIVE;
                numbersOfFive++;
            } else if (matchCount == 6) {
                ticket.prizeLevel = PRIZE_LEVELS.SIX;
                numbersOfSix++;
            }
        }

        (uint256 prizeAmountByLevelThree, uint256 prizeAmountByLevelFour, uint256 prizeAmountByLevelFive, uint256 prizeAmountByLevelSix) = _calculatePrizeByLevel(numbersOfThree, numbersOfFour, numbersOfFive, numbersOfSix);

        for(uint256 i = 0; i < numberOfParticipants; i++) {
            Ticket storage ticket = s_tickets[s_participants[i]];

            if (ticket.prizeLevel == PRIZE_LEVELS.THREE) {
                ticket.prize = prizeAmountByLevelThree;
            } else if (ticket.prizeLevel == PRIZE_LEVELS.FOUR) {
                ticket.prize = prizeAmountByLevelFour;
            } else if (ticket.prizeLevel == PRIZE_LEVELS.FIVE) {
                ticket.prize = prizeAmountByLevelFive;
            } else if (ticket.prizeLevel == PRIZE_LEVELS.SIX) {
                ticket.prize = prizeAmountByLevelSix;
            }
        }
    }

    /**
     * @dev Calculates the prize amount for each prize level
     * @param _numbersOfThree The number of tickets with 3 winning numbers
     * @param _numbersOfFour The number of tickets with 4 winning numbers
     * @param _numbersOfFive The number of tickets with 5 winning numbers
     * @param _numbersOfSix The number of tickets with 6 winning numbers
     * @return The prize amount for each prize level
     */
    function _calculatePrizeByLevel(uint256 _numbersOfThree, uint256 _numbersOfFour, uint256 _numbersOfFive, uint256 _numbersOfSix) internal returns(uint256, uint256, uint256, uint256) {
        uint256 prizeAmountByLevelSix = 0;
        uint256 prizeAmountByLevelFive = 0;
        uint256 prizeAmountByLevelFour = 0;
        uint256 prizeAmountByLevelThree = 0;

        if(_numbersOfThree > 0) {
            prizeAmountByLevelThree = ((s_totalJackpot * THREE_NUMBERS_PRIZE_PERCENT) / 100) / _numbersOfThree;
        } else if(_numbersOfFour > 0) {
            prizeAmountByLevelFour = ((s_totalJackpot * FOUR_NUMBERS_PRIZE_PERCENT) / 100) / _numbersOfFour;
        } else if(_numbersOfFive > 0) {
            prizeAmountByLevelFive = ((s_totalJackpot * FIVE_NUMBERS_PRIZE_PERCENT) / 100) / _numbersOfFive;
        } else if(_numbersOfSix > 0) {
            prizeAmountByLevelSix = ((s_totalJackpot * SIX_NUMBERS_PRIZE_PERCENT) / 100) / _numbersOfSix;
        }

        emit PrizeLevelCalculated(prizeAmountByLevelThree, prizeAmountByLevelFour, prizeAmountByLevelFive, prizeAmountByLevelSix);

        return (prizeAmountByLevelThree, prizeAmountByLevelFour, prizeAmountByLevelFive, prizeAmountByLevelSix);
    }

    /**
     * @dev Calculates the number of matches between the user's numbers and the winning numbers
     * @param _userNumbers The user's numbers
     * @return The number of matches
     */
    function _calculateMatchCount(uint8[6] memory _userNumbers, uint8[6] memory _winningNumbers) internal pure returns (uint8) {
        uint8 matchCount = 0;
        for (uint i = 0; i < 6; i++) {
            for (uint j = 0; j < 6; j++) {
                if (_userNumbers[i] == _winningNumbers[j]) {
                    matchCount++;
                    break; // Stop once a match is found
                }
            }
        }
        return matchCount;
    }

    /*//////////////////////////////////////////////////////////////
                          GETTERS FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getNumberOfParticipants() public view returns(uint256) {
        return s_numberOfParticipants;
    }

    function getTotalJackpot() public view returns(uint256) {
        return s_totalJackpot;
    }

    function getTicket(address _address) public view returns(Ticket memory) {
        return s_tickets[_address];
    }

    function getPrizePercentages() public pure returns(uint256, uint256, uint256, uint256) {
        return (THREE_NUMBERS_PRIZE_PERCENT, FOUR_NUMBERS_PRIZE_PERCENT, FIVE_NUMBERS_PRIZE_PERCENT, SIX_NUMBERS_PRIZE_PERCENT);
    }
}
