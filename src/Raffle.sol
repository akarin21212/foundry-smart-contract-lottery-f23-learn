/*
构造函数
receive 函数（如果存在）
fallback 函数（如果存在）
外部函数
公共函数
内部函数
私有函数 
*/
/*
按以下顺序布置合约的元素：
Pragma 语句
导入语句
接口
库
合约
在每个合约，库或接口内，使用以下顺序：
类型声明
状态变量
事件
错误
修饰符
函数
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


/**
 * @title A sample Raffle Contract
 * @author y
 * @notice this contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Ruffle is VRFConsumerBaseV2{

    enum RaffleState {
        OPEN,
        CLACULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLine;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_palyers;
    uint256 private s_lastTimeStamp;
    uint64 private immutable i_subscriptionId;
    address private s_recentWinner;
    RaffleState private s_raffleState;
   

    event EnterRaffle(address indexed player);

    error Raffle__NotEnoughETHSend();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator,
        bytes32 gasLine,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLine = gasLine;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }


    function enterRaffle() external payable{
        //require(msg.value >= i_entranceFee, "Not enough ETH");
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHSend();
        }

        s_palyers.push(payable(msg.sender));

        emit EnterRaffle(msg.sender);
    }

    //生成一个随机数
    //通过随机数选择一个玩家
    //定期自动执行
    function pickWinner() public {
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CLACULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLine,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_palyers.length;
        address payable winner = s_palyers[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_palyers = new address payable[](0);

        (bool success,) = s_recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }
}