// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/**
     To Learn

1. calldataload - always loads in increments of 32 bytes
2. imitating function selectors - shift right everything except the first 4 bytes
3. switch statement - in Yul but not Solidity
4. yul functions with arguments - 
5. functions that return
6. exit from a function without returning
7. validating calldata - In Solidity it's done automatically but in Yul the process is manual

**/

contract CalldataDemo {
    fallback() external {
        assembly {
            let cd := calldataload(0) // always loads 32 bytes
            // d2178b0800000000000000000000000000000000000000000000000000000000
            let selector := shr(0xe0, cd) // shift right 224 bits (28 bytes) to get last 4 bytes
            // 00000000000000000000000000000000000000000000000000000000d2178b08

            // unlike other languages, switch does not "fall through"
            switch selector
            case 0xd2178b08 /* get2() */
            {
                returnUint(2)
            }
            case 0xba88df04 /* get99(uint256) */
            {
                returnUint(getNotSoSecretValue())
            }
            default {
                revert(0, 0)
            }

            function getNotSoSecretValue() -> r {
                // Ensure the calldata size is at least 36 bytes (function selector + argument)
                if lt(calldatasize(), 36) {
                    revert(0, 0)
                }

                // Loads the argument from calldata, skipping the function selector (first 4 bytes)
                let arg1 := calldataload(4)
                if eq(arg1, 8) {
                    r := 88
                    // Stops the execution inside the function and returns to where we originally were
                    leave
                }
                // Returns the value of r and stays within the execution of the Yul code
                r := 99
            }

            function returnUint(v) {
                mstore(0, v)
                // This return hands control back to the calling contract and end execution of this contract
                // This DOES NOT return back to the Yul code
                return(0, 0x20)
            }
        }
    }
}

interface ICalldataDemo {
    function get2() external view returns (uint256);

    function get99(uint256) external view returns (uint256);
}

contract CallDemo {
    ICalldataDemo public target;

    constructor(ICalldataDemo _a) {
        target = _a;
    }

    function callGet2() external view returns (uint256) {
        return target.get2();
    }

    function callGet99(uint256 arg) external view returns (uint256) {
        return target.get99(arg);
    }
}
