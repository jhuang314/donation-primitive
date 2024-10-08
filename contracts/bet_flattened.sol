// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/bet.sol


pragma solidity ^0.8.0;




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