// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.t.sol";

abstract contract CodeConstant {
    /** VRF COORDNATOR CONSTANT */
    uint96 public constant BASE_FEE = 1 ether;
    uint96 public constant GAS_PRICE= 1e9;
    int256 public constant WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
contract HelperConfig  is Script, CodeConstant {
    error HelperConfig__InvalidChainId();
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane; 
        uint256 subscriptionId; 
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    NetworkConfig public s_localNetwokConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function getConfigByChainId(uint256 chainId) public  returns(NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId] ;
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public  returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig ({
            entranceFee: 0.01 ether,
            interval :30,
             vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
             gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
             callbackGasLimit: 500000,
             subscriptionId: 71836126886715559154197175906264911707336137386531605208782877508334661361883,
             link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
             account: 0x072AB702Abb5BF91d2eD842dC87BEE2044f84C51


        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (s_localNetwokConfig.vrfCoordinator != address(0)) {
            return s_localNetwokConfig;
        }
        //Deploy mocks
        vm.startBroadcast();

        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        LinkToken linkToken =new LinkToken();
        vm.stopBroadcast();
        s_localNetwokConfig = NetworkConfig ({
            entranceFee: 0.01 ether,
            interval :30,
            vrfCoordinator: address(vrfCoordinator),
            gasLane : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38

        });
        return s_localNetwokConfig;
    }

}