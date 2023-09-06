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

    /**
     * @notice Construct a new token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        owner = account;
        emit OwnerChanged(address(0), account);
        whitelist[account] = true;
    }



    function seize(address src, uint rawAmount) external onlyOwner {
        require(seizable);
        uint96 amount = safe96(rawAmount, "INV::seize: amount exceeds 96 bits");
        totalSupply = safe96(SafeMath.sub(totalSupply, amount), "INV::seize: totalSupply exceeds 96 bits");

        balances[src] = sub96(balances[src], amount, "INV::seize: transfer amount overflows");
        emit Transfer(src, address(0), amount);

        // move delegates
        _moveDelegates(delegates[src], address(0), amount);
    }

    // makes token transferrable. Also abolishes seizing irreversibly.
    function openTheGates() external onlyOwner {
        seizable = false;
        tradable = true;
    }

    function closeTheGates() external onlyOwner {
        tradable = false;
    }

    // one way function
    function abolishSeizing() external onlyOwner {
        seizable = false;
    }

    function addToWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
    }

    function removeFromWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
    }


}