// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BettingMarket is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    address public constant CHARITY_WALLET = 0xd394dD69861b602c882F0F771002eef3A49a718d;

    struct Event {
        uint256 startTime;
        uint256 totalBetsA;
        uint256 totalBetsB;
        bool resolved;
        bool winningOutcome;
        uint256 oddsA;
        uint256 oddsB;
        mapping(address => uint256) betsA;
        mapping(address => uint256) betsB;
        mapping(address => bool) hasClaimed;
    }

    uint256 public currentEventId;
    uint256 public minBetAmount;
    uint256 public maxBetAmount;

    mapping(uint256 => Event) public events;

    event NewEventCreated(uint256 indexed eventId, uint256 startTime);
    event BetPlaced(uint256 indexed eventId, address indexed bettor, bool betOnA, uint256 amount);
    event EventResolved(uint256 indexed eventId, bool outcome);
    event WinningsClaimed(uint256 indexed eventId, address indexed winner, uint256 amount);
    event EventCancelled(uint256 indexed eventId);
    event OddsUpdated(uint256 indexed eventId, uint256 oddsA, uint256 oddsB);
    event CharityContribution(uint256 indexed eventId, address indexed winner, uint256 amount);

    constructor() Ownable(msg.sender) {
        minBetAmount = 0.001 ether;
        maxBetAmount = 10 ether;
    }

    function getCurrentEventId() public view returns (uint256) {
        require(currentEventId > 0, "No events created yet");
        return currentEventId;
    }

    function createNewEvent() public onlyOwner {
        require(currentEventId == 0 || events[currentEventId].resolved, "Previous event not yet resolved");

        currentEventId = currentEventId.add(1);
        events[currentEventId].startTime = block.timestamp;
        events[currentEventId].oddsA = 500;
        events[currentEventId].oddsB = 500;

        emit NewEventCreated(currentEventId, block.timestamp);
    }

    function placeBet(bool _betOnA) public payable nonReentrant whenNotPaused {
        require(currentEventId > 0, "No active event");
        require(msg.value >= minBetAmount && msg.value <= maxBetAmount, "Invalid bet amount");
        
        Event storage currentEvent = events[currentEventId];
        require(!currentEvent.resolved, "Event has ended");

        if (_betOnA) {
            currentEvent.totalBetsA = currentEvent.totalBetsA.add(msg.value);
            currentEvent.betsA[msg.sender] = currentEvent.betsA[msg.sender].add(msg.value);
        } else {
            currentEvent.totalBetsB = currentEvent.totalBetsB.add(msg.value);
            currentEvent.betsB[msg.sender] = currentEvent.betsB[msg.sender].add(msg.value);
        }

        updateOdds(currentEventId);

        emit BetPlaced(currentEventId, msg.sender, _betOnA, msg.value);
    }

    function updateOdds(uint256 _eventId) internal {
        Event storage currentEvent = events[_eventId];
        uint256 totalBets = currentEvent.totalBetsA.add(currentEvent.totalBetsB);
        
        if (totalBets > 0) {
            currentEvent.oddsA = currentEvent.totalBetsB.mul(1000).div(totalBets);
            currentEvent.oddsB = currentEvent.totalBetsA.mul(1000).div(totalBets);
        } else {
            currentEvent.oddsA = 500;
            currentEvent.oddsB = 500;
        }

        emit OddsUpdated(_eventId, currentEvent.oddsA, currentEvent.oddsB);
    }

    function resolveEvent(uint256 _eventId, bool _outcome) public onlyOwner {
        require(_eventId <= currentEventId, "Invalid event ID");
        Event storage eventToResolve = events[_eventId];
        require(!eventToResolve.resolved, "Event already resolved");

        eventToResolve.resolved = true;
        eventToResolve.winningOutcome = _outcome;

        emit EventResolved(_eventId, eventToResolve.winningOutcome);
    }

    function claimWinnings(uint256 _eventId) public nonReentrant {
        Event storage eventToClaim = events[_eventId];
        require(eventToClaim.resolved, "Event not yet resolved");
        require(!eventToClaim.hasClaimed[msg.sender], "Winnings already claimed");

        uint256 betAmount = 0;
        uint256 winnings = 0;
        
        if (eventToClaim.winningOutcome && eventToClaim.betsA[msg.sender] > 0) {
            betAmount = eventToClaim.betsA[msg.sender];
            winnings = betAmount.mul(eventToClaim.totalBetsA.add(eventToClaim.totalBetsB)).div(eventToClaim.totalBetsA);
        } else if (!eventToClaim.winningOutcome && eventToClaim.betsB[msg.sender] > 0) {
            betAmount = eventToClaim.betsB[msg.sender];
            winnings = betAmount.mul(eventToClaim.totalBetsA.add(eventToClaim.totalBetsB)).div(eventToClaim.totalBetsB);
        }

        require(winnings > 0, "No winnings to claim");

        eventToClaim.hasClaimed[msg.sender] = true;
        eventToClaim.betsA[msg.sender] = 0;
        eventToClaim.betsB[msg.sender] = 0;

        uint256 profit = winnings.sub(betAmount);
        uint256 charityAmount = profit.div(2);
        uint256 userWinnings = betAmount.add(profit.sub(charityAmount));

        payable(msg.sender).transfer(userWinnings);
        payable(CHARITY_WALLET).transfer(charityAmount);

        emit WinningsClaimed(_eventId, msg.sender, userWinnings);
        emit CharityContribution(_eventId, msg.sender, charityAmount);
    }

    function setMinMaxBetAmount(uint256 _minBetAmount, uint256 _maxBetAmount) public onlyOwner {
        require(_minBetAmount > 0 && _maxBetAmount > _minBetAmount, "Invalid bet limits");
        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getEventStatus(uint256 _eventId) public view returns (string memory) {
        Event storage eventToCheck = events[_eventId];
        if (!eventToCheck.resolved) {
            return "Active";
        } else {
            return "Resolved";
        }
    }

    function getUserBet(uint256 _eventId, address _user) public view returns (bool betOnA, uint256 amount) {
        Event storage eventToCheck = events[_eventId];
        if (eventToCheck.betsA[_user] > 0) {
            return (true, eventToCheck.betsA[_user]);
        } else if (eventToCheck.betsB[_user] > 0) {
            return (false, eventToCheck.betsB[_user]);
        }
        return (false, 0);
    }

    function getCurrentEventWinner() public view returns (uint256) {
        Event storage currentEvent = events[getCurrentEventId()];
        require(currentEvent.resolved, "Current event not yet resolved");
        return currentEvent.winningOutcome ? 0 : 1; // 0 for A, 1 for B
    }

    function getTotalBets(uint256 _eventId) public view returns (uint256 totalA, uint256 totalB) {
        Event storage eventToCheck = events[_eventId];
        return (eventToCheck.totalBetsA, eventToCheck.totalBetsB);
    }

    function getOdds(uint256 _eventId) public view returns (uint256 oddsA, uint256 oddsB) {
        Event storage eventToCheck = events[_eventId];
        return (eventToCheck.oddsA, eventToCheck.oddsB);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function cancelEvent(uint256 _eventId) public onlyOwner {
        Event storage eventToCancel = events[_eventId];
        require(!eventToCancel.resolved, "Event already resolved");
        eventToCancel.resolved = true;
        
        // Refund logic
        for (uint256 i = 1; i <= currentEventId; i++) {
            address bettor = address(uint160(i)); // This is a simplification, you'll need to implement a way to iterate through bettors
            uint256 refundAmount = eventToCancel.betsA[bettor].add(eventToCancel.betsB[bettor]);
            if (refundAmount > 0) {
                eventToCancel.betsA[bettor] = 0;
                eventToCancel.betsB[bettor] = 0;
                payable(bettor).transfer(refundAmount);
            }
        }

        emit EventCancelled(_eventId);
    }
}