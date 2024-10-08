// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BettingMarket is ReentrancyGuard, Ownable, Pausable {
    // Bet amounts in USD
    uint256 public constant BET_AMOUNT_1 = 1;
    uint256 public constant BET_AMOUNT_10 = 10;
    uint256 public constant BET_AMOUNT_100 = 100;

    // RBTC to USD rate (updated by owner)
    uint256 public rbtcToUsdRate;

    // Betting duration in seconds (5 minutes)
    uint256 public constant BETTING_DURATION = 5 * 60;

    struct Bet {
        uint256 amount;
        bool claimed;
    }

    struct Event {
        uint256 id;
        bool resolved;
        bool result;
        uint256 totalBetsA;
        uint256 totalBetsB;
        uint256 startTime;
        mapping(address => Bet) betsA;
        mapping(address => Bet) betsB;
    }

    uint256 public currentEventId;
    Event public currentEvent;

    event EventCreated(uint256 indexed eventId, uint256 startTime);
    event BetPlaced(uint256 indexed eventId, address indexed bettor, bool outcome, uint256 amount);
    event EventResolved(uint256 indexed eventId, bool result);
    event Payout(uint256 indexed eventId, address indexed bettor, uint256 amount);
    event RbtcToUsdRateUpdated(uint256 newRate);

//constructor(uint256 _initialRbtcToUsdRate) Ownable(msg.sender) {
    constructor() Ownable(msg.sender) {
        // require(_initialRbtcToUsdRate > 0, "Invalid initial rate");
        rbtcToUsdRate = 60000000000000000000000;
        // rbtcToUsdRate = _initialRbtcToUsdRate;
        currentEvent.resolved = true;
    }

    function createNewEvent() external onlyOwner {
        currentEventId++;
        require(currentEvent.resolved, "Current event not resolved");

        currentEvent.id = currentEventId;
        currentEvent.startTime = block.timestamp;
        currentEvent.resolved = false;
                
        emit EventCreated(currentEventId, block.timestamp);
    }

    function placeBet(bool outcome) external payable nonReentrant whenNotPaused {
        require(currentEvent.resolved == false, "No active event");
        require(block.timestamp < currentEvent.startTime + BETTING_DURATION, "Betting period has ended");
        require(msg.value > 0, "Bet amount must be greater than 0");
        
        //uint256 betAmountUsd = (msg.value * rbtcToUsdRate) / 1e18;
        //require(betAmountUsd == BET_AMOUNT_1 || betAmountUsd == BET_AMOUNT_10 || betAmountUsd == BET_AMOUNT_100, "Invalid bet amount");

        if (outcome) {
            currentEvent.betsA[msg.sender].amount += msg.value;
            currentEvent.totalBetsA += msg.value;
        } else {
            currentEvent.betsB[msg.sender].amount += msg.value;
            currentEvent.totalBetsB += msg.value;
        }

        emit BetPlaced(currentEventId, msg.sender, outcome, msg.value);
    }

    function resolveEvent() external {
        require(currentEventId > 0, "No active event");
        require(block.timestamp >= currentEvent.startTime + BETTING_DURATION, "Betting period not yet ended");
        require(!currentEvent.resolved, "Event already resolved");

        // Simple RNG (Note: This is not secure for production use)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, currentEventId))) % 2;
        currentEvent.result = randomNumber == 0; // 0 for A, 1 for B
        currentEvent.resolved = true;

        emit EventResolved(currentEventId, currentEvent.result);
    }

    function claimWinnings() external nonReentrant {
        Event storage bettingEvent = currentEvent;
        require(bettingEvent.resolved, "Event not resolved");
        
        Bet storage userBet = bettingEvent.result ? bettingEvent.betsA[msg.sender] : bettingEvent.betsB[msg.sender];
        
        require(userBet.amount > 0, "No winning bet placed");
        require(!userBet.claimed, "Winnings already claimed");

        userBet.claimed = true;

        uint256 totalWinningBets = bettingEvent.result ? bettingEvent.totalBetsA : bettingEvent.totalBetsB;
        uint256 totalLosingBets = bettingEvent.result ? bettingEvent.totalBetsB : bettingEvent.totalBetsA;

        require(totalWinningBets > 0, "No winning bets");

        uint256 winnings = userBet.amount + (userBet.amount * totalLosingBets / totalWinningBets);

        (bool success, ) = msg.sender.call{value: winnings}("");
        require(success, "Transfer failed");

        emit Payout(currentEventId, msg.sender, winnings);
    }

    function getEventDetails() external view returns (
        bool resolved,
        bool result,
        uint256 totalBetsA,
        uint256 totalBetsB,
        uint256 startTime
    ) {
        Event storage bettingEvent = currentEvent;
        return (
            bettingEvent.resolved,
            bettingEvent.result,
            bettingEvent.totalBetsA,
            bettingEvent.totalBetsB,
            bettingEvent.startTime
        );
    }

    function getUserBet(address user, bool outcome) external view returns (uint256 amount, bool claimed) {
        Event storage bettingEvent = currentEvent;
        Bet storage bet = outcome ? bettingEvent.betsA[user] : bettingEvent.betsB[user];
        return (bet.amount, bet.claimed);
    }

    function updateRbtcToUsdRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Invalid rate");
        rbtcToUsdRate = _newRate;
        emit RbtcToUsdRateUpdated(_newRate);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {}
}