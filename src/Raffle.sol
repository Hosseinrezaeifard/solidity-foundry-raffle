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
    address payable[] private s_players;

    /** ================= Events ================= */
    event EnteredRaffle(address indexed player);

    /** ================= Functions ================= */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) { revert Raffle_NotEnoughEthSent(); }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }
    function pickWinner() public {}

    /** ================= Getters ================= */
    function getEntranceFee() external view returns(uint256) {
        return i_entranceFee;
    }
}