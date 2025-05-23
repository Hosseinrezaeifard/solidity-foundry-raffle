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
    /** ================= Errors ================= */
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();

    /** ================= Type Declarations ================= */
    /** @dev each field in enum can be converted to interge => for example: Open would be 0, calculating would be 1 */
    enum RaffleState {OPEN, CALCULATING}

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
    RaffleState private s_raffleState;

    /** ================= Events ================= */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    /** ================= Functions ================= */
    constructor(uint256 entranceFee,uint256 interval,address vrfCoordinator,bytes32 gasLane,uint64 subscriptionId,uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    // ✅ CEI Verified Function
    function enterRaffle() external payable {
        // Checks
        if (msg.value < i_entranceFee) { revert Raffle__NotEnoughEthSent(); }
        if (s_raffleState != RaffleState.OPEN) { revert Raffle__RaffleNotOpen(); }
        // Effects
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // ✅ CEI Verified Function
    function pickWinner() external {
        // Checks
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        // Effects (Our own contract)
        s_raffleState = RaffleState.CALCULATING;
        /**
            @dev Here's what gonna happen: 
            @dev We're gonna make a request to the chainlink node to give us a random number (requestRandomWords);
        */
        // Interactions (Other contracts)
        i_vrfCoordinator.requestRandomWords(
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

    // ✅ CEI Verified Function
    function fulfillRandomWords(uint256,uint256[] memory randomWords) internal override {
        // Effects (Our own contract)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.CALCULATING;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner);
        // Interactions (Other contracts)
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
