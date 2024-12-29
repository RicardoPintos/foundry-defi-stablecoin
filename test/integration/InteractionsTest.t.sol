// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {OracleLib} from "../../src/libraries/OracleLib.sol";
import {FailedERC20MockTransfer} from "../mocks/FailedERC20MockTransfer.sol";
import {FailedERC20MockTransferFrom} from "../mocks/FailedERC20MockTransferFrom.sol";
import {FailedDscMint} from "../mocks/FailedDscMint.sol";
import {FailedDscBurn} from "../mocks/FailedDscBurn.sol";

contract InteractionsTest is Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    FailedERC20MockTransfer wethTransferFailed;
    FailedERC20MockTransferFrom wethTransferFromFailed;
    FailedDscMint mockDscMint;
    FailedDscBurn mockDscBurn;
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    address public USER = makeAddr("user");

    uint256 public constant STARTING_BALANCE = 100 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant SMALL_MINTING = 1e21;
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;

    function setUp() public {
        vm.deal(USER, STARTING_BALANCE);
    }

    function testDepositCollateralFailed() public {
        config = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed,, address wbtc,) = config.activeNetworkConfig();
        wethTransferFromFailed = new FailedERC20MockTransferFrom("WETH", "WETH", msg.sender, 1000e8);

        tokenAddresses = [address(wethTransferFromFailed), wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        dsc = new DecentralizedStableCoin();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        dsc.transferOwnership(address(engine));
        vm.startPrank(USER);
        FailedERC20MockTransferFrom(wethTransferFromFailed).mint(USER, STARTING_ERC20_BALANCE);
        FailedERC20MockTransferFrom(wethTransferFromFailed).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);
        engine.depositCollateral(address(wethTransferFromFailed), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testMintFailed() public {
        config = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc,) = config.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        mockDscMint = new FailedDscMint();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockDscMint));
        mockDscMint.transferOwnership(address(engine));
        vm.startPrank(USER);
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__MintFailed.selector);
        engine.mintDsc(SMALL_MINTING);
        vm.stopPrank();
    }

    function testRedeemFailed() public {
        config = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed,, address wbtc,) = config.activeNetworkConfig();
        wethTransferFailed = new FailedERC20MockTransfer("WETH", "WETH", msg.sender, 1000e8);

        tokenAddresses = [address(wethTransferFailed), wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        dsc = new DecentralizedStableCoin();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        dsc.transferOwnership(address(engine));
        vm.startPrank(USER);
        FailedERC20MockTransfer(wethTransferFailed).mint(USER, STARTING_ERC20_BALANCE);
        FailedERC20MockTransfer(wethTransferFailed).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(address(wethTransferFailed), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);
        engine.redeemCollateral(address(wethTransferFailed), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testBurnFailed() public {
        config = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc,) = config.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        mockDscBurn = new FailedDscBurn();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(mockDscBurn));
        mockDscBurn.transferOwnership(address(engine));
        vm.startPrank(USER);
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(SMALL_MINTING);
        vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);
        engine.burnDsc(SMALL_MINTING);
        vm.stopPrank();
    }

    function testStalePrice() public {
        config = new HelperConfig();
        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc,) = config.activeNetworkConfig();
        console.log("Original time: ", block.timestamp);
        uint256 stalePriceTime = block.timestamp + 4 hours;
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        dsc = new DecentralizedStableCoin();
        engine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
        dsc.transferOwnership(address(engine));
        vm.warp(stalePriceTime);
        console.log("Current time: ", block.timestamp);
        vm.expectRevert(OracleLib.OracleLib__StalePrice.selector);
        engine.getUsdValue(weth, STARTING_ERC20_BALANCE);
    }

    function testERC20MintInicialBalance() public {
        config = new HelperConfig();
        (,, address weth,,) = config.activeNetworkConfig();
        assert(ERC20Mock(weth).balanceOf(address(this)) == 1000e8);
    }

    function testERC20BurnInicialBalance() public {
        config = new HelperConfig();
        (,, address weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).burn(address(this), 1000e8);
        assert(ERC20Mock(weth).balanceOf(address(this)) == 0);
    }
}
