// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;

contract ZenithSubscriptionHub {
    struct Tier {
        address payable creator;
        uint256 priceWei;
        uint256 durationSeconds;
        bool isActive;
    }

    address payable public immutable hubAdmin;
    string public hubDescriptor;
    uint256 public platformFeeBps; // 250 = 2.5%
    uint256 public tierCounter;
    uint256 public accumulatedFees;
    bool public isHubHalted;

    mapping(address => bool) public verifiedCreators;
    mapping(uint256 => Tier) public tiers;
    mapping(uint256 => mapping(address => uint256)) public subscriptionExpiry;

    event CreatorAdded(address indexed creator);
    event SubscriptionBought(uint256 indexed tierId, address indexed subscriber, uint256 expiry);
    event TierCanceled(uint256 indexed tierId);
    event TreasuryDeposited(address indexed funder, uint256 amount);
    event ReservesEmptied(address indexed admin, uint256 amount);
    event FeesGathered(address indexed admin, uint256 amount);
    event HubHaltToggled(bool isHalted);
    event TierRegistered(uint256 indexed tierId, address indexed creator, uint256 price, uint256 duration);
    event DescriptorUpdated(string newDescriptor);

    modifier onlyAdmin() {
        require(msg.sender == hubAdmin, "ZenithSub: Access denied");
        _;
    }

    modifier whenNotHalted() {
        require(!isHubHalted, "ZenithSub: Hub is halted");
        _;
    }

    constructor() {
        hubAdmin = payable(msg.sender);
        hubDescriptor = "Zenith Base Subscription Hub v1";
        platformFeeBps = 250; // 2.5%
        isHubHalted = false;
        verifiedCreators[msg.sender] = true;
    }

    // 1. addVerifiedCreator
    function addVerifiedCreator(address creator) external onlyAdmin {
        require(!verifiedCreators[creator], "ZenithSub: Already verified");
        verifiedCreators[creator] = true;
        emit CreatorAdded(creator);
    }

    // 2. buySubscription
    function buySubscription(uint256 tierId) external payable whenNotHalted {
        Tier storage t = tiers[tierId];
        require(tierId > 0 && tierId <= tierCounter, "ZenithSub: Invalid ID");
        require(t.isActive, "ZenithSub: Tier inactive");
        require(msg.value >= t.priceWei, "ZenithSub: Insufficient payment");

        uint256 fee = (msg.value * platformFeeBps) / 10000;
        uint256 creatorShare = msg.value - fee;

        accumulatedFees += fee;
        
        uint256 currentExpiry = subscriptionExpiry[tierId][msg.sender];
        if (currentExpiry < block.timestamp) {
            subscriptionExpiry[tierId][msg.sender] = block.timestamp + t.durationSeconds;
        } else {
            subscriptionExpiry[tierId][msg.sender] = currentExpiry + t.durationSeconds;
        }

        if (creatorShare > 0) {
            (bool sent, ) = t.creator.call{value: creatorShare}("");
            require(sent, "ZenithSub: Payout failed");
        }

        emit SubscriptionBought(tierId, msg.sender, subscriptionExpiry[tierId][msg.sender]);
    }

    // 3. cancelSubscriptionTier
    function cancelSubscriptionTier(uint256 tierId) external {
        Tier storage t = tiers[tierId];
        require(tierId > 0 && tierId <= tierCounter, "ZenithSub: Invalid ID");
        require(msg.sender == t.creator || msg.sender == hubAdmin, "ZenithSub: Unauthorized");
        require(t.isActive, "ZenithSub: Already inactive");

        t.isActive = false;
        emit TierCanceled(tierId);
    }

    // 4. depositPlatformTreasury
    function depositPlatformTreasury() external payable whenNotHalted {
        require(msg.value > 0, "ZenithSub: Zero deposit");
        accumulatedFees += msg.value;
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    // 5. emptyPlatformReserves
    function emptyPlatformReserves() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "ZenithSub: Zero balance");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: balance}("");
        require(sent, "ZenithSub: Sweep failed");

        emit ReservesEmptied(hubAdmin, balance);
    }

    // 6. gatherPlatformFees
    function gatherPlatformFees() external onlyAdmin {
        uint256 amount = accumulatedFees;
        require(amount > 0, "ZenithSub: Zero fees");

        accumulatedFees = 0;
        (bool sent, ) = hubAdmin.call{value: amount}("");
        require(sent, "ZenithSub: Harvest failed");

        emit FeesGathered(hubAdmin, amount);
    }

    // 7. haltSubscriptionHub
    function haltSubscriptionHub(bool isHalted) external onlyAdmin {
        isHubHalted = isHalted;
        emit HubHaltToggled(isHalted);
    }

    // 8. registerNewTier
    function registerNewTier(uint256 priceWei, uint256 durationSeconds) external whenNotHalted returns (uint256) {
        require(verifiedCreators[msg.sender], "ZenithSub: Not a creator");
        require(priceWei > 0 && durationSeconds > 0, "ZenithSub: Invalid parameters");

        tierCounter++;
        tiers[tierCounter] = Tier({
            creator: payable(msg.sender),
            priceWei: priceWei,
            durationSeconds: durationSeconds,
            isActive: true
        });

        emit TierRegistered(tierCounter, msg.sender, priceWei, durationSeconds);
        return tierCounter;
    }

    // 9. updateHubDescriptor
    function updateHubDescriptor(string calldata newDescriptor) external onlyAdmin {
        require(bytes(newDescriptor).length > 0, "ZenithSub: Empty string");
        hubDescriptor = newDescriptor;
        emit DescriptorUpdated(newDescriptor);
    }
}