// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract
// Inside Contract:
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
// internal & private view & pure functions

// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


//import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
    


/**
 * @title A sample Raffle Contract
 * @author D. Ali bakar(or even better, you own name)
 * @notice This contract is for creating a sample raffle
 * @dev It implements Chainlink VRFv2 and Chainlink Automation
 */
contract Raffle is  VRFConsumerBaseV2Plus {

    /**Errors */
    error Raffle__NotEnoughEthSend();
    error Raffle__transferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleSate);

    /** Type declaration */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /**State variables */
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUMWORD= 1;
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    //@dev interval of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private  s_winner;
    RaffleState private s_raffleState;
    
   
    
    
    /** Events */
    event RafleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator,bytes32 gasLane, uint256 subscriptionId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval= interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSend();
        }
        if (s_raffleState!= RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        // require(msg.value>=i_entranceFee, NotEnoughEthSend())
        emit RafleEntered(msg.sender);

    }

/**
 * @dev Thiq is the function that that the chainlink will call to seeif the lottery is ready to have a winner picked
 * @param - ignored 
 * @return upkeepNeeded true if it is restarted
 * @return ignord
 */
     function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        //upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
        bool hasTimePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool lotteryIsOpen = (s_raffleState == RaffleState.OPEN);
        bool hasBalance = address(this).balance > 0;
        bool haPlayers = s_players.length > 0;
        upkeepNeeded = hasTimePassed && lotteryIsOpen && hasBalance && haPlayers;
        return (upkeepNeeded, "0x0");
        
    }

     function performUpkeep(bytes calldata /* performData */) external   {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert  Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }


        s_raffleState = RaffleState.CALCULATING;

         VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUMWORD,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: false
                    })
                )
            });

           uint256 requestId =  s_vrfCoordinator.requestRandomWords(request);
           emit RequestedRaffleWinner(requestId);

    }

    /* Getter Function */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        uint256 indexWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexWinner];
        s_winner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players =new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__transferFailed();
        }
 
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }

    function getPlayers(uint256 index) external view returns(address) {
        return s_players[index];
    }

    function getLastTimeStamps() external view returns(uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns(address) {
        return s_winner;
    }

}