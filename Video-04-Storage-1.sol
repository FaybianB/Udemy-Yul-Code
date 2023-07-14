// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// (variable name).slot returns the slot that the variable data is stored in, it DOES NOT return the variable data...
// The slot is determined at compile time.
contract StorageBasics {
    // Slot 0
    uint256 x = 2;
    // Slot 1
    uint256 y = 13;
    // Slot 2
    uint256 z = 54;
    // Slot 3
    uint256 p;
    // Slots are packed to fit 256-bits, so the following uint128 values will be in the same slot...
    // If the variable type doesn't fit in the amount of bits left in current 256-bit slot then it's stored in the next slot.
    // Slot 4
    uint128 a = 1;
    // Slot 4
    uint128 b = 2;

    function getP() external view returns (uint256) {
        return p;
    }

    function getVarYul(uint256 slot) external view returns (bytes32 ret) {
        assembly {
            // sload() loads the data in the specified slot
            // If the slot doesn't have data, 0 is returned
            ret := sload(slot)
        }
    }

    function setVarYul(uint256 slot, uint256 value) external {
        assembly {
            // sstore() stores data in the specified slot
            // This will overwrite any existing data in the slot
            sstore(slot, value)
        }
    }

    function setX(uint256 newVal) external {
        x = newVal;
    }

    function getX() external view returns (uint256) {
        return x;
    }
}
