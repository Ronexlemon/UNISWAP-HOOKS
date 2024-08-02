// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {PoolManager} from "v4-core/PoolManager.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";

import "forge-std/console.sol";
import {PointsHook} from "../src/PointHook.sol";

/***Before test
 * 1 . Deploy an instance of the PoolManager
 * 2. Deploy periphery router contracts for swapping, modifying liquidity
 * 3. Deploy the TOKEN ERC20 contract
 * 4. Mint a bunch of TOKEN supply to ourselves so we can use it for adding liquidity
 * 5. Mine a contract address for our hook using HookMiner
 * 6. Deploy our Hook contract
 * 7. Approve our TOKEN for spending on the periphery router contracts
 * 8. Create a new Pool for ETH and TOKEN with our hook contracts
 */
contract TestPointHook is Test,Deployers{
    using CurrencyLibrary for Currency;
    MockERC20 public token; // token to use in the ETH-TOKEN pool

    //Native tokens are represented by address(0)

    Currency ethCurrency = Currency.wrap(address(0));

    Currency public tokenCurrency;
    PointsHook hook;

    function setUp()public{
        //Step 1 +2
        //Deploy PoolManagerAndRouter and router contracts
        deployFreshManagerAndRouters();

        //Deploy our TOKEN contract
        token = new MockERC20("Test Token", "TT", 18);
        tokenCurrency = Currency.wrap(address(token));
        //Mint a bunch of Token to ourselves and to address
        token.mint(address(this),1000 ether);
        token.mint(address(1),1000 ether);

        //Deploy hook to an address that has the proper flags
        uint160 flags = uint160(Hooks.AFTER_ADD_LIQUIDITY_FLAG| Hooks.AFTER_SWAP_FLAG);
        deployCodeTo("PointHook.sol",
        abi.encode(manager, "Points Token", "TEST_POINTS"),
        address(flags)
        );

        //Deploy our Hook

        hook = PointsHook(address(flags));
        //Approve our token for spending on Swap router and modify liquidity router

        //these variables are coming from the `Deployers` contract

        token.approve(address(swapRouter), type(uint256).max);
         token.approve(address(modifyLiquidityRouter), type(uint256).max);

         //Initalize a pool
         (key,) = initPool(ethCurrency, //, Currency 0 = ETH
          tokenCurrency, //, Currency 1 = TOKEN
           hook, //HOOK contract
            3000,  //0.03 % Wap fees
            SQRT_PRICE_1_1, //Initial  Sqrt(P) value = 1
             ZERO_BYTES  // No additional  'initData'
             );



    }


    // tests  Add liquidity + swap (without referrer)

}



