// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";

import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";

import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {TickMath} from "v4-core/libraries/TickMath.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";


contract TakeProfitsHook is BaseHook , ERC1155 {
    // stateLibrary its used to add helper functions to the PoolManager to read storage values

    using StateLibrary for IPoolManager;
    //PoolIdLibrary to convert PoolKeys to IDS
    using PoolIdLibrary for PoolKey;
    //Used to represent Currency types and helper functions like `.isNative()`
    using CurrencyLibrary for Currency;

    //Used for helpful math like `mulDiv`
    using FixedPointMathLib for uint256;


    //errors

    error InValidOrder();
    error NothingToClaim();
    error NotEnoughToClaim();


    //mapping to create a mapping to store pending orders. 
    mapping(PoolId poolId =>mapping(int24 tickToSell => mapping(bool zeroForOne => uint256 inputAmount))) public pendingOrders;

    mapping(uint256 positionId => uint256 claimSupply)public claimTokensSupply;


    //contructor

    constructor(IPoolManager _manager,string memory _url)BaseHook(_manager) ERC1155(_url){}
    // BaseHook Functions
    function getHookPermissions()
        public
        pure
        override
        returns (Hooks.Permissions memory)
    {
        return
            Hooks.Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
    }

    function afterInitialize(address,
    PoolKey calldata key,
    uint160,
    int24 tick,
    bytes calldata)external override onlyByPoolManager returns(bytes4){

        return this.afterInitialize.selector;

    }

    function afterSwap(address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta,
    bytes calldata)external override onlyByPoolManager returns(bytes4,int128){

        return (this.afterSwap.selector,0);
    }
    

    //getting the closet lower tick that is actually usable,given an arbitray 

    function getLowerUsableTick(int24 tick,int24 tickspacing)private pure returns(int24){
        //E.g tickspacing =60, tick = -100
        //closet usable tick rounded-down will be  -120

        //intervals = -100/60 = -1  (integer division)
        int24 intervals  = tick/tickspacing;

        //since tick <0 , we round `intervals` down to -2
        //if tick >0, `intervals` is fine as it is

        if(tick < 0 && tick % tickspacing !=0) intervals --; //round towards negative infinity
        //actual usable tick, is intervals * tickspacing

        //i.e -2*60 =-120
        return intervals *tickspacing;


    } 

    //helper function for the positionID

    function getPositionId(PoolKey calldata key,
    int24 tick,
    bool zeroForOne)public pure returns(uint256){
        return uint256(keccak256(abi.encode(key.toId(),tick,zeroForOne)));

    }

    //placing order

    function placeOrder(
        PoolKey calldata key,
        int24 tickToSellAt,
        bool zeroForOne,
        uint256 inputAmount
    ) external returns(int24){
        //ge the lower actually usable tick given `tickToSellAt
        int24 tick = getLowerUsableTick(tickToSellAt, key.tickSpacing);
        //create a pending order
        uint256 positionId  = getPositionId(key, tick, zeroForOne);
        claimTokensSupply[positionId] +=inputAmount;

        //Depending on direction of swap, we select the proper input token
        //and request a transfer of those tokens to the hook contract

        address sellToken = zeroForOne ? Currency.unwrap(key.currency0):Currency.unwrap(key.currency1);

        IERC20(sellToken).transferFrom(msg.sender,address(this), inputAmount);

        return tick;
    }

}