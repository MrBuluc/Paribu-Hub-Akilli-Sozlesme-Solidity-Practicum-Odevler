// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CrowdFund {
    event Launch(uint id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    ERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address tokenAdd) {
        token = ERC20(tokenAdd);
    }

    function launch(uint goal, uint32 startAt, uint32 endAt) external {
        require(startAt >= block.timestamp, "start at < now");
        require(endAt >= startAt, "end at < start at");
        require(endAt <= block.timestamp + 90 days, "end at > max duration");

        count++;
        campaigns[count] = Campaign(msg.sender, goal, 0, startAt, endAt, false);

        emit Launch(count, msg.sender, goal, startAt, endAt);
    }

    function cancel(uint id) external checkCreator(id) {
        Campaign memory campaign = campaigns[id];
        //require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");
        delete campaigns[id];
        emit Cancel(id);
    }

    function pledge(uint id, uint amount) external checkNotEndAt(id) {
        Campaign storage campaign = campaigns[id];
        require(block.timestamp >= campaign.startAt, "not started");
        //require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += amount;
        pledgedAmount[id][msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);

        emit Pledge(id, msg.sender, amount);
    }

    function unpledge(uint id, uint amount) external checkNotEndAt(id) {
        Campaign storage campaign = campaigns[id];
        //require(block.)
        
        campaign.pledged -= amount;
        pledgedAmount[id][msg.sender] -= amount;
        token.transfer(msg.sender, amount);

        emit Unpledge(id, msg.sender, amount);
    }

    function claim(uint id) external checkCreator(id) {
        Campaign storage campaign = campaigns[id];
        //require()
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(id);
    }

    function refund(uint id) external checkEndAtAndCampaignPledgedGreaterOrEqualThanGoal(id) {
        uint bal = pledgedAmount[id][msg.sender];
        pledgedAmount[id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(id, msg.sender, bal);
    }

    modifier checkNotEndAt(uint id) {
        _;
        Campaign memory campaign = campaigns[id];
        require(block.timestamp <= campaign.endAt, "ended");
        _;
    }

    modifier checkCreator(uint id) {
        _;
        Campaign memory campaign = campaigns[id];
        require(msg.sender == campaign.creator, "not creator");
        _;
    }

    modifier checkEndAtAndCampaignPledgedGreaterOrEqualThanGoal(uint id) {
        Campaign memory campaign = campaigns[id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        _;
    }
}