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

/**
 * @title A sample Raffle Contract
 * @author y
 * @notice this contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Ruffle {

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    address payable[] private s_palyers;
    uint256 private s_lastTimeStamp;

    event EnterRaffle(address indexed player);

    error Raffle__NotEnoughETHSend();

    constructor(uint256 entranceFee, uint256 interval){
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable{
        //require(msg.value >= i_entranceFee, "Not enough ETH");
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

        
    }

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }
}