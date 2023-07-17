// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract StorageComplex {
    // Fixed array values are stored in the slots sequentially
    uint256[3] fixedArray;
    // Dynamic arrays ARE NOT stored in the slots sequentially because they could cause collisions with slots below them
    uint256[] bigArray;
    uint8[] smallArray;

    mapping(uint256 => uint256) public myMapping;
    mapping(uint256 => mapping(uint256 => uint256)) public nestedMapping;
    mapping(address => uint256[]) public addressToList;

    constructor() {
        fixedArray = [99, 999, 9999];
        bigArray = [10, 20, 30, 40];
        smallArray = [1, 2, 3];

        myMapping[10] = 5;
        myMapping[11] = 6;
        nestedMapping[2][4] = 7;

        addressToList[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = [42, 1337, 777];
    }

    function fixedArrayView(uint256 index) external view returns (uint256 ret) {
        assembly {
            // Add the index to the array slot in order to get the particular array value at the specified index...
            // Return fixedArray[index]
            ret := sload(add(fixedArray.slot, index))
        }
    }

    function bigArrayLength() external view returns (uint256 ret) {
        assembly {
            // Loading an array's slot will return the length of the array
            ret := sload(bigArray.slot)
        }
    }

    function readBigArrayLocation(uint256 index) external view returns (uint256 ret)
    {
        uint256 slot;
        assembly {
            slot := bigArray.slot
        }
        /*
         * This is Solidity's methodology for storing dynamic arrays
         * because keccak256() produces a 256-bit hash, whose location
         * is unlikely to contain other data
         * For example:
         *
         * Storage slots:
         * p = length of the array
         * keccak256(p) = value of index 0
         * keccak256(p) + 1 = value of index 1
         * etc...
        */
        /* 
         * The abi.encode is needed because in Solidity, a hash function
         * must first have the data input encoded because hash functions
         * operate on binary data. Encoding the data input ensures that
         * the input is properly represented in a binary format (such as byte-code)
         * that can be processed by the hash function.
        */
        bytes32 location = keccak256(abi.encode(slot));

        assembly {
            ret := sload(add(location, index))
        }
    }

    function readSmallArray() external view returns (uint256 ret) {
        assembly {
            // Loading an array's slot will return the length of the array
            ret := sload(smallArray.slot)
        }
    }

    function readSmallArrayLocation(uint256 index) external view returns (bytes32 ret) {
        uint256 slot;
        assembly {
            slot := smallArray.slot
        }
        bytes32 location = keccak256(abi.encode(slot));

        assembly {
            ret := sload(add(location, index))
        }
    }

    function getMapping(uint256 key) external view returns (uint256 ret) {
        uint256 slot;
        assembly {
            /*
             * For mappings, this slot stays empty, but it is still needed to ensure
             * that even if there are two mappings next to each other, their content
             * ends up at different storage locations.
            */
            slot := myMapping.slot
        }

        /*
         * This is Solidity's methodology for storing mappings. Mappings concatenate
         * the key with the storage slot in order to store the values.
         * For example:
         *
         * Storage slots:
         * p = (empty)
         * keccak256(key . p) = value of key
        */
        bytes32 location = keccak256(abi.encode(key, uint256(slot)));

        assembly {
            ret := sload(location)
        }
    }

    function getNestedMapping() external view returns (uint256 ret) {
        uint256 slot;
        assembly {
            slot := nestedMapping.slot
        }

        bytes32 location = keccak256(
            abi.encode(
                uint256(4),
                keccak256(abi.encode(uint256(2), uint256(slot)))
            )
        );
        assembly {
            ret := sload(location)
        }
    }

    function lengthOfNestedList() external view returns (uint256 ret) {
        uint256 addressToListSlot;
        assembly {
            addressToListSlot := addressToList.slot
        }

        // Produces the location of the dynamic array's base storage slot associated with this key (address)
        bytes32 location = keccak256(
            abi.encode(
                // Key whose value we want to retrieve
                address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4),
                // Slot for the mapping
                uint256(addressToListSlot)
            )
        );
        assembly {
            ret := sload(location)
        }
    }

    function getAddressToList(uint256 index) external view returns (uint256 ret) {
        uint256 slot;
        assembly {
            slot := addressToList.slot
        }

        // Produces the starting location of the dynamic array's values (index 0) for the given (address) key
        bytes32 location = keccak256(
            abi.encode(
                // Produces the location of the dynamic array's base storage slot associated with this (address) key
                keccak256(
                    abi.encode(
                        // Key whose value we want to retrieve
                        address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4),
                        // Slot for the mapping
                        uint256(slot)
                    )
                )
            )
        );
        assembly {
            ret := sload(add(location, index))
        }
    }
}
