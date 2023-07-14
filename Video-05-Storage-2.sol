// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract StoragePart1 {
    uint128 public C = 4;
    uint96 public D = 6;
    uint16 public E = 8;
    uint8 public F = 1;

    function readBySlot(uint256 slot) external view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }

    // NEVER DO THIS IN PRODUCTION
    function writeBySlot(uint256 slot, uint256 value) external {
        assembly {
            sstore(slot, value)
        }
    }

    // masks can be hardcoded because variable storage slot and offsets are fixed
    // V and 00 = 00
    // V and FF = V
    // V or  00 = V
    // function arguments are always 32 bytes long under the hood
    function writeToE(uint16 newE) external {
        assembly {
            /*
             * Even though the parameter is specified as a uint16, Yul is going to treat it as
             * a 256-bit value and interpret it as:
             * 
             * newE = 0x000000000000000000000000000000000000000000000000000000000000000a
             */
            let c := sload(E.slot) // slot 0
            // c = 0x0000010800000000000000000000000600000000000000000000000000000004
            let clearedE := and(
                c,
                0xffff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            // mask     = 0xffff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            // c        = 0x0001000800000000000000000000000600000000000000000000000000000004
            // clearedE = 0x0001000000000000000000000000000600000000000000000000000000000004
            let shiftedNewE := shl(mul(E.offset, 8), newE)
            // shiftedNewE = 0x0000000a00000000000000000000000000000000000000000000000000000000
            let newVal := or(shiftedNewE, clearedE)
            // shiftedNewE = 0x0000000a00000000000000000000000000000000000000000000000000000000
            // clearedE    = 0x0001000000000000000000000000000600000000000000000000000000000004
            // newVal      = 0x0001000a00000000000000000000000600000000000000000000000000000004
            sstore(C.slot, newVal)
        }
    }

    function getOffsetE() external pure returns (uint256 slot, uint256 offset) {
        assembly {
            slot := E.slot
            // The offset tells us at which position in the slot we can find the value for the variable
            /* 
             * For example, the return here is 28... that translates to "If you read 28 bytes to the left
             * (starting at the end of the bytecode) you can find the variable"
             */
            offset := E.offset
        }
    }

    function readE() external view returns (uint256 e) {
        assembly {
            let value := sload(E.slot) // must load in 32 byte increments
            // E.offset = 28
            /* 
             * NOTE: offset() returns the number of bytes to shift the bytecode in order to locate the variable
             * data, however, shr() expects bits so we multiply the offset x 8 (number of bits in a byte)
            */
            /*
             * Before the shift right operation, the slot looks like this:
             *
             * 0x0001000800000000000000000000000600000000000000000000000000000004
            */
            let shifted := shr(mul(E.offset, 8), value)
            // 0x0000000000000000000000000000000000000000000000000000000000010008
            // equivalent to
            // 0x000000000000000000000000000000000000000000000000000000000000ffff
            e := and(0xffff, shifted)
        }
    }

    function readEalt() external view returns (uint256 e) {
        assembly {
            let slot := sload(E.slot)
            let offset := sload(E.offset)
            let value := sload(E.slot) // must load in 32 byte increments

            // NOTE: This is equivalent to shr() but it's less efficient because it costs more gas
            // shift right by 224 (28 bytes) = divide by (2 ** 224). below is 2 ** 224 in hex
            let shifted := div(
                value,
                0x100000000000000000000000000000000000000000000000000000000
            )
            e := and(0xffff, shifted)
        }
    }
}
