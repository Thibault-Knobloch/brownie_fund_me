// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        // this will be executed the instance the contract is deployed, will never be called again
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimum USD to fund
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // the underscore represents the place where the code will run after the modifier
    }

    function fund() public payable {
        // add a minmum amount to be a funder
        uint256 minimumUSD = 50 * 10**18; // to make the minimum 5 USD

        // basically an if statement, but require is the convention
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH."
        );

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // needs an address to work (where the interface is located),
        // that address is different based on the network you deploy on

        // need to deploy this at leaast on a test net, because the interface contract
        // is not located in the javascript VM
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // this will convert to WEI
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // because 1 WEI = 1000000000000000000 ETH and the conversion rate we got is USD to ETH!! not WEI
        return ethAmountInUsd;
    }

    function withdraw() public payable onlyOwner {
        // we want that only the contract creator can withdraw money
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
