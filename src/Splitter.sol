// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./test/utils/Console.sol";
import "./TestERC20.sol";

contract Splitter {
    TestERC20 public paymentToken;
    mapping(address => bool) public isRecipient;
    uint256 public numberOfRecipients;

    modifier onlyRecipient() {
        require(isRecipient[msg.sender], "not recipient");
        _;
    }

    constructor(address[] memory initialRecipients, TestERC20 _paymentToken) {
        paymentToken = _paymentToken;
        // TODO
        console.log("Fill this function in");
        console.log(initialRecipients);
    }

    function splitPay(uint256 amount) public {
        // TODO
        console.log("Fill this function in", amount);
    }

    function claimPayments() public onlyRecipient {
        // TODO
        console.log("Fill this function in");
    }
}
