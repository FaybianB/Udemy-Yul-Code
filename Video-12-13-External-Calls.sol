// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// NOTE: Tx.data can be arbitrary (only constrained by gas cost)
// The longer the Tx.data array, the more the user pays to send the transaction
/*
 * Convention
 *
 * - Solidity's dominance has forced a convention on how tx.data is used
 * - When sending to a wallet, you don't put any data in unless you are trying
 *   to send that person a message (hackers have used this field for taunts)
 * - When sending to a smart contract, the first four bytes specify which function
 *   you are calling, and the bytes that follow are the abi.encoded function arguments
 * - Solidity expects the bytes after the function selector to always be a multiple of
 *   32 in length, but this is convention.
 * - If you send more bytes, Solidity will ignore them.
 * - But a Yul smart contract can be programmed to respond to any arbitrary length tx.data
 *   in an arbitrary manner
 */
/*
 * Overview
 *
 * - Function selectors are the first four bytes of the keccak256 of the function selector
 * - balanceOf(address _address) -> keccak256("balanceOf(address)") -> 0x70a08231
 * - balanceOf(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4) -> 0x70a082310000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4
 * - balanceOf(address _address, uint256) -> keccak256("balanceOf(address,uint256)") -> 0x00fdd58e
 * - The result of abi.encode() is always a multiple of 32 bytes
 * - balanceOf(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 5) -> 0x00fdd58e0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC40000000000000000000000000000000000000000000000000000000000000005
 * - The above example features a uint256 as the second argument but even if the uint was another size, like uint8, the abi.encoded value will always be 32-bytes, thus, it would be the same
 */ 
/*
 * ABI Specification
 *
 * - Front-end apps know to format the transaction based on the abi specification of the contract
 * - In Solidity, the function selector and 32-byte arguments are created under the hood by interfaces or if you use abi.encodeWithSignature("balanceOf(address)", 0x...)
 * - But in Yul, you have to be explicit
 * - It doesn't know about function selectors, interfaces or abi encoding
 * - If you want to make an external call to a Solidity contract, you implement all of that yourself
 */
contract OtherContract {
    // "0c55699c": "x()"
    uint256 public x;

    // "71e5ee5f": "arr(uint256)",
    uint256[] public arr;

    // "9a884bde": "get21()",
    function get21() external pure returns (uint256) {
        return 21;
    }

    // "73712595": "revertWith999()",
    function revertWith999() external pure returns (uint256) {
        assembly {
            mstore(0x00, 999)
            // This behaves the same way as "return", since this memory location is populated with data (999)
            revert(0x00, 0x20)
        }
    }

    // "4018d9aa": "setX(uint256)"
    function setX(uint256 _x) external {
        x = _x;
    }

    // "196e6d84": "multiply(uint128,uint16)",
    function multiply(uint128 _x, uint16 _y) external pure returns (uint256) {
        return _x * _y;
    }

    // "0b8fdbff": "variableLength(uint256[])",
    function variableLength(uint256[] calldata data) external {
        arr = data;
    }

    // "7c70b4db": "variableReturnLength(uint256)",
    function variableReturnLength(uint256 len)
        external
        pure
        returns (bytes memory)
    {
        bytes memory ret = new bytes(len);
        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = 0xab;
        }
        return ret;
    }

    // Think about how to abi.encode() when a function takes variable length arguments and specifically more than one
    // exercise for the reader #1
    function multipleVariableLength(
        uint256[] calldata data1,
        uint256[] calldata data2
    ) external pure returns (bool) {
        require(data1.length == data2.length, "invalid");

        // this is often better done with a hash function, but we want to enforce
        // the array is proper for this test
        for (uint256 i = 0; i < data1.length; i++) {
            if (data1[i] != data2[i]) {
                return false;
            }
        }
        return true;
    }

    // exercise for the reader #2
    function multipleVariableLength2(
        uint256 max,
        uint256[] calldata data1,
        uint256[] calldata data2
    ) external pure returns (bool) {
        require(data1.length < max, "data1 too long");
        require(data2.length < max, "data2 too long");

        for (uint256 i = 0; i < max; i++) {
            if (data1[i] != data2[i]) {
                return false;
            }
        }
        return true;
    }
}

contract ExternalCalls {
    // get21() 0x9a884bde
    // x() 0c55699c
    function externalViewCallNoArgs(address _a)
        external
        view
        returns (uint256)
    {
        assembly {
            mstore(0x00, 0x9a884bde)
            // 000000000000000000000000000000000000000000000000000000009a884bde
            //                                                         |       |
            //                                                         28      32
            /*
             * staticcall(g, a, in, insize, out, outsize) - calls contract at address
             * (a) while guaranteeing no state changes. The input is memory from (in) to
             * (in + insize) providing g gas and output area memory from (out) to (out + outsize)
             * returning 0 on error (eg. out of gas) and 1 on success.
             */
            let success := staticcall(gas(), _a, 28, 32, 0x00, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            return(0x00, 0x20)
        }
    }

    function getViaRevert(address _a) external view returns (uint256) {
        assembly {
            mstore(0x00, 0x73712595)
            // We don't care about the return value of the staticcall so pop() it off the stack
            pop(staticcall(gas(), _a, 28, 32, 0x00, 0x20))
            return(0x00, 0x20)
        }
    }

    function callMultiply(address _a) external view returns (uint256 result) {
        assembly {
            let mptr := mload(0x40)
            let oldMptr := mptr
            mstore(mptr, 0x196e6d84)
            mstore(add(mptr, 0x20), 3)
            mstore(add(mptr, 0x40), 11)
            mstore(0x40, add(mptr, 0x60)) // advance the memory pointer 3 x 32 bytes
            //  00000000000000000000000000000000000000000000000000000000196e6d84
            //  0000000000000000000000000000000000000000000000000000000000000003
            //  000000000000000000000000000000000000000000000000000000000000000b|<- (free memory pointer is here - after the b)
            let success := staticcall(
                gas(),
                _a,
                // The free memory pointer looks at the beginning of the 32-bytes so we add 28 to it, so it starts reading the first 4 bytes
                add(oldMptr, 28),
                // Since the memory pointer was updated after the function arguments were stored, load the free memory pointer index to know where to stop reading
                mload(0x40),
                0x00,
                0x20
            )
            if iszero(success) {
                revert(0, 0)
            }

            result := mload(0x00)
        }
    }

    // setX
    function externalStateChangingCall(address _a) external {
        assembly {
            mstore(0x00, 0x4018d9aa)
            mstore(0x20, 999)
            // memory now looks like this
            //0x000000000000000000000000000000000000000000000000000000004018d9aa...
            //  0000000000000000000000000000000000000000000000000000000000000009
            let success := call(
                gas(),
                _a,
                // Used to forward the ethereum associated with this call
                // Since this specific function is not "payable", this could be hardcoded to 0 and it'd be more efficient
                callvalue(),
                28,
                add(28, 32),
                0x00,
                0x00
            )
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function unknownReturnSize(address _a, uint256 amount)
        external
        view
        returns (bytes memory)
    {
        assembly {
            mstore(0x00, 0x7c70b4db)
            mstore(0x20, amount)

            let success := staticcall(gas(), _a, 28, add(28, 32), 0x00, 0x00)
            if iszero(success) {
                revert(0, 0)
            }

            // returndatasize() - returns the size of the return data of the last call.
            // returndatacopy(t, f, s) - copies s bytes from the return data from stack to memory, starting from position f and writes it to memory at position t.
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }

    // https://docs.soliditylang.org/en/develop/abi-spec.html#abi
}
