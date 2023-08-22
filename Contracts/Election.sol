// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract Election is Ownable, ReentrancyGuard {
    uint256 public timeLock = 24 hours;
    address private voteraddress;
    address public guard;

    //Arrays

    //Mappings 
    
    mapping(address => uint256) public entryMap;
    mapping(address => uint256) public VoteCheck;

    constructore(
    address _voteraddress,
    address _guard
    ) {
    guard = _guard;
    voteraddress = _voteraddress
    }

modifier onlyGuard {
  require(msg.sender == guard, "Not Authorized");
  _;
}

modifier onlyAfterTimelock {            
  require(entryMap[msg.sender] + timeLock < block.timestamp, "Timelocked.");
  _;
}

modifier onlyVoter() {             
        require(VoteCheck[msg.sender] + timeLock < block.timestamp, "Timelocked.");
        _;
}


    
    }
