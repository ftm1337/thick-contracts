/*


FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU

						Contact us at:
			https://discord.com/invite/QpyfMarNrV
					https://t.me/FTM1337


	Community Mediums:
		https://medium.com/@ftm1337
		https://twitter.com/ftm1337




    ▀█▀░█░█░█░█▀░█▄▀
    ░█░░█▀█░█░█▄░█▀▄

	Thick Liquidity Protocol
	> Network agnostic Decentralized Exchange for ERC20 tokens


   Contributors:
    -   543#3017 (Sam, @i543), ftm.guru, Eliteness.network


  SPDX-License-Identifier: UNLICENSED

*/

pragma solidity 0.7.6;

import './interfaces/IUniswapV3Factory.sol';

import './UniswapV3PoolDeployer.sol';
import './NoDelegateCall.sol';
import './UniswapV3Pool.sol';

/// @title Canonical Uniswap V3 factory
/// @notice Deploys Uniswap V3 pools and manages ownership and control over pool protocol fees
contract UniswapV3Factory is IUniswapV3Factory, UniswapV3PoolDeployer, NoDelegateCall {
    /// @inheritdoc IUniswapV3Factory
    address public override owner;
    /// @inheritdoc IUniswapV3Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IUniswapV3Factory
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;
    /// @inheritdoc IUniswapV3Factory
    address[] public override allPairs;
    /// @inheritdoc IUniswapV3Factory
    uint8 public override feeProtocol = 27; // 15=5%, 27=10%

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[100] = 1;
        emit FeeAmountEnabled(100, 1);
        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }

    /// @inheritdoc IUniswapV3Factory
    function POOL_INIT_CODE_HASH() external override pure returns (bytes32) {
        return keccak256(type(UniswapV3Pool).creationCode);
    }
/*
    /// @inheritdoc IUniswapV3Factory
    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }
*/
    /// @inheritdoc IUniswapV3Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        allPairs.push(pool);
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IUniswapV3Factory
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IUniswapV3Factory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }

    /// @inheritdoc IUniswapV3Factory
    function setFeeProtocol(uint8 fee) external override {
        require(msg.sender == owner);
        feeProtocol = fee;
    }
}
