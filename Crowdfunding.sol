   
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 //CROUDFUUND CONTRACT
interface IERC20{
 function transfer(address, uint) external returns(bool);
 function transferFrom(address, address, uint) external returns(bool);
}
 
contract CrowdFund{
 
  event Launch( //lets user launch campaign
     uint id,
     address indexed creator, //here we are indexing to find all campaigns launched by the creator
    uint goal, // allows user to set goal
     uint32 startAt, // the date the campaign starts
     uint32 endAt //the date the campaign stops
  );
 
event Cancel( // Allows campaign creator to cancel contract before campaign starts

    uint id
);
event Pledge( // lets users pledge the amount of tokens
   uint indexed id, // indexed id because many users will be able to pledge to same campaign
   address indexed caller, // indexed caller because same caller will be able to pledge to many campaigns
   uint amount
);
    event Unpledge(uint indexed id, address indexed caller, uint amount); // users are ale to call this function if they want to change amount pledged during campaign
    event Claim(uint id); // user is able to claim amount of token if ahas not been reached
    event Refund(uint id, address indexed caller, uint amount); //if campasign was unsuccessful user is ale to call this fumction
 event Pledged(uint id, address indexed caller, uint amount);

struct Campaign {
        address creator;  //address of creators
        uint goal;  // amount of tokens users need to raise for the campaign to be successful
        uint pledged; //  total amount of tokens pledge
        uint32 startAt; // timestamp of start of campaign 
        uint32 endAt;  // timestamp of end of camapign
        bool claimed; // tokens of the campaign have been claimed by creator
    }
 
   IERC20 public immutable token; //token will not be changed 
 
uint public count; //Everytime we create a new campaign the count incorrects
 
mapping(uint => Campaign) public campaigns; //mapping from id to campaign
 
mapping(uint => mapping(address => uint)) public pledgedAmount; //how much user has pledged 
 
constructor(address _token){ //initializes the state variable
token = IERC20(_token);
}
function launch(uint _goal, uint32 _startAt, uint32 _endAt) external{ //launching the campaign

require (_startAt >= block.timestamp, "startAt <now"); // the time you are starting the camapaign 
require (_endAt >= _startAt, "endAt < startAt"); // the time you end the campaign
require (_endAt <= block.timestamp + 120 days, " endAt > max duration"); // campaign must not exceed 120days 

count +=1;  //increatments the id stored in count
campaigns[count] = Campaign ({
    creator: msg.sender,
    goal: _goal,
    pledged: 0,
    startAt: _startAt,
    endAt: _endAt,
    claimed: false
});
emit Launch(count, msg.sender, _goal, _startAt, _endAt); //broadcasting event
}

function cancel (uint _id) external{ //Only campaign creator is able to cancel if campaign has not started and campaign does exist
Campaign memory campaign = campaigns [_id];  
require(msg.sender == campaign.creator, "not creator");//person who is 
require (block.timestamp < campaign.startAt, "started"); //current block.timestamp is strictly less than campaign.startAt meaning campaign has not started throws "started"

delete campaigns[_id]; //if the two conditions are meant you can delete the campaign
emit Cancel(_id);
}

function pledge(uint _id, uint _amount) external{ //once campaign starts users will be able to pledge tokens into the campaign
Campaign storage campaign = campaigns[_id];// declaring as storage because we need to update the campaign struct
require(block.timestamp >= campaign.startAt, "not started");// we require that camapaign has started
require(block.timestamp <= campaign.endAt, "campaign has ended"); // require that if campaign does not exist users will not be able to pledge

campaign.pledged += _amount; //updating campaign struct
pledgedAmount [_id] [msg.sender]+= _amount; //stored amount of tokens pledged by user
token.transferFrom (msg.sender, address(this), _amount); //allows us to transfer tokens
emit Pledge (_id, msg.sender, _amount); 
}


function unpledge (uint _id, uint _amount) external{ //user wants to change the amount of tokens pledged while campaign is still on
    Campaign storage campaign = campaigns[_id];//updating the campaign struct 
    require(block.timestamp <= campaign.endAt, "campaign has ended"); //users should not be able to unpledged before campaign has ended 

    campaign.pledged -= _amount;//once we know that campaign is still active we will transfer token back to the user and we also deduct amounts from campaign struct 
    pledgedAmount [_id] [msg.sender] -= _amount; //deducting from the mapping pledged
    token.transfer(msg.sender, _amount); //token tranfer
emit Unpledge(_id, msg.sender, _amount);
}

function claim(uint _id) external{ //the amount pledged is greater or equal to the goal then campaign craetor is able to claim tokens
Campaign storage campaign = campaigns [_id]; //getting campaign as storage variable because we will be updating struct
require(msg.sender == campaign.creator, "not creator"); // contract can only be called by the campaign creator
require(block.timestamp > campaign.endAt, "not ended"); //making sure campaign has ended
require(campaign.pledged >= campaign.goal, "pledge < goal"); // make sure amount pledged is graeter or equal to the goal
require(!campaign.claimed, "claimed");//making sure claimed has not been called

campaign.claimed = true; //function claimed can only be called once for each campaign
token.transfer(msg.sender,campaign.pledged); //token transfer. We are accessing msg.sender is cheaper gas than accesing state variable camapign.creator.Pledged holds the total amount that was pledged
emit Claim(_id); //broad casting event
}
function refund(uint _id) external{ //if total amount is less than the pledged amount then users are able to claim
Campaign memory campaign = campaigns[_id]; // we are not storing 
require(block.timestamp > campaign.endAt, "not ended"); //no refund if campaign has not ended
require(campaign.pledged < campaign.goal, "pledge >=goal"); //amount pledged should be strictly less than the goal

uint bal = pledgedAmount[_id][msg.sender];//resetting balance before transfering token out, we are trying to prevent re entrancy event 
pledgedAmount[_id][msg.sender] = 0; //resetting pledged amount
token.transfer(msg.sender , bal); // transfering token out

emit Refund(_id, msg.sender, bal); //once tokens are refunded event can be emited

}
function second () public view returns(uint){
    return block.timestamp + 60 seconds;
}
function week() public view returns(uint){
    return block.timestamp + 1 weeks;
}
 function day() public view returns(uint){
     return block.timestamp + 1 days;
 }
}
