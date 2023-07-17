// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract UsingMemory {
    function return2and4() external pure returns (uint256, uint256) {
        assembly {
            mstore(0x00, 2)
            mstore(0x20, 4)

            // Returns the boundaries of the area in memory that we are trying to return
            return(0x00, 0x40)
        }
    }

    function requireV1() external view {
        require(msg.sender == 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    }

    function requireV2() external view {
        assembly {
            if iszero(eq(caller(), 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2)) {
                // Need to specify an area in memory to return
                /* 
                 * It's still possible to return data in a revert case so that the calling function
                 * can respond to it. Most times, however, when reverts happen, we want to stop execution
                 * and not return values, so 0, 0 is used as the revert parameters.
                 */
                revert(0, 0)
            }
        }
    }

    function hashV1() external pure returns (bytes32) {
        // In regular Soldity, keccak256 takes a variable that's of type bytes memory
        // We're hashing the sequence uint256(1), uint256(2) and uint256(3) laid out end to end in memory 
        bytes memory toBeHashed = abi.encode(1, 2, 3);

        return keccak256(toBeHashed);
    }

    function hashV2() external pure returns (bytes32) {
        assembly {
            let freeMemoryPointer := mload(0x40)

            // store 1, 2, 3 in memory
            mstore(freeMemoryPointer, 1)
            mstore(add(freeMemoryPointer, 0x20), 2)
            mstore(add(freeMemoryPointer, 0x40), 3)
            // update memory pointer
            // increase memory pointer by 96 bytes
            mstore(0x40, add(freeMemoryPointer, 0x60))
            // keccak256 takes the starting point in memory and number of bytes to be hashed as parameters
            mstore(0x00, keccak256(freeMemoryPointer, 0x60))
            
            // Techincally, we could return more or less bytes than was specified in the returns and the transaction
            // would succeed, although, the client might error because it's expecting 32 bytes.
            // return(0x00, 0x60)
            return (0x00, 0x20)
        }
    }
}
