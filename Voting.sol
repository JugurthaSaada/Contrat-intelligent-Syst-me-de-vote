// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Voting is Ownable {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    WorkflowStatus public workflowStatus;
    uint public winningProposalId;

    mapping(address => Voter) public voters;
    Proposal[] public proposals;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted(address voter, uint proposalId);

    constructor()Ownable(msg.sender) {
        workflowStatus = WorkflowStatus.RegisteringVoters;
    }

    modifier inState(WorkflowStatus state) {
        require(workflowStatus == state, "Invalid workflow state");
        _;
    }

    function startProposalsRegistration() external onlyOwner inState(WorkflowStatus.RegisteringVoters) {
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function endProposalsRegistration() external onlyOwner inState(WorkflowStatus.ProposalsRegistrationStarted) {
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() external onlyOwner inState(WorkflowStatus.ProposalsRegistrationEnded) {
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession() external onlyOwner inState(WorkflowStatus.VotingSessionStarted) {
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    function tallyVotes() external onlyOwner inState(WorkflowStatus.VotingSessionEnded) {
        workflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
    }

    function registerVoter(address voterAddress) external onlyOwner inState(WorkflowStatus.RegisteringVoters) {
        require(!voters[voterAddress].isRegistered, "Voteur deja inscrit");
        voters[voterAddress].isRegistered = true;
        emit VoterRegistered(voterAddress);
    }

    function submitProposal(string memory description) external inState(WorkflowStatus.ProposalsRegistrationStarted) {
        proposals.push(Proposal({
            description: description,
            voteCount: 0
        }));
        emit ProposalRegistered(proposals.length - 1);
    }

    function vote(uint proposalId) external {
        Voter storage voter = voters[msg.sender];
        require(voter.isRegistered, "Voteur n'est pas enregistre");
        require(!voter.hasVoted, "Voteur a deja vote");
        require(proposalId < proposals.length, "ID de propositon, invalide");
        voter.hasVoted = true;
        voter.votedProposalId = proposalId;
        proposals[proposalId].voteCount++;
        emit Voted(msg.sender, proposalId);
    }

    function getWinner() external view inState(WorkflowStatus.VotesTallied) returns (uint) {
        require(winningProposalId < proposals.length, "Aucun gagnant");
        return winningProposalId;
    }
}
