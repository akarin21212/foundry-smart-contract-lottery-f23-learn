// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLine,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address link,
        uint256 deployKey
        ) = helperConfig.activeNetworkConfig();

        //如果没有subscription，那么创建一个
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link, deployKey);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            gasLine,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();

        //添加consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(raffle), 
            vrfCoordinator, 
            subscriptionId, 
            deployKey
        );

        return (raffle, helperConfig);
    }
}