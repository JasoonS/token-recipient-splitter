// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./test/utils/Console.sol";
import "./TestERC20.sol";

contract Splitter {
    TestERC20 public paymentToken;
    mapping(address => bool) public isRecipient;
    mapping(uint256 => address) public allRecipients;
    uint256 public numberOfRecipients;

    uint256 public latestPaymentIndex;
    mapping(uint256 => uint256) public paymentCheckpoint;
    mapping(address => uint256) public recipientLatestCheckpoint;

    modifier onlyRecipient(address recipient) {
        require(isRecipient[recipient], "not recipient");
        _;
    }

    constructor(address[] memory initialRecipients, TestERC20 _paymentToken) {
        paymentToken = _paymentToken;

        numberOfRecipients = initialRecipients.length;
        for (uint256 i = 0; i < initialRecipients.length; ++i) {
            isRecipient[initialRecipients[i]] = true;
            allRecipients[i] = initialRecipients[i];
        }
    }

    function removeRecipient(address recipient)
        public
        onlyRecipient(recipient)
    {
        uint256 updatedNumberOfRecipients = numberOfRecipients - 1;
        for (uint256 i = 0; i < updatedNumberOfRecipients; ++i) {
            // allRecipients[i] = initialRecipients[i];
            address currentRecipient = allRecipients[i];
            _claimPayments(currentRecipient);
            if (currentRecipient == recipient) {
                address lastRecipient = allRecipients[
                    updatedNumberOfRecipients
                ];
                _claimPayments(lastRecipient);
                allRecipients[i] = lastRecipient;
            }
        }

        numberOfRecipients = updatedNumberOfRecipients;
        isRecipient[recipient] = false;
    }

    function addRecipient(address recipient) public {
        require(!isRecipient[recipient], "already a recipient");

        uint256 numberOfRecipientsMemory = numberOfRecipients;
        for (uint256 i = 0; i < numberOfRecipientsMemory; ++i) {
            _claimPayments(allRecipients[i]);
        }

        isRecipient[recipient] = true;
        recipientLatestCheckpoint[recipient] = latestPaymentIndex;
        numberOfRecipients = numberOfRecipientsMemory + 1;
    }

    function swapRecipient(
        address previousRecipient,
        address newRecipient,
        uint256 recipientIndex
    ) public {
        require(
            allRecipients[recipientIndex] == previousRecipient,
            "recipient not found at index"
        );
        require(!isRecipient[newRecipient], "already a recipient");

        isRecipient[newRecipient] = true;
        isRecipient[previousRecipient] = false;
        recipientLatestCheckpoint[newRecipient] = latestPaymentIndex;
        allRecipients[recipientIndex] = newRecipient;

        _claimPayments(previousRecipient);
    }

    function splitPay(uint256 amount) public {
        ++latestPaymentIndex;

        paymentCheckpoint[latestPaymentIndex] =
            paymentCheckpoint[latestPaymentIndex - 1] +
            amount;

        // TODO: use safe transfer?
        require(
            paymentToken.transferFrom(msg.sender, address(this), amount),
            "failed payment"
        );
    }

    function _availablePayment(address recipient, uint256 totalRaised)
        internal
        view
        returns (uint256 amountToPayOut)
    {
        amountToPayOut =
            (totalRaised -
                paymentCheckpoint[recipientLatestCheckpoint[recipient]]) /
            numberOfRecipients;
    }

    function availablePayment(address recipient)
        public
        view
        returns (uint256 amountToPayOut)
    {
        amountToPayOut = _availablePayment(
            recipient,
            paymentCheckpoint[latestPaymentIndex]
        );
    }

    function _claimPaymentAmount(address recipient, uint256 amountToPayOut)
        internal
    {
        recipientLatestCheckpoint[recipient] = latestPaymentIndex;
        require(
            paymentToken.transfer(recipient, amountToPayOut),
            "Failed payment"
        );
    }

    function _claimPayments(address recipient)
        internal
        onlyRecipient(recipient)
    {
        uint256 amountToPayOut = availablePayment(recipient);
        _claimPaymentAmount(recipient, amountToPayOut);
    }

    function claimPayments() public {
        _claimPayments(msg.sender);
    }

    function claimPaymentsFor(address recipient) public {
        _claimPayments(recipient);
    }
}
