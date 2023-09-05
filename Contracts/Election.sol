// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract Election is Ownable, ReentrancyGuard {
    uint256 public timeLock = 24 hours;
    address private voteraddress;
    uint256 public quorum;
    string public winner;
    
    enum ElectionState { Inactive, Active, Ended }

    ElectionState public electionState = ElectionState.Inactive;

    //Arrays
    address[] private admins;
    address[] public voters;

    //Mappings 
    
    mapping(address => uint256) public entryMap;
    mapping(address => uint256) public VoteCheck;
    mapping(address => uint256) public electorate;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public hasVoted;

    constructor (
    address _admin
    ) {
    admins.push(_admin);
    }    
    using ABDKMath64x64 for uint256; 

    modifier onlyQuorum() {
        //Call for Quorum ;
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not Authorized");
        _;
    }

    modifier onlyAfterTimelock {            
    require(entryMap[msg.sender] + timeLock < block.timestamp, "Timelocked.");
    _;
    }

    modifier onlyVoter() {
        require(electionState == ElectionState.Active, "Election is not active");
        require(!hasVoted[msg.sender], "You have already voted");
        require(block.timestamp < entryMap[msg.sender] + timeLock, "Timelocked.");
        _;
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;

    event adminAdded(address indexed admin);
    event adminRemoved(address indexed admin);
    event ElectionStarted();
    event ElectionEnded(string indexed winner, uint256 winningCandidateIndex);
    event Voted(address indexed Voter, address indexed Candidate, uint256 candidateIndex);

    function createAdmin(address _newAdmin) public nonReentrant onlyOwner {
    
    }

    function addAdmin(address _admin) public onlyOwner {
        require(!isAdmin[_admin], "Admin already exists");
        admins.push(_admin);
        isAdmin[_admin] = true;
        emit adminAdded(_admin);
    }

    function removeAdmin(address _admin) public onlyOwner {
        require(isAdmin[_admin], "Admin does not exist");
        require(admins.length > 1, "Cannot remove the last admin");
        isAdmin[_admin] = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _admin) {
                admins[i] = admins[admins.length - 1];
                break;
            }
        }
        admins.pop();
        emit adminRemoved(_admin);
    }

    function startElection() public onlyQuorum {
        require(electionState == ElectionState.Inactive, "Election is active");
        electionState = ElectionState.Active;
        emit ElectionStarted();
    }

    function endElection() public onlyQuorum {
        require(electionState == ElectionState.Active, "Election is not active");
        electionState = ElectionState.Ended;
        uint256 winningCandidateIndex = getWinningCandidateIndex();
        //search the Candidate List for winner    
        emit ElectionEnded(winner, winningCandidateIndex);
    }

    function getWinningCandidateIndex() private view returns (uint256) {
        require(electionState == ElectionState.Ended, "Election has not ended yet");        
        uint256 maxVotes = 0;
        uint256 winningIndex = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winningIndex = i;
            }
        }
        return winningIndex;
    }

    function addCandidate(string memory _name) public onlyQuorum {
        require(electionState == ElectionState.Active, "Election is not active");
        candidates.push(Candidate(_name, 0));
    }
    
    function voteNow(string memory _hash, uint256 _candidateIndex) public {
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        candidates[_candidateIndex].voteCount++;
        hasVoted[msg.sender] = true;

        //keccak hash proof of user
        
        // emit Voted(msg.sender, Candidate, _candidateIndex);
    }

    function changeVote() public {

    }

    function setQuorum(uint256 _quorum) public {
        quorum = _quorum;
    }
    
}
