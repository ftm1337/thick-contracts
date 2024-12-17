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

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
