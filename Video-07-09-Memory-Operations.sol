// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
 * Memory Is A Prerequisite
 * 
 * - You need memory  do the following:
 *  - Return values external calls
 *  - Set the function arguments for external calls
 *  - Get values from external calls
 *  - Revert with an error string
 *  - Log messages
 *  - Create other smart contracts
 *  - Use keccak256 hash function
*/
/*
 * Overview
 *
 * - Memory is equivalent to the heap in other languages
 *  - But there is no garbage collector or `free`
 *  - Solidity memory is laid out in 32 byte sequences
 *  - [0x00 - 0x20)[0x20 - 0x40][0x40 - 0x60)[0x60 - 0x80)[0x80 - 0x100)...
 * - Only four instructions: mload, mstore, mstore8, msize
 * - In pure Yul programs, memory is easy to use (it's just an array). But in mixed Solidity/yul programs,
 * Solidity expects memory to be used in a specific manner.
 * - IMPORTANT: You are charged gas for each memory access, and for how far into the memory array you accessed.
 * (It becomes quadratic).
 * - mload(0xffffffffffffffff) will run out of gas.
 * - Using a hash function to mstore like storage does is a bad idea.
 * - mstore(p, v) stores value v in slot p (just like sstore)
 * - mload(p) retrieves 32 bytes from slot p [p..0x20)
 * - mstore8(p, v) like mstore but for 1 byte
 * - msize() largest accessed memory index in that transaction
*/
/*
 * How Solidity Uses Memory
 *
 * - Solidity allocates slots 0 - 63 or [0x00 - 0x20), [0x20 - 0x40) for "scratch space", so items written here will
 * last for the duration of the memory's lifespan
 * - Solidity reserves slot [0x40 - 0x60) as the "free memory pointer"
 * - Solidity keeps [0x60 - 0x80) empty
 * - The action begins in slot [0x80 - ...)
*/
/*
 * How Solidity Uses Memory
 *
 * - Solidity uses memory for
 *  - abi.encode and abi.encodePacked
 *  - Structs and arrays (but you explicitly need the memory keyword)
 *  - When structs or arrays are declared memory in function arguments
 *  - Because objects in memory are laid out end to end, arrays have no push unlike storage
 * - In Yul
 *  - The variable itself is where it begins in memory
 *  - To access a dynamic array, you have to add 32 bytes or 0x20 to skip the length
*/
contract Memory {
    struct Point {
        uint256 x;
        uint256 y;
    }

    event MemoryPointer(bytes32);
    event MemoryPointerMsize(bytes32, bytes32);

    function highAccess() external pure {
        assembly {
            // pop just throws away the return value
            pop(mload(0xffffffffffffffff))
        }
    }

    function mstore8() external pure {
        assembly {
            // In this example, mstore8 stores the value in the first byte of memory slot 0x00
            mstore8(0x00, 7)
            /* 
             * While mstore writes in 32 bytes so since decimal 7 is equivalent to 0000000000000000000000000000000000000000000000000000000000000007
             * in hexadecimal, mstore will preserve the 31-bytes of 0's and write 7 in the last slot of the 32-bytes [0-20) or 0x19.
            */
            // This overwrites the mstore8 instruction.
            mstore(0x00, 7)
        }
    }

    function memPointer() external {
        bytes32 x40;
        
        assembly {
            // This is the location of the free memory pointer... This value is the memory offset for the next available slot in memory
            x40 := mload(0x40)
        }

        // Free memory pointer's offset = 0x80
        emit MemoryPointer(x40);

        // Since each value in the struct is 256 bits, this will shift the free memory pointer by 64 bytes (32-bytes x 2)
        Point memory p = Point({x: 1, y: 2});

        assembly {
            x40 := mload(0x40)
        }

        // Free memory pointer's offset = 0xc0 (0xc0 - 0x80 = 64)
        emit MemoryPointer(x40);
    }

    function memPointerV2() external {
        bytes32 x40;
        bytes32 _msize;
        assembly {
            x40 := mload(0x40)
            _msize := msize()
        }
        // msize() returns 0x60 here because Solidity writes the free memory pointer from [0x40 - 0x60)
        // 0x40, or the memory pointer offset is 0x80 because this is where Solidity begins storing contract data
        // [0x40 - 0x60) is empty
        emit MemoryPointerMsize(x40, _msize);

        Point memory p = Point({x: 1, y: 2});
        assembly {
            // Returns 0xc0
            x40 := mload(0x40)
            // Returns 0xc0
            _msize := msize()
        }
        emit MemoryPointerMsize(x40, _msize);

        assembly {
            // This will cause msize value to change because it's reading / accessing bytes further in memory
            pop(mload(0xff))
            // However, it will not affect the memory pointer's offset (0xc0)
            x40 := mload(0x40)
            // Returns 0x120... mload reads 32-bytes from the provided offset (with furthest offset thus far being 0xff)
            _msize := msize()
        }
        emit MemoryPointerMsize(x40, _msize);
    }

    function fixedArray() external {
        bytes32 x40;
        
        assembly {
            x40 := mload(0x40)
        }
        
        emit MemoryPointer(x40);

        // Behaves the same as the struct example
        uint256[2] memory arr = [uint256(5), uint256(6)];
        
        assembly {
            x40 := mload(0x40)
        }

        // Free memory pointer is set to 0xc0
        emit MemoryPointer(x40);
    }

    function abiEncode() external {
        bytes32 x40;
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);

        // The output of abi.encode() needs to go into storage or memory
        /*
         * abi.encode() affects memory because it stores:
         *  1) the amount of bytes / length of data it's encoding
         *  2) And then the data that it's encoding, here it's uint256(5) and uint256(19)
        */
        abi.encode(uint256(5), uint256(19));

        assembly {
            x40 := mload(0x40)
        }

        // Free memory pointer is 0xe0
        emit MemoryPointer(x40);
    }

    function abiEncode2() external {
        bytes32 x40;
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);

        /* 
         * This causes the same affect as the previous example, although the second parameter is uint128,
         * because abi.encode() pads it's internal values to be 32-bytes
         */
        abi.encode(uint256(5), uint128(19));
        
        assembly {
            x40 := mload(0x40)
        }

        // Free memory pointer is 0xe0
        emit MemoryPointer(x40);
    }

    function abiEncodePacked() external {
        bytes32 x40;
        assembly {
            x40 := mload(0x40)
        }
        emit MemoryPointer(x40);

        // The encodePacked function will pack it's internal values, so the second parameter only consumes 16-bytes
        abi.encodePacked(uint256(5), uint128(19));
       
        assembly {
            x40 := mload(0x40)
        }

        // Free memory pointer is 0xd0
        emit MemoryPointer(x40);
    }

    event Debug(bytes32, bytes32, bytes32, bytes32);

    function args(uint256[] memory arr) external {
        bytes32 location;
        bytes32 len;
        bytes32 valueAtIndex0;
        bytes32 valueAtIndex1;

        assembly {
            // Returna the location of the array in memory
            location := arr
            // Dynamic arrays in memory store the length of the array at the array's location
            len := mload(arr)
            // Jump over the array's length value to get the elements
            valueAtIndex0 := mload(add(arr, 0x20))
            valueAtIndex1 := mload(add(arr, 0x40))
            // ...
        }

        emit Debug(location, len, valueAtIndex0, valueAtIndex1);
    }

    function breakFreeMemoryPointer(uint256[1] memory foo) external view returns (uint256) {
        /*
         * This rewrites the free memory pointer to point to 0x80, even though this memory slot
         * has been written to already to store the parameter foo.
         */
        assembly {
            mstore(0x40, 0x80)
        }

        /* 
         * Since foo is stored at at 0x80 and the free memory pointer is still pointed at 0x80, this
         * operation will overwrite foo with bar
         */
        uint256[1] memory bar = [uint256(6)];
        
        return foo[0];
    }

    uint8[] foo = [1, 2, 3, 4, 5, 6];

    /*
     * Gotchas
     *
     * - The Solidity compiler memory does not try to pack datatypes smaller than 32 bytes, unlike storage...
     * (For example, in storage, if there were uint8s next to each other, Solidity would try to pack them into
     * the same slot)
     * - If you load from storage to memory, it will be unpacked
     */
    function unpacked() external {
        // Each uint8 will be unpacked into it's own slot
        uint8[] memory bar = foo;
    }
}
