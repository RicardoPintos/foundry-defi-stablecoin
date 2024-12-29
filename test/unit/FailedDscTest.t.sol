// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FailedDscBurn} from "../mocks/FailedDscBurn.sol";
import {FailedDscMint} from "../mocks/FailedDscMint.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract FailedDscTest is Test {
    HelperConfig config;
    FailedDscMint dscMint;
    FailedDscBurn dscBurn;
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
    }

    ///////////////
    // Modifiers //
    ///////////////
    modifier failedDscMint() {
        dscMint = new FailedDscMint();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dscMint));
        dscMint.transferOwnership(address(dscMint));
        ERC20Mock(weth).mint(address(dscMint), STARTING_ERC20_BALANCE);
        _;
    }

    modifier failedDscBurn() {
        dscBurn = new FailedDscBurn();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dscBurn));
        dscBurn.transferOwnership(address(dscBurn));
        ERC20Mock(weth).mint(address(dscBurn), STARTING_ERC20_BALANCE);
        _;
    }

    /////////////////
    // Failed Mint //
    /////////////////
    function testMintZeroAddressFailedMint() public failedDscMint {
        vm.prank(address(dscMint));
        vm.expectRevert(FailedDscMint.FailedDscMint__NotZeroAddress.selector);
        dscMint.mint(address(0), SMALL_MINTING);
    }

    function testMintMoreThanZeroFailedMint() public failedDscMint {
        vm.prank(address(dscMint));
        vm.expectRevert(FailedDscMint.FailedDscMint__MustBeMoreThanZero.selector);
        dscMint.mint(address(dscMint), 0);
    }

    /////////////////
    // Failed Burn //
    /////////////////
    function testMintZeroAddressFailedBurn() public failedDscBurn {
        vm.prank(address(dscBurn));
        vm.expectRevert(FailedDscBurn.FailedDscBurn__NotZeroAddress.selector);
        dscBurn.mint(address(0), SMALL_MINTING);
    }

    function testMintMoreThanZeroFailedBurn() public failedDscBurn {
        vm.prank(address(dscBurn));
        vm.expectRevert(FailedDscBurn.FailedDscBurn__MustBeMoreThanZero.selector);
        dscBurn.mint(address(dscBurn), 0);
    }

    function testBurnMoreThanZeroFailedBurn() public failedDscBurn {
        vm.startPrank(address(dscBurn));
        dscBurn.mint(address(dscBurn), SMALL_MINTING);
        vm.expectRevert(FailedDscBurn.FailedDscBurn__MustBeMoreThanZero.selector);
        dscBurn.burn(0);
        vm.stopPrank();
    }

    function testBurnMoreThanBalanceFailedBurn() public failedDscBurn {
        vm.startPrank(address(dscBurn));
        dscBurn.mint(address(dscBurn), SMALL_MINTING);
        vm.expectRevert(FailedDscBurn.FailedDscBurn__BurnAmountExceedsBalance.selector);
        dscBurn.burn(SMALL_MINTING + 1);
        vm.stopPrank();
    }

    function testBurnTransferFromReturnFalse() public failedDscBurn {
        vm.startPrank(address(dscBurn));
        dscBurn.mint(address(dscBurn), SMALL_MINTING);
        (bool notSuccess) = dscBurn.transferFrom(address(dscBurn), address(dscBurn), SMALL_MINTING);
        assert(notSuccess == false);
    }
}
