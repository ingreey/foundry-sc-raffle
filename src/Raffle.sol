// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Raffle is VRFConsumerBaseV2{
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    
    enum RaffleState { 
        OPEN, 
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subscriptionId;

    RaffleState private s_raffleState;
    address private s_recentWinner;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinator) {
        i_callbackGasLimit = callbackGasLimit;
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    /** EVENTS */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed player);

    function enterRaffle() external payable {
        if (i_entranceFee > msg.value) {
            revert Raffle__NotEnoughEthSent();
        }
        if ((s_raffleState != RaffleState.OPEN)) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // randomly called
    // automatically called
    function pickWinner() public {
        //check current block time to previous pick
        
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        s_raffleState = RaffleState.CALCULATING;
  
        uint256 requestId = i_vrfCoordinator.requestRandomWords(i_gasLane, i_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS);
        // get random number
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(winner);
    }
     
    /** GETTER FUNCTIONS */
    function getEntranceFee() public view returns(uint256) {
        return i_entranceFee;
    }
}