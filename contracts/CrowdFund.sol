//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IERC20.sol";

contract CrowdFund {
    event Launch(
        uint256 id,
        address indexed creatot,
        uint256 goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint256 id);
    event Pledge(uint256 id, address indexed sender, uint256 amount);
    event Unpledge(uint256 id, address indexed sender, uint256 amount);
    event Claim(uint256 id, address indexed sender, uint256 amount);
    event Refund(uint256 id, address indexed sender, uint256 amount);

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    IERC20 public immutable token;
    uint256 public count;
    mapping(uint256 => Campaign) public campaings;
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch(
        uint256 _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp, "start < now");
        require(_endAt >= _startAt, "end < start");
        require(_endAt <= block.timestamp + 90 days, "end > max duration");

        count += 1;
        campaings[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint256 _id) external {
        Campaign memory campaign = campaings[_id];
        require(msg.sender == campaign.creator, "not created");
        require(block.timestamp < campaign.startAt, "started");

        delete campaings[_id];

        emit Cancel(_id);
    }

    function pledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaings[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;

        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

    function unpledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaings[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;

        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint256 _id) external {
        Campaign storage campaign = campaings[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(msg.sender == campaign.creator, "not created");
        require(campaign.pledged >= campaign.goal, "goal not reach");
        require(!campaign.claimed, "claimed");

        token.transfer(campaign.creator, campaign.pledged);

        campaign.claimed = true;

        emit Claim(_id, msg.sender, campaign.pledged);
    }

    function refund(uint256 _id) external {
        Campaign storage campaign = campaings[_id];
        require(block.timestamp >= campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "goal not reach");

        uint256 amount = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;

        require(amount > 0, "not pledged");

        token.transfer(msg.sender, amount);

        emit Refund(_id, msg.sender, amount);
    }
}
