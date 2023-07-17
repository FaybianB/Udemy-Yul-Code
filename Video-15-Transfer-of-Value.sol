//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract WithdrawV1 {
    constructor() payable {}

    address public constant owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function withdraw() external {
        // Bad practice
        // payable(owner).transfer(address(this).balance);
        (bool s, ) = payable(owner).call{value: address(this).balance}("");
        require(s);
    }
}

contract WithdrawV2 {
    constructor() payable {}

    address public constant owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    function withdraw() external {
        assembly {
            /*
             * In the case of the transfer() above, it hardcodes the gas to 2300 to
             * limit the risk of reentrancy.
             */
            // let s := call(2300, owner, selfbalance(), 0, 0, 0, 0)
            /* 
             * This is identical to the .call{} above, it sends the contract's balance 
             * to an address. However, this call in Yul is more gas efficient.
             */
            let s := call(gas(), owner, selfbalance(), 0, 0, 0, 0)
            if iszero(s) {
                revert(0, 0)
            }
        }
    }
}
