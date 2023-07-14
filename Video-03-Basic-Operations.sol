// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract IsPrime {
    function isPrime(uint256 x) public pure returns (bool p) {
        p = true;
        assembly {
            /*
             *  The following statement is representatative of:
             *
             *  uint256 halfX = x / 2 + 1
             */
             
             // Yul writes mathematical operations (and pretty much everything) in the form of a function
             // There isn't a notion of an order of operations... The division happens first because it's the innermost function
            let halfX := add(div(x, 2), 1)
            let i := 2
            for {

            } lt(i, halfX) {

            } {
                if iszero(mod(x, i)) {
                    p := 0
                    break
                }

                i := add(i, 1)
            }
        }
    }

    function testPrime() external pure {
        require(isPrime(2));
        require(isPrime(3));
        require(!isPrime(4));
        require(!isPrime(15));
        require(isPrime(23));
        require(isPrime(101));
    }
}

contract IfComparison {
    function isTruthy() external pure returns (uint256 result) {
        result = 2;
        assembly {
            if 2 {
                result := 1
            }
        }

        return result; // returns 1
    }

    function isFalsy() external pure returns (uint256 result) {
        // NOTE: Falsy values in Yul are when all of the bits inside a 32-byte word is 0
        result = 1;
        assembly {
            if 0 {
                result := 2
            }
        }

        return result; // returns 1
    }

    function negation() external pure returns (uint256 result) {
        result = 1;
        assembly {
            if iszero(0) {
                result := 2
            }
        }

        return result; // returns 2
    }

    function unsafe1NegationPart1() external pure returns (uint256 result) {
        result = 1;
        assembly {
            // Generally, in Yul, when trying to negate something, should avoid using not()...
            // Although, this specific example will work as expected because not(0) is TRUE...
            if not(0) {
                result := 2
            }
        }

        return result; // returns 2
    }

    function bitFlip() external pure returns (bytes32 result) {
        assembly {
            /*
             * When using not() on a value that is not 0, it's going to flip all of the bits and return a non-zero value...
             * For example, the result of the following code is:
             *
             * 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd
             *
             * This is the result of flipping all of the bits in the 32-byte hexadecimal representation of 2 which is:
             *
             * 0x0000000000000000000000000000000000000000000000000000000000000002
             */
            result := not(2)
        }
    }

    function unsafe2NegationPart() external pure returns (uint256 result) {
        result = 1;
        assembly {
            if not(2) {
                result := 2
            }
        }

        return result; // returns 2
    }

    function safeNegation() external pure returns (uint256 result) {
        result = 1;
        assembly {
            if iszero(2) {
                result := 2
            }
        }

        return result; // returns 1
    }

    function max(uint256 x, uint256 y) external pure returns (uint256 maximum) {
        assembly {
            if lt(x, y) {
                maximum := y
            }
            if iszero(lt(x, y)) {
                // NOTE: There is no ELSE in Yul, so we have to explicitly check the else scenarios with another IF statement...
                maximum := x
            }
        }
    }

    // The rest (These are ALWAYS bitwise operations and operations on 32-byte words):
    /*
        | solidity | YUL       |
        +----------+-----------+
        | a && b   | and(a, b) |
        +----------+-----------+
        | a || b   | or(a, b)  |
        +----------+-----------+
        | a ^ b    | xor(a, b) |
        +----------+-----------+
        | a + b    | add(a, b) |
        +----------+-----------+
        | a - b    | sub(a, b) |
        +----------+-----------+
        | a * b    | mul(a, b) |
        +----------+-----------+
        | a / b    | div(a, b) |
        +----------+-----------+
        | a % b    | mod(a, b) |
        +----------+-----------+
        | a >> b   | shr(b, a) |
        +----------+-----------+
        | a << b   | shl(b, a) |
        +----------------------+

    */
}
