// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant LIQUIDATOR_COLLATERAL = 100 ether;
    uint256 public constant STARTING_LIQUIDATOR_ERC20_BALANCE = 100 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant SMALL_MINTING = 1e21;
    uint256 public constant LIQUIDATOR_MINTING = 1e21;
    uint256 public constant SMALL_LIQUIDATE = 1e20;
    uint256 public constant TOO_MUCH_MINTING = 1e24;
    int256 public constant PRICE_LIQUIDATION = 110e8;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
        ERC20Mock(weth).mint(LIQUIDATOR, STARTING_LIQUIDATOR_ERC20_BALANCE);
    }

    ///////////////
    // Modifiers //
    ///////////////
    modifier userDepositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier userDepositedCollateralAndMinted() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, SMALL_MINTING);
        DecentralizedStableCoin(dsc).approve(address(engine), SMALL_MINTING);
        vm.stopPrank();
        _;
    }

    modifier liquidatorDepositedCollateralAndMinted() {
        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(engine), LIQUIDATOR_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, LIQUIDATOR_COLLATERAL, LIQUIDATOR_MINTING);
        DecentralizedStableCoin(dsc).approve(address(engine), LIQUIDATOR_MINTING);
        vm.stopPrank();
        _;
    }

    ///////////////////////
    // Constructor Tests //
    ///////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeedLength() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    function testTokensMatchPriceFeeds() public view {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            assertEq(engine.getPriceFeeds(tokenAddresses[i]), priceFeedAddresses[i]);
        }
    }

    function testCollateralTokens() public view {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            assertEq(engine.getCollateralTokens(i), tokenAddresses[i]);
        }
    }

    function testEngineIsOwner() public view {
        assertEq(engine.getDscOwner(), address(engine));
    }

    /////////////////
    // Price Tests //
    /////////////////
    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdAmount = 100 ether;
        uint256 expectedTokenAmount = 0.05 ether;
        uint256 actualTokenAmount = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedTokenAmount, actualTokenAmount);
    }

    /////////////////////////////
    // depositCollateral Tests //
    /////////////////////////////
    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotSupported.selector);
        engine.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetCollateral() public userDepositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(expectedTotalDscMinted, totalDscMinted);
        assertEq(expectedDepositAmount, AMOUNT_COLLATERAL);
    }

    function testMaxHealthFactor() public userDepositedCollateral {
        assertEq(engine.calculateHealthFactor(0, 1), type(uint256).max);
    }

    ///////////////////
    // mintDsc Tests //
    ///////////////////
    function testMintDsc() public userDepositedCollateralAndMinted {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        console.log("DSC Minted: ", totalDscMinted);
        console.log("Collateral deposited: ", collateralValueInUsd);
        assertEq(totalDscMinted, SMALL_MINTING);
    }

    function testRevertIfMintIsZero() public userDepositedCollateral {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.mintDsc(0);
    }

    function testMintingBreaksHealthFactor() public userDepositedCollateral {
        uint256 userHealthFactor =
            engine.calculateHealthFactor(TOO_MUCH_MINTING, engine.getUsdValue(weth, AMOUNT_COLLATERAL));

        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, userHealthFactor));

        engine.mintDsc(TOO_MUCH_MINTING);
        vm.stopPrank();
    }

    function testDepositAndMintFunction() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, SMALL_MINTING);
        uint256 userHealthFactor = engine.getHealthFactor(USER);
        vm.stopPrank();
        assert(userHealthFactor > engine.getMinHealthFactor());
    }

    ///////////////////////////
    // Redeem and Burn Tests //
    ///////////////////////////
    function testRedeemCollateral() public userDepositedCollateral {
        vm.prank(USER);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        assertEq(AMOUNT_COLLATERAL, ERC20Mock(weth).balanceOf(USER));
        assertEq((engine.getCollateralDeposited(USER, weth)), 0);
    }

    function testBurnDsc() public userDepositedCollateralAndMinted {
        vm.prank(USER);
        engine.burnDsc(SMALL_MINTING);
        uint256 amountOfUserDscAfterBurn = 0;
        assertEq(engine.getDscMinted(USER), amountOfUserDscAfterBurn);
    }

    function testRedeemCollateralForDsc() public userDepositedCollateralAndMinted {
        vm.prank(USER);
        engine.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, SMALL_MINTING);
        assertEq(AMOUNT_COLLATERAL, ERC20Mock(weth).balanceOf(USER));
        uint256 amountOfUserCollateralAfterRedeem = 0;
        uint256 amountOfUserDscAfterRedeem = 0;
        assertEq((engine.getCollateralDeposited(USER, weth)), amountOfUserCollateralAfterRedeem);
        assertEq(engine.getDscMinted(USER), amountOfUserDscAfterRedeem);
    }

    /////////////////////
    // Liquidate Tests //
    /////////////////////
    function testRevertHealthFactorOfUserOk() public userDepositedCollateralAndMinted {
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotBroken.selector);
        engine.liquidate(weth, USER, SMALL_MINTING);
    }

    function testRevertHealthFactorNotImproved()
        public
        userDepositedCollateralAndMinted
        liquidatorDepositedCollateralAndMinted
    {
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(PRICE_LIQUIDATION);
        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        engine.liquidate(weth, USER, SMALL_LIQUIDATE);
    }

    function testLiquidate() public userDepositedCollateralAndMinted {
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(PRICE_LIQUIDATION);
        uint256 previousUserCollateral = engine.getCollateralDeposited(USER, weth);
        uint256 previousUserDsc = engine.getDscMinted(USER);
        // Liquidator deposits collateral and mints after price drops.
        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(engine), LIQUIDATOR_COLLATERAL);
        engine.depositCollateralAndMintDsc(weth, LIQUIDATOR_COLLATERAL, LIQUIDATOR_MINTING);
        DecentralizedStableCoin(dsc).approve(address(engine), LIQUIDATOR_MINTING);
        engine.liquidate(weth, USER, SMALL_MINTING);
        vm.stopPrank();
        uint256 currentUserCollateral = engine.getCollateralDeposited(USER, weth);
        uint256 currentUserDsc = engine.getDscMinted(USER);
        assert(previousUserCollateral > currentUserCollateral);
        assert(previousUserDsc > currentUserDsc);
    }

    ///////////////////
    // Getters Tests //
    ///////////////////
    function testGetCollateralTokens() public view {
        assertEq(engine.getCollateralTokens(0), weth);
    }

    function testGetAccountCollateralValue() public userDepositedCollateral {
        assertEq(engine.getAccountCollateralValue(USER), engine.getUsdValue(weth, AMOUNT_COLLATERAL));
    }

    function testGetDscAddress() public view {
        assertEq(engine.getDscAddress(), address(dsc));
    }
}
