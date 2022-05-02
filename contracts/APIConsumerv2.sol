// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title The APIConsumer contract
 * @notice An API Consumer contract that makes GET requests to obtain 24h trading volume of ETH in USD
 */
contract APIConsumer is ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 public volume;
  address private immutable oracle;
  bytes32 private immutable jobId;
  uint256 private immutable fee;

  event DataFullfilled(uint256 volume);
  /**
   * Network: Rinkeby
   * Chainlink token id on rinkeby: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
   * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8
   * Job ID: 6b88e0402e5d415eb946e528b8e0c7ba 
   * Fee: 0.1 LINK
   */
  constructor() {
    setChainlinkToken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
    oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
    jobId = "6b88e0402e5d415eb946e528b8e0c7ba";
    fee = 0.1 * 10 ** 18; // (Varies by network and job)
  }
  /**
   * @notice Creates a Chainlink request to retrieve API response, find the target
   * data, then multiply by 1000000000000000000 (to remove decimal places from data).
   *
   * @return requestId - id of the request
   */
  function requestVolumeData() public returns (bytes32 requestId) {
    Chainlink.Request memory request = buildChainlinkRequest(
      jobId,
      address(this),
      this.fulfill.selector
    );

    // Set the URL to perform the GET request on
    request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD");

    // Set the path to find the desired data in the API response, where the response format is:
    // {"RAW":
    //   {"ETH":
    //    {"USD":
    //     {
    //      "VOLUME24HOUR": xxx.xxx,
    //     }
    //    }
    //   }
    //  }
    // request.add("path", "RAW.ETH.USD.VOLUME24HOUR"); // Chainlink nodes prior to 1.0.0 support this format
    request.add("path", "RAW,ETH,USD,VOLUME24HOUR"); // Chainlink nodes 1.0.0 and later support this format

    // Multiply the result by 1000000000000000000 to remove decimals
    int256 timesAmount = 10**18;
    request.addInt("times", timesAmount);

    // Sends the request
    return sendChainlinkRequestTo(oracle, request, fee);
  }

  /**
   * @notice Receives the response in the form of uint256
   *
   * @param _requestId - id of the request
   * @param _volume - response; requested 24h trading volume of ETH in USD
   */
  function fulfill(bytes32 _requestId, uint256 _volume)
    public
    recordChainlinkFulfillment(_requestId)
  {
    volume = _volume;
    emit DataFullfilled(volume);
  }

  /**
   * @notice Witdraws LINK from the contract
   * @dev Implement a withdraw function to avoid locking your LINK in the contract
   */
  function withdrawLink() external {}
}