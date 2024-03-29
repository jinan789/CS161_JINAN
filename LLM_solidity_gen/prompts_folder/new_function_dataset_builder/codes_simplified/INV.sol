pragma solidity ^0.5.16;

pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

contract INV {
    /// @notice EIP-20 token name for this token
    string public constant name = "Inverse DAO";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "INV";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 100000e18; // 100k

    /// @notice Address which may mint new tokens
    address public owner;

    bool public tradable;
    bool public seizable = true;

    mapping (address => bool) public whitelist; // addresses allowed to send when non-tradable

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when the owner address is changed
    event OwnerChanged(address owner, address newOwner);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == owner, "INV: only the owner can call this method");
        _;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    constructor(address account) public {

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        owner = account;
        emit OwnerChanged(address(0), account);
        whitelist[account] = true;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function setOwner(address owner_) external onlyOwner {
        emit OwnerChanged(owner, owner_);
        owner = owner_;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function seize(address src, uint rawAmount) external onlyOwner {
        require(seizable);
        uint96 amount = safe96(rawAmount, "INV::seize: amount exceeds 96 bits");
        totalSupply = safe96(SafeMath.sub(totalSupply, amount), "INV::seize: totalSupply exceeds 96 bits");

        balances[src] = sub96(balances[src], amount, "INV::seize: transfer amount overflows");
        emit Transfer(src, address(0), amount);

        // move delegates
        _moveDelegates(delegates[src], address(0), amount);
    }

<FUNCTION_DELIMINATOR_JINAN789>    
    function openTheGates() external onlyOwner {
        seizable = false;
        tradable = true;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function closeTheGates() external onlyOwner {
        tradable = false;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function abolishSeizing() external onlyOwner {
        seizable = false;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function addToWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function removeFromWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function mint(address dst, uint rawAmount) external {
        require(msg.sender == owner, "INV::mint: only the owner can mint");
        require(dst != address(0), "INV::mint: cannot transfer to the zero address");

        // mint the amount
        uint96 amount = safe96(rawAmount, "INV::mint: amount exceeds 96 bits");
        totalSupply = safe96(SafeMath.add(totalSupply, amount), "INV::mint: totalSupply exceeds 96 bits");

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount, "INV::mint: transfer amount overflows");
        emit Transfer(address(0), dst, amount);

        // move delegates
        _moveDelegates(address(0), delegates[dst], amount);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "INV::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function permit(address _owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "INV::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, _owner, spender, rawAmount, nonces[_owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INV::permit: invalid signature");
        require(signatory == _owner, "INV::permit: unauthorized");
        require(now <= deadline, "INV::permit: signature expired");

        allowances[_owner][spender] = amount;

        emit Approval(_owner, spender, amount);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "INV::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "INV::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "INV::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INV::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "INV::delegateBySig: invalid nonce");
        require(now <= expiry, "INV::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

<FUNCTION_DELIMINATOR_JINAN789>
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "INV::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "INV::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "INV::_transferTokens: cannot transfer to the zero address");

        if(!tradable) {
            require(whitelist[src], "INV::_transferTokens: src not whitelisted");
        }

        balances[src] = sub96(balances[src], amount, "INV::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "INV::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "INV::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "INV::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "INV::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}