// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract DecentralizedStableCoinTest is Test {
    HelperConfig config;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    DeployDSC deployer;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant SMALL_MINTING = 1e21;
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function setUp() public {
        config = new HelperConfig();

        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];
        dsc = new DecentralizedStableCoin();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        dsc.transferOwnership(address(dsc));
        ERC20Mock(weth).mint(address(dsc), STARTING_ERC20_BALANCE);
    }

    function testMintZeroAddress() public {
        vm.prank(address(dsc));
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector);
        dsc.mint(address(0), SMALL_MINTING);
    }

    function testMintMoreThanZero() public {
        vm.prank(address(dsc));
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.mint(address(dsc), 0);
    }

    function testBurnMoreThanZero() public {
        vm.startPrank(address(dsc));
        dsc.mint(address(dsc), SMALL_MINTING);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__MustBeMoreThanZero.selector);
        dsc.burn(0);
        vm.stopPrank();
    }

    function testBurnMoreThanBalance() public {
        vm.startPrank(address(dsc));
        dsc.mint(address(dsc), SMALL_MINTING);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(SMALL_MINTING + 1);
        vm.stopPrank();
    }
}
