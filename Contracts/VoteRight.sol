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
        uint256 votes;
    }

    struct Electorate {
        string name;
        Candidate[] candidates;
    }

    struct CollatedCandidate {
        string name;
        uint256 totalVotes;
    }

    struct CollatedElectorate {
        string name;
        uint256 totalVotes;
    }

    // Arrays
    Candidate[] public candidates;
    Electorate[] public electorates;
    CollatedCandidate[] public collatedCandidates;
    CollatedElectorate[] public collatedElectorates;


    // Mappings
    mapping(address => uint256) public entryMap;
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public hasVoted;
    mapping(address => bytes32) private voterHashes;
    mapping(address => bool) public isRegistered;

    bytes32[] public merkleProofs;

    event ElectionStarted();
    event ElectionEnded(uint256 indexed totalVotes);
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
        candidates.push(Candidate(_name, 0));
    }

    function startElection() public onlyAdmin {
        require(electionState == ElectionState.Inactive, "Election is already active");
        electionState = ElectionState.Active;
        emit ElectionStarted();
    }

    function endElection() public onlyAdmin {
        require(electionState == ElectionState.Active, "Election is not active");
        electionState = ElectionState.Ended;
        collate();
        uint256 TotalNumberOfVoters;
        // uint256 winningCandidateIndex = getWinningCandidate();
        emit ElectionEnded(TotalNumberOfVoters);
    }

    function vote(uint256 _telephone, uint256 _electorate, uint256 _candidateIndex, bytes32[] memory _proof)
        public
        onlyVoter
        onlyAfterTimelock
        nonReentrant
    {
        require(!paused, "Election is paused.");
        require(electionState == ElectionState.Active, "Election is not active");
        require(!hasVoted[msg.sender], "Voter is already registered");
        bytes32 leaf = keccak256(abi.encodePacked(_telephone)); // Still undecided over telephone or evm address? or both.
        bytes32 merkleRoot = voterHashes[msg.sender];
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid Merkle proof");
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        require(_electorate < totalElectorates, "Invalid electorate");

        // Update the candidate's vote count in the specified Electorate
        electorates[_electorate].candidates[_candidateIndex].votes += 1;

        // Update the total votes for the candidate
        candidates[_candidateIndex].votes += 1;

        // Emit the Voted event with the electorate and candidate index
        emit Voted(msg.sender, _electorate, _candidateIndex);

        // Mark the voter as having voted
        hasVoted[msg.sender] = true;
    }

    uint256 public totalVoters; // State variable to store the total number of voters

    function collate() internal {
        require(electionState == ElectionState.Ended, "Election has not ended yet");

        // Collate votes for candidates
        for (uint256 i = 0; i < candidates.length; i++) {
            uint256 totalVotes = 0;
            for (uint256 j = 0; j < electorates.length; j++) {
                totalVotes += electorates[j].candidates[i].votes;
            }
            collatedCandidates.push(CollatedCandidate(candidates[i].name, totalVotes));
        }

        // Collate votes for electorates
        for (uint256 i = 0; i < electorates.length; i++) {
            uint256 totalSumVotes = 0;
            for (uint256 j = 0; j < candidates.length; j++) {
                totalSumVotes += electorates[i].candidates[j].votes;
            }
            collatedElectorates.push(CollatedElectorate(electorates[i].name, totalSumVotes));
        totalVoters = totalSumVotes; // Store the total number of voters
        }
    }

    // Getter function to access the total number of voters
    function getTotalVoters() public view returns (uint256) {
        return totalVoters;
    }

    
    function registerVoter(bytes32 _voterHash) public onlyAdmin {
        require(electionState == ElectionState.Inactive, "Registration is closed");
        require(!isRegistered[msg.sender], "Voter is already registered");
        isRegistered[msg.sender] = true;
        // Allow the public to push their registration fingerprints
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
