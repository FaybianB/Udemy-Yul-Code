// SPDX-License-Identifier: GPL-3.0

/** 
    To Learn

    1. constructor
    2. yul doesn't have to respect call data
    3. how to compile yul - Change the compiler type from Solidity to Yul
    4. how to interact with yul
    5. custom code in the constructor

**/
// NOTE: There are no function selectors because that's a Solidity concept
// NOTE: 100% Yul codes is not able to be published on Etherscan because Yul is not an option
object "Simple" {
    // Constructor
    code {
        /*
         * Code Breakdown:
         *
         * 1) Look inside of "runtime"
         * 2) Get the size of "runtime"
         * 3) Copy the size into memory
         */
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        
        // Return the area in memory where the size of "runtime" is stored
        return(0, datasize("runtime"))        
    }

    object "runtime" {
        
        code {
            // Stores 2 in memory
            mstore(0x00, 2)
            // Returns 2 from memory
            return(0x00, 0x20)
        }
    }
}