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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
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

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    enum LottoState {
        OPEN,
        CLOSED,
        CALCULATING_WINNERS
    }

    struct Ticket {
        uint8[6] numbers;
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

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/
    event NewParticipantEntered();

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
    function enter(uint8[6] memory _numbers) external payable {
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
            numbers: _numbers
        });

        s_numberOfParticipants++;
        s_totalJackpot += msg.value;
        emit NewParticipantEntered();
    }

    function pickNumbers( ) external {
        if(s_state == LottoState.CALCULATING_WINNERS) {
            revert LOTTO__LottoIsNotOpen();
        }

        s_state = LottoState.CALCULATING_WINNERS;

        (uint256 requestId) = s_vrfCoordinator.requestRandomWords(
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

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}

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
}
