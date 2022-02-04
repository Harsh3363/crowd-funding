// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    //mapping will link the address of contributors with it's contribution amount -
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    // to count number of requests.
    mapping(uint=>Request) public requests;
    uint public numRequests;

    //constructor is the first function as soon as contract is deployed
    constructor(uint _target,uint _deadline){
        target=_target;
        deadline=block.timestamp+_deadline;//block.timestamp is the time from when contract get deployed
        minimumContribution=100 wei;
        manager=msg.sender;
    } 

    function sendEth() public payable{
        //it will see that the deadline has not passed if it is then print the statement.
        require(block.timestamp<deadline,"deadline has passed");
        //will check if minimum contribution criteria is meet or not.
        require(msg.value>=minimumContribution,"minimum contribution is not meet");
        //it will check if a contributor who have contributed already is contributing then it will not increase no of
        //contributors but it will just increase the raisedAmount .
        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target,"not eligible for refund");
        require(contributors[msg.sender]>0);
        //making user var user payable in order to transfer eth to it.
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    modifier onlyManager(){
        require(msg.sender==manager,"only manager can call this function.");
        _;
    }
    //using the above made modifier in the function
    function createRequests(string memory _description,address payable _recipient,uint _value) public onlyManager{
        //newRequest is of type Request(structure) and inside this struct we are making mapping so we will be using 
        //storage and not memory in order to use the mapping.
        //newRequest is making changes in Request structure for request[0] then for 1  and so on.....
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"you have already voted");//intially bool value is false if voted it becomes true.
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"the request have been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"majority doesnot support.");
        thisRequest.recipient.transfer(thisRequest.value);//thisRequest is pointing towards Request structure
        thisRequest.completed=true;
    }

}
