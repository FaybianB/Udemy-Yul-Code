//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract YulTypes {
    function getNumber() external pure returns (uint256) {
        /* 
         * The following code is equivalent to:
         *
         * uint256 x = 42;
         */

        // NOTE: Yul only has 1 (ONE) type, the 32-byte word / 256-bits in Solidity
        uint256 x;

        assembly {
            x := 42
        }

        // Returns 42
        return x;
    }

    function getHex() external pure returns (uint256) {
        // NOTE: Solidity interprets the hexadecimal value as decimal when it's in a uint256 (& possibily all uints)
        uint256 x;

        assembly {
            // 0xa is the hexadecimal representation of decimal 10 
            x := 0xa
        }

        // Returns 10
        return x;
    }

    function demoString() external pure returns (string memory) {
        /* 
         *  NOTE: A string IS NOT naturally bytes32... bytes32 is always stored on the stack
         *
         *  Given the above, the following declaration would pass the compile check but ultimately would not return the correct value:
         *
         *  string memory myString = "";
         *
         *  This is because the string is being stored in memory, on the equivalent of the heap (not on the stack)
        */
        bytes32 myString = "";

        assembly {
            // This attempts to assign the string value to a pointer... the pointer on the stack, to a location in memory
            // This assumes the string we're assigning is less than 32 bytes... the compiler will throw an error because the string literal is too long 
            myString := "lorem ipsum dolor set amet..."
        }

        // This would return the bytes32 (hexadecimal) representation of the string
        // return myString;

        // Returns the string representation, as set in the assembly block
        return string(abi.encode(myString));
    }

    function representation() external pure returns (address) {
        // bool x;
        // uint16 x;
        address x;

        assembly {
            x := 1
        }

        // Returns true for bool
        // Returns 1 for uint16
        // Returns 0x0000000000000000000000000000000000000001 for address
        return x;
    }
}
