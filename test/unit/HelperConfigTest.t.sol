// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    struct NetworkConfig {
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
        address weth;
        address wbtc;
        address account;
    }

    function setUp() public {}

    function testGetOrCreateAnvilEthConfig() public {
        HelperConfig config = new HelperConfig();
        address expectedAnvilAccount = config.getAnvilAccount();
        (,,,, address actualAnvilAccount) = config.activeNetworkConfig();
        console.log("expectedAnvilAccount", expectedAnvilAccount);
        console.log("actualAnvilAccount", actualAnvilAccount);
        assertEq(expectedAnvilAccount, actualAnvilAccount);
    }

    function testGetSepoliaEthConfig() public {
        vm.chainId(11155111);
        HelperConfig config = new HelperConfig();
        address expectedSepoliaAccount = config.getSepoliaAccount();
        (,,,, address actualSepoliaAccount) = config.activeNetworkConfig();

        console.log("expectedAnvilAccount", expectedSepoliaAccount);
        console.log("actualAnvilAccount", actualSepoliaAccount);
        assertEq(expectedSepoliaAccount, actualSepoliaAccount);
    }

    function testAnvilEthConfigAlreadyExists() public {
        HelperConfig config = new HelperConfig();
        (address wethUsdPriceFeed,,,,) = config.activeNetworkConfig();
        config.getOrCreateAnvilEthConfig();
        assert(wethUsdPriceFeed != address(0));
    }
}
