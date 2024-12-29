// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "../../test/fuzz/Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine engine;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();
        handler = new Handler(engine, dsc);
        targetContract(address(handler));
    }

    function invariant_protocolMustHaveMoreValueThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(engine));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(engine));

        uint256 wethValue = engine.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = engine.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("wethValue", wethValue);
        console.log("wbtcValue", wbtcValue);
        console.log("totalSupply", totalSupply);
        console.log("times mint is called", handler.timesMintIsCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_gettersShouldNotRevert() public view {
        // Engine getters
        engine.getDscOwner();
        engine.getDscAddress();
        engine.getMinHealthFactor();
        engine.getCollateralTokensArray();
        engine.getDscMinted(msg.sender);
        engine.getHealthFactor(msg.sender);
        engine.calculateHealthFactor(engine.getDscMinted(msg.sender), engine.getAccountCollateralValue(msg.sender));
        for (uint256 i = 0; i < engine.getCollateralTokensArray().length; i++) {
            engine.getCollateralDeposited(msg.sender, engine.getCollateralTokens(i));
        }
        for (uint256 i = 0; i < engine.getCollateralTokensArray().length; i++) {
            engine.getPriceFeeds(address(uint160(i)));
        }
        for (uint256 i = 0; i < engine.getCollateralTokensArray().length; i++) {
            engine.getCollateralTokens(i);
        }
        for (uint256 i = 0; i < engine.getCollateralTokensArray().length; i++) {
            engine.getTokenAmountFromUsd(
                engine.getCollateralTokens(i),
                engine.getUsdValue(
                    engine.getCollateralTokens(i),
                    engine.getCollateralDeposited(msg.sender, engine.getCollateralTokens(i))
                )
            );
        }
        engine.getAccountCollateralValue(msg.sender);
        for (uint256 i = 0; i < engine.getCollateralTokensArray().length; i++) {
            engine.getUsdValue(
                engine.getCollateralTokens(i), engine.getCollateralDeposited(msg.sender, engine.getCollateralTokens(i))
            );
        }
        engine.getAccountInformation(msg.sender);

        // Config getters
        config.getSepoliaAccount();
        config.getAnvilAccount();
    }
}
