// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title A Raffle Contract
 * @author 0xError
 * @notice This contract is for creating a sample raffle
 * @dev Implements chainLink VRFv2
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2{
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();

    /** ================= State Variables ================= */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    /** @dev duration of the lottery in seconds */
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    /** ================= Events ================= */
    event EnteredRaffle(address indexed player);

    /** ================= Functions ================= */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSent();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }
    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        /**
            @dev Here's what gonna happen: 
            @dev We're gonna make a request to the chainlink node to give us a random number (requestRandomWords);
        */
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        /**
            @dev It's gonna generate the random number, 
            @dev and then it's gonna call a very specific contract on chain called `VRFCoordinator` 
            @dev where only the chainlink node can respond to.
            @dev that contrct is gonna call rawFulfillRandomWords in `VRFConsumerBaseV2`,
            @dev finally `rawFulfillRandomWords` function is gonna call `fulfillRandomWords`
            @dev which exists in `VRFConsumerBaseV2` contract which we are overriding.
        */
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** ================= Getters ================= */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
