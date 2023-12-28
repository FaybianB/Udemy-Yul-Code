// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Log {
    event SomeLog(uint256 indexed a, uint256 indexed b);
    event SomeLogV2(uint256 indexed a, bool);
    event SomeLogV3(uint256[] a, uint256[] b);

    function emitLog() external {
        emit SomeLog(5, 6);
    }

    function yulEmitLog() external {
        assembly {
            // keccak256("SomeLog(uint256,uint256)")
            let
                signature
            := 0xc200138117cf199dd335a2c6079a6e1be01e6592b6a76d4b5fc31b169df819cc
            
            /*
            * In Yul, the `log3()` function is used to emit a log with three topics.
            * It takes four arguments:
            *
            * 1. Start of Data: The start of data argument specifies the memory position where the log data begins.
            *    It is passed as the first argument to `log3()`.
            *    This argument indicates the memory location of the log's data payload.
            *
            * 2. Size of Data: The size of data argument specifies the length of the log data in bytes.
            *    It is passed as the second argument to `log3()`.
            *    This argument represents the size of the data payload being logged.
            *
            * 3. First Topic: The first topic argument represents the first topic of the log.
            *    It is passed as the third argument to `log3()`.
            *    A topic is a 32-byte value that can be used to categorize and filter logs.
            *
            * 4. Second Topic: The second topic argument represents the second topic of the log.
            *    It is passed as the fourth argument to `log3()`.
            *
            * 5. Third Topic: The third topic argument represents the third topic of the log.
            *    It is passed as the fifth argument to `log3()`.
            */

            // Since all of the arguments are indexed, we don't have to look in memory for the log data
            log3(0, 0, signature, 5, 6)
        }
    }

    function v2EmitLog() external {
        emit SomeLogV2(5, true);
    }

    function v2YulEmitLog() external {
        assembly {
            // keccak256("SomeLogV2(uint256,bool)")
            let
                signature
            := 0x113cea0e4d6903d772af04edb841b17a164bff0f0d88609aedd1c4ac9b0c15c2
            mstore(0x00, 1)
            // Since bool is not indexed, we specify where in memory we find it's value and it's number of bytes (0x20 = 32)
            log2(0, 0x20, signature, 5)
        }
    }

    function v3YulEmitLog() external {
        assembly {
            let signature := 0x9d3a01189f186eed5f1f1326d8e4b1d74107d7e987d545a27638e7efe98c961c

            mstore(0x00, 0x40)
            mstore(0x20, 0x80)
            mstore(0x40, 1)
            mstore(0x60, 99)
            mstore(0x80, 1)
            mstore(0xa0, 25)

            log1(0x00, msize(), signature)
        }
    }

    function boom() external {
        assembly {
            selfdestruct(caller())
        }
    }
}
