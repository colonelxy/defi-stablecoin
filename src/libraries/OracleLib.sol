// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
*@title OracleLib
*@author Harold A - harold2@protonmail.com
*@notice This library is used to check Chainlink for state data
* If the price feed is stale, the DSCEngine will revert. This is to prevent users from minting DSC with stale price data, which could lead to undercollateralization and potential insolvency of the protocol.
* We want the DSCEngine to freeze if the prices are stale.
* If you have a lot of money locked in the protocol and the Chainlink network explodes, too bad.
*/

library OracleLib {
    error OracleLib__StalePrice();
    uint256 private constant TIMEOUT = 3 hours;  // 3 * 60 * 60 = 10800 seconds
    function staleCheckLatestRoundData(AggregatorV3Interface priceFeed) public view returns(uint80, int256, uint256, uint256, uint80){
    (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)= priceFeed.latestRoundData();
    uint256 secondsSinceLastUpdate = block.timestamp - updatedAt;
    if(secondsSinceLastUpdate > TIMEOUT){
        revert OracleLib__StalePrice();
    }
    return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
}