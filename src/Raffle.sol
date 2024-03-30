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
contract Raffle is VRFConsumerBaseV2{

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
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    uint64 private immutable i_subscriptionId;
    address private s_recentWinner;
    RaffleState private s_raffleState;
   

    event EnteredRaffle(address indexed player);
    event RequestedRaffleWinner(uint indexed winner);
    event WinnerPicked(address indexed winner);
    
    error Raffle__NotEnoughETHSend();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

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

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    //生成一个随机数
    //通过随机数选择一个玩家
    //定期自动执行

    function checkUpkeep(
        bytes memory /* checkData */
        ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
            bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
            bool isOpen = s_raffleState == RaffleState.OPEN;
            bool hasBalance = address(this).balance > 0;
            bool hasPlayers = s_players.length > 0;
            upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        } 

    function performUpkeep (bytes calldata /*performData*/) external {

        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CLACULATING;
        uint requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLine,//指定了愿意为更快的响应在网络上支付的gas费用，不同网络gas费率不同，每个gas价格都有自己的地址，见官方文档
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,//需要多少区块确认
            i_callbackGasLimit,//callback函数中可用的最大gas量
            NUM_WORDS//获取随机数的数量
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        emit WinnerPicked(winner);

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState) {
        return s_raffleState;
    }

    function getRafflePlayers(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns(uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns(uint256) {
        return s_lastTimeStamp;
    }
}