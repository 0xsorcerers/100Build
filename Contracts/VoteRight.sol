// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract VoteRight is Ownable, ReentrancyGuard {
    using ABDKMath64x64 for uint256;
    using MerkleProof for bytes32[];

    enum ElectionState { Inactive, Active, Ended }

    ElectionState public electionState = ElectionState.Inactive;
    uint256 public timeLock = 24 hours;
    uint256 public totalElectorates = 36;
    uint256 public electoralCollegeThreshold = 13;
    bool public paused = false;

    struct Candidate {
        string name;
        uint256[] voteCounts; // One for each electorate
    }

    //Arrays
    Candidate[] public candidates;

    //Mappings
    mapping(address => uint256) public entryMap;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public hasVoted;
    mapping(address => bytes32) private voterHashes; // Maps Merkle root hashes for voters
    mapping(address => bool) public isRegistered; // Maps Telephone numbers to registration status

    bytes32[] public merkleProofs; // Merkle root hashes for voter registration

    event ElectionStarted();
    event ElectionEnded(uint256 winningCandidateIndex, uint256 winningElectorate);
    event Voted(address indexed voter, uint256 electorate, uint256 candidateIndex);

    constructor() {
        isAdmin[msg.sender] = true;
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
        require(!isAdmin[msg.sender], "Admins cannot vote");
        require(electionState == ElectionState.Active, "Election is not active");
        require(!hasVoted[msg.sender], "You have already voted");
        require(block.timestamp < entryMap[msg.sender] + timeLock, "Timelocked.");
        require(isRegistered[msg.sender], "You are not registered");
        _;
    }

    function addAdmin(address _admin) public onlyOwner {
        require(!isAdmin[_admin], "Admin already exists");
        isAdmin[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyOwner {
        require(isAdmin[_admin], "Admin does not exist");
        require(_admin != owner(), "Cannot remove the contract admin");
        isAdmin[_admin] = false;
    }
    
    function addCandidate(string memory _name) public onlyAdmin {
        require(electionState == ElectionState.Active, "Election is not active");
        
    }

    function startElection() public onlyAdmin {
        require(electionState == ElectionState.Inactive, "Election is already active");
        electionState = ElectionState.Active;
        emit ElectionStarted();
    }

    function endElection() public onlyAdmin {
        require(electionState == ElectionState.Active, "Election is not active");
        electionState = ElectionState.Ended;
        uint256 winningCandidateIndex;
        uint256 winningElectorate;
        // uint256 winningCandidateIndex = getWinningCandidate();
        emit ElectionEnded(winningCandidateIndex, winningElectorate);
    }

    function getWinningCandidate() private view returns (uint256, uint256) {
        require(electionState == ElectionState.Ended, "Election has not ended yet");
        uint256 maxVotes = 0;
        uint256 winningIndex = 0;
        uint256 winningElectorate = 0;
        // collate all votes from all Electorates for the Electoral College
        
        return (winningIndex, winningElectorate);
    }

    function vote(uint256 _candidateIndex,uint256 _telephone, uint256 _electorate, bytes32[] memory _proof) 
    public onlyVoter onlyAfterTimelock nonReentrant {
        require(!paused, "Election is paused.");
        require(electionState == ElectionState.Active, "Election is not active");       
        require(!hasVoted[msg.sender], "Voter is already registered");
        bytes32 leaf = keccak256(abi.encodePacked(_telephone)); // Still undecided over telephone or evm address? or both.
        bytes32 merkleRoot = voterHashes[msg.sender];
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid Merkle proof"); 
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        require(_electorate < totalElectorates, "Invalid electorate");
        
        candidates[_candidateIndex].voteCounts[_electorate]++;
        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, _electorate, _candidateIndex);
    }

    function registerVoter(bytes32 _voterHash) public onlyAdmin {
        require(electionState == ElectionState.Inactive, "Registration is closed");
        require(!isRegistered[msg.sender], "Voter is already registered");
        isRegistered[msg.sender] = true;
        //Allow the public push their registration fingerprints
        voterHashes[msg.sender] = _voterHash;
    }

    event Pause();
    function pause() public onlyOwner {
        require(!paused, "Election already paused.");
        paused = true;
        emit Pause();
    }

    event Unpause();
    function unpause() public onlyOwner {
        require(paused, "Election ongoing.");
        paused = false;
        emit Unpause();
    }
}
