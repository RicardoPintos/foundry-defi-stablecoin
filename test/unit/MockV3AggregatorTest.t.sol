// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract MockV3AggregatorTest is Test {
    HelperConfig config;
    address wethUsdPriceFeed;
    int256 public constant NEW_ETH_USD_PRICE = 3000e8;
    int256 public constant LAST_ETH_USD_PRICE = 4000e8;

    function setUp() public {
        config = new HelperConfig();
        (wethUsdPriceFeed,,,,) = config.activeNetworkConfig();
    }

    function testGetRoundData() public view {
        (, int256 answer,,,) = MockV3Aggregator(wethUsdPriceFeed).getRoundData(1);
        assert(answer == config.ETH_USD_PRICE());
    }

    function testUpdateAnswer() public {
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(NEW_ETH_USD_PRICE);
        (, int256 answer,,,) = MockV3Aggregator(wethUsdPriceFeed).latestRoundData();
        assertEq(answer, NEW_ETH_USD_PRICE);
    }

    function testUpdateRoundData() public {
        MockV3Aggregator(wethUsdPriceFeed).updateAnswer(NEW_ETH_USD_PRICE);
        MockV3Aggregator(wethUsdPriceFeed).updateRoundData(2, LAST_ETH_USD_PRICE, block.timestamp, block.timestamp);
        (, int256 answer,,,) = MockV3Aggregator(wethUsdPriceFeed).latestRoundData();
        assertEq(answer, LAST_ETH_USD_PRICE);
    }

    function testDescription() public view {
        assert(
            keccak256(abi.encodePacked(MockV3Aggregator(wethUsdPriceFeed).description()))
                == keccak256(abi.encodePacked("v0.6/tests/MockV3Aggregator.sol"))
        );
    }
}
