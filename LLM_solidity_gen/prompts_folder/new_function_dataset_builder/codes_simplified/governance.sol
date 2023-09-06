// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./GovernorBravoInterfaces.sol";

contract GovernorBravoDelegate is Initializable,UUPSUpgradeable,GovernorBravoDelegateStorageV2, GovernorBravoEvents {
    /// @notice Address of Investee.
    mapping (uint256 => address) public investeeDetails;
    
    /// @notice Next investee to support
    uint256 public nextInvestee;

    /// @notice Next investee to fund
    uint256 public nextInvesteeFund;

    /// @notice Treasury contract address
    address public treasury;

    /// @notice The name of this contract
    string public constant name = "Cult Governor Bravo";

    /// @notice The minimum setable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 50000e18; // 50,000 Cult

    /// @notice The maximum setable proposal threshold
    uint public constant MAX_PROPOSAL_THRESHOLD = 6000000000000e18; //6000000000000 Cult

    /// @notice The minimum setable voting period
    uint public constant MIN_VOTING_PERIOD = 1; // About 24 hours

    /// @notice The max setable voting period
    uint public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

    /// @notice The min setable voting delay
    uint public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public constant quorumVotes = 1000000000e18; // 1 Billion

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");

<FUNCTION_DELIMINATOR_JINAN789>
    function initialize(address timelock_, address dCult_, uint votingPeriod_, uint votingDelay_, uint proposalThreshold_, address treasury_) public initializer{
        require(address(timelock) == address(0), "GovernorBravo::initialize: can only initialize once");
        require(timelock_ != address(0), "GovernorBravo::initialize: invalid timelock address");
        require(dCult_ != address(0), "GovernorBravo::initialize: invalid dCult address");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "GovernorBravo::initialize: invalid voting period");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "GovernorBravo::initialize: invalid voting delay");
        require(proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD && proposalThreshold_ <= MAX_PROPOSAL_THRESHOLD, "GovernorBravo::initialize: invalid proposal threshold");
        require(treasury_ != address(0), "GovernorBravo::initialize: invalid treasury address");

        timelock = TimelockInterface(timelock_);
        dCult = dCultInterface(dCult_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThreshold = proposalThreshold_;
        admin = timelock_;
        treasury = treasury_;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        // Allow addresses above proposal threshold and whitelisted addresses to propose
        require(keccak256(abi.encodePacked(signatures[0])) == keccak256(abi.encodePacked("_setInvesteeDetails(address)")), "GovernorBravo::propose: invalid proposal");
        require(dCult.checkHighestStaker(0,msg.sender),"GovernorBravo::propose: only top staker");
        require(targets.length <= 1, "GovernorBravo::propose: too many targets");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorBravo::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorBravo::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "GovernorBravo::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorBravo::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay);
        uint endBlock = add256(startBlock, votingPeriod);

        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer= msg.sender;
        newProposal.eta= 0;
        newProposal.targets= targets;
        newProposal.values= values;
        newProposal.signatures= signatures;
        newProposal.calldatas= calldatas;
        newProposal.startBlock= startBlock;
        newProposal.endBlock= endBlock;
        newProposal.forVotes= 0;
        newProposal.againstVotes= 0;
        newProposal.abstainVotes= 0;
        newProposal.canceled= false;
        newProposal.executed= false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function queue(uint proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorBravo::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function queueOrRevertInternal(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function execute(uint proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorBravo::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value:proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function cancel(uint proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "GovernorBravo::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];

        require(msg.sender == proposal.proposer, "GovernorBravo::cancel: Other user cannot cancel proposal");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > initialProposalId, "GovernorBravo::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function castVote(uint proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function castVoteBySig(uint proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainIdInternal(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorBravo::castVoteBySig: invalid signature");
        emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), "");
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function castVoteInternal(address voter, uint proposalId, uint8 support) internal returns (uint256) {
        require(!dCult.checkHighestStaker(0,msg.sender),"GovernorBravo::castVoteInternal: Top staker cannot vote");
        require(state(proposalId) == ProposalState.Active, "GovernorBravo::castVoteInternal: voting is closed");
        require(support <= 2, "GovernorBravo::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorBravo::castVoteInternal: voter already voted");
        uint256 votes = dCult.getPastVotes(voter, proposal.startBlock);

        if (support == 0) {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        } else if (support == 1) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else if (support == 2) {
            proposal.abstainVotes = add256(proposal.abstainVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function isWhitelisted(address account) public view returns (bool) {
        return (whitelistAccountExpirations[account] > block.timestamp);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _setVotingDelay(uint newVotingDelay) external {
        require(false, "GovernorBravo::_setVotingDelay: disable voting delay update");
        require(msg.sender == admin, "GovernorBravo::_setVotingDelay: admin only");
        require(newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY, "GovernorBravo::_setVotingDelay: invalid voting delay");
        uint oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay,votingDelay);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _setInvesteeDetails(address _investee) external {
        require(msg.sender == admin, "GovernorBravo::_setInvesteeDetails: admin only");
        require(_investee != address(0), "GovernorBravo::_setInvesteeDetails: zero address");
        investeeDetails[nextInvestee] = _investee;
        nextInvestee =add256(nextInvestee,1);

        emit InvesteeSet(_investee,sub256(nextInvestee,1));
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _fundInvestee() external returns(address){
        require(msg.sender == treasury, "GovernorBravo::_fundInvestee: treasury only");
        require(nextInvesteeFund <= nextInvestee, "GovernorBravo::_fundInvestee: No new investee");

        nextInvesteeFund =add256(nextInvesteeFund,1);
        emit InvesteeFunded(investeeDetails[sub256(nextInvesteeFund,1)],sub256(nextInvesteeFund,1));
        return investeeDetails[sub256(nextInvesteeFund,1)];
    }


<FUNCTION_DELIMINATOR_JINAN789>
    function _setVotingPeriod(uint newVotingPeriod) external {
        require(false, "GovernorBravo::_setVotingPeriod: disable voting period update");
        require(msg.sender == admin, "GovernorBravo::_setVotingPeriod: admin only");
        require(newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD, "GovernorBravo::_setVotingPeriod: invalid voting period");
        uint oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _setProposalThreshold(uint newProposalThreshold) external {
        require(false, "GovernorBravo::_setProposalThreshold: disable proposal threshold update");
        require(msg.sender == admin, "GovernorBravo::_setProposalThreshold: admin only");
        require(newProposalThreshold >= MIN_PROPOSAL_THRESHOLD && newProposalThreshold <= MAX_PROPOSAL_THRESHOLD, "GovernorBravo::_setProposalThreshold: invalid proposal threshold");
        uint oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _setWhitelistAccountExpiration(address account, uint expiration) external {
        require(false, "GovernorBravo::_setWhitelistAccountExpiration: disable whitelist account expiration update");
        require(msg.sender == admin || msg.sender == whitelistGuardian, "GovernorBravo::_setWhitelistAccountExpiration: admin only");
        whitelistAccountExpirations[account] = expiration;

        emit WhitelistAccountExpirationSet(account, expiration);
    }

<FUNCTION_DELIMINATOR_JINAN789>
     function _setWhitelistGuardian(address account) external {
        require(false, "GovernorBravo::_setWhitelistGuardian: disable whitelist guardian update");
        // Check address is not zero
        require(account != address(0), "GovernorBravo:_setWhitelistGuardian: zero address");
        require(msg.sender == admin, "GovernorBravo::_setWhitelistGuardian: admin only");
        address oldGuardian = whitelistGuardian;
        whitelistGuardian = account;

        emit WhitelistGuardianSet(oldGuardian, whitelistGuardian);
     }

<FUNCTION_DELIMINATOR_JINAN789>
    function _initiate(address governorAlpha) external {
        require(false, "GovernorBravo::_initiate: disable initiate update");
        require(msg.sender == admin, "GovernorBravo::_initiate: admin only");
        require(initialProposalId == 0, "GovernorBravo::_initiate: can only initiate once");
        proposalCount = GovernorAlpha(governorAlpha).proposalCount();
        initialProposalId = proposalCount;
        timelock.acceptAdmin();
        emit GovernanceInitiated(governorAlpha);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _setPendingAdmin(address newPendingAdmin) external {
        require(false, "GovernorBravo::_setPendingAdmin: disable set pending admin update");
        // Check address is not zero
        require(newPendingAdmin != address(0), "GovernorBravo:_setPendingAdmin: zero address");
        // Check caller = admin
        require(msg.sender == admin, "GovernorBravo:_setPendingAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _acceptAdmin() external {
        require(false, "GovernorBravo::_acceptAdmin: disable accept admin update");
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "GovernorBravo:_acceptAdmin: pending admin only");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function _AcceptTimelockAdmin() external {
        timelock.acceptAdmin();
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _authorizeUpgrade(address) internal view override {
        require(admin == msg.sender, "Only admin can upgrade implementation");
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function getChainIdInternal() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}