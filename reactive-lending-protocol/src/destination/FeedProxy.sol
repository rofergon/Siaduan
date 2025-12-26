// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IAggregatorV3Interface.sol";

/**
 * @title FeedProxy
 * @notice Receives price updates from ReactOracleHub and serves them via AggregatorV3Interface.
 */
contract FeedProxy is IAggregatorV3Interface {
    struct RoundData {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    // Immutable configuration
    address public immutable callbackProxy;
    address public immutable authorizedReactVM;
    
    // Feed Metadata
    uint8 public override decimals;
    string public override description;
    uint256 public constant override version = 1;

    // State
    uint80 public latestRoundId;
    mapping(uint80 => RoundData) public rounds;

    // Events
    event PriceUpdated(uint80 indexed roundId, int256 answer, uint256 updatedAt);

    /**
     * @param _callbackProxy Address of the Reactive Network Callback Proxy on this chain
     * @param _authorizedReactVM Address of the ReactOracleHub (ReactVM ID) authorized to update this feed
     * @param _decimals Decimal precision of the feed
     * @param _description Description of the feed
     */
    constructor(
        address _callbackProxy,
        address _authorizedReactVM,
        uint8 _decimals,
        string memory _description
    ) {
        require(_callbackProxy != address(0), "Invalid callback proxy");
        require(_authorizedReactVM != address(0), "Invalid authorized RVM");
        callbackProxy = _callbackProxy;
        authorizedReactVM = _authorizedReactVM;
        decimals = _decimals;
        description = _description;
    }

    modifier onlyReactive() {
        require(msg.sender == callbackProxy, "Caller must be Callback Proxy");
        _;
    }

    /**
     * @notice Updates the price feed. Called by ReactOracleHub via Reactive Network.
     * @dev The first argument `_sender` is injected by the Reactive Network Callback Proxy.
     * It MUST match the authorizedReactVM address.
     */
    function updatePrice(
        address _sender,
        uint80 _roundId,
        int256 _answer,
        uint256 _startedAt,
        uint256 _updatedAt,
        uint80 _answeredInRound
    ) external onlyReactive {
        require(_sender == authorizedReactVM, "Unauthorized ReactVM sender");
        
        // Ensure strictly increasing updates (optional but good for consistency)
        // Note: In some cases, we might want to allow backfilling or out-of-order if timestamps are respected,
        // but generally we want the latest state. We'll use roundId to check freshness.
        // Assuming roundIds are globally increasing from the source. 
        // If the source resets roundID (e.g. aggregator upgrade), this logic might need adjustment (phase id).
        // For this hackathon, simple roundId check is sufficient.
        require(_roundId > latestRoundId, "Stale or older round ID");
        require(_updatedAt > 0, "Invalid timestamp");

        rounds[_roundId] = RoundData({
            answer: _answer,
            startedAt: _startedAt,
            updatedAt: _updatedAt,
            answeredInRound: _answeredInRound
        });

        latestRoundId = _roundId;
        
        emit PriceUpdated(_roundId, _answer, _updatedAt);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = latestRoundId;
        RoundData storage round = rounds[roundId];
        return (roundId, round.answer, round.startedAt, round.updatedAt, round.answeredInRound);
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        RoundData storage round = rounds[_roundId];
        require(round.updatedAt != 0, "No data for round");
        return (_roundId, round.answer, round.startedAt, round.updatedAt, round.answeredInRound);
    }
}
