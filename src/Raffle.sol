// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title A Raffle Contract
 * @author 0xError
 * @notice This contract is for creating a sample raffle
 * @dev Implements chainLink VRFv2
 */
contract Raffle {
    error Raffle_NotEnoughEthSent();

    uint256 private immutable i_entranceFee;
    /** @dev duration of the lottery in seconds */
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /** ================= Events ================= */
    event EnteredRaffle(address indexed player);

    /** ================= Functions ================= */
    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) { revert Raffle_NotEnoughEthSent(); }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }
    function pickWinner() external {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
    }

    /** ================= Getters ================= */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}