// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {CurrencyLibrary, Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDeltaLibrary, BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";


contract PointsHook is BaseHook,ERC20{

    using CurrencyLibrary for Currency;
    using BalanceDeltaLibrary for BalanceDelta;

    //keep track of user => referrer

    mapping(address => address) public referedBy;

    //amounts of points someone get for refering someone

    uint256 public constant POINTS_FOR_REFERAL = 500 *10**18;

    //Initialize baseHook and ERC20

    constructor(IPoolManager _manager,
    string memory _name,
    string memory _symbol)
    BaseHook(_manager) ERC20(_name,_symbol,18){ }

//setUp hook permissions to return 'true'
// for the two hook functions we are using ''=> afterswap and afterAddLiquidity"

function getHookPermissions()public pure override returns(Hooks.Permissions memory){
    return Hooks.Permissions({
         beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterAddLiquidity: true,
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

//implementation of afterSwap

function afterSwap(address,
PoolKey calldata key,
IPoolManager.SwapParams calldata SwapParams,
BalanceDelta delta,
bytes calldata hookData) external override onlyByPoolManager returns(bytes4,int128){

    return(this.afterSwap.selector,0);

}

}
