## HOOKS FUNCTIONS

-----
### `beforeInitialize`

------


`
- we Want to issue points in two cases
1. when a swap occurs which buys TOKEN for ETH
2. When liquidity is Added to the pull


##### `For case (1) we can use either beforeswap or afterswap`
##### `For case (2) we can use beforeAddLiquidity of afterAddLiquidity`

```
beforeSwap(address sender,
PoolKey calldata key,
IPoolManager.SwapParams calldata params,
bytes calldata hookData)


afterSwap(address sender,
PoolKey calldata key,
IPoolManager.SwapParams calldata params,
BalanceDelta delta,
bytes calldata hookData)
```


