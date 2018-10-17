pragma solidity ^0.4.23;

contract FundRaising {
  mapping(address => uint) public contributors;
  address public admin;
  uint public noOfContributors;
  uint public minimumContribution;
  uint public deadline; // a timestamp in seconds so users can potentially request a refund
  uint public goal;
  uint public raisedAmount = 0;

  struct Request{
    string description;
    address recipient;
    uint value;
    // marks if a specific request has been completed or not
    bool completed;
    uint noOfVoters;
    // registers the voters
    mapping(address => bool) voters;
  }

  Request[] public requests;

  event ContributeEvent(address sender, uint value);
  event createRequestEvent(string _description, address _recipient, uint _value);
  // triggered when the owner makes a payment
  event makePaymentEvent(address recipient, uint value);

constructor(uint _goal, uint _deadline) public {
  goal = _goal;
  // campaign deadline will be reached in this no. of seconds from this moment
  deadline = now + _deadline;

  admin = msg.sender;
  minimumContribution = 10;
}

modifier onlyAdmin() {
  require(msg.sender == admin);
  _;
}

  function contribute() public payable {
    require(now < deadline);
    require(msg.value >= minimumContribution);

    // so we only increment the value if it's the first time a user sends to the campaign
    if(contributors[msg.sender] == 0) {
      noOfContributors++;
    }

    contributors[msg.sender] += msg.value;
    raisedAmount += msg.value;

    emit ContributeEvent(msg.sender, msg.value);
  }

  // returns the contract balance
  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function getRefund() public {
    require(now > deadline) ;
    require(raisedAmount < goal);
    // makes sure the sender actually contributed
    require(contributors[msg.sender] > 0);

    address recipient = msg.sender;
    uint value = contributors[msg.sender];

    // transfer value to the recipient
    recipient.transfer(value);
    contributors[msg.sender] = 0;
  }

  function createRequest(string _description, address _recipient, uint _value) public onlyAdmin {
    // create request in memory
    Request memory newRequest = Request({
      description: _description,
      recipient: _recipient,
      value: _value,
      completed: false,
      noOfVoters: 0
      });

      // add to an array
      requests.push(newRequest);
      emit createRequestEvent(_description, _recipient, _value);
  }

  function voteRequest(uint index) public {
    // working directly on an element of array saved in storage, so not a copy
    Request storage thisRequest = requests[index];
    // who can vote? only noOfContributors
    require(contributors[msg.sender] > 0);
    // make sure user can't vote twice by modifying the value associated from address in the request
    require(thisRequest.voters[msg.sender] == false);

    thisRequest.voters[msg.sender] = true;
    thisRequest.noOfVoters++;
  }

  function makePayment(uint index) public onlyAdmin {
    Request storage thisRequest = requests[index];
    // verify it's not been finalized
    require(thisRequest.completed == false);
    // more than 50% of contributors must have voted
    require(thisRequest.noOfVoters > noOfContributors / 2);
    // transfer money to the recipient
    thisRequest.recipient.transfer(thisRequest.value);

    thisRequest.completed = true;

    emit makePaymentEvent(thisRequest.recipient, thisRequest.value);
  }

}
