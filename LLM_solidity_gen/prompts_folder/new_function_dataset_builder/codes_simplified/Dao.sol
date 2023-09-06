// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "../Roles.sol";

contract DaoRole is Context {
    using Roles for Roles.Role;

    event DaoAdded(address indexed account);
    event DaoRemoved(address indexed account);

    Roles.Role private _daos;

<FUNCTION_DELIMINATOR_JINAN789>
    constructor () {
        _addDao(_msgSender());
    }

    modifier onlyDao() {
        require(isDao(_msgSender()), "DaoRole: caller does not have the Dao role");
        _;
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function isDao(address account) public view returns (bool) {
        return _daos.has(account);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function addDao(address account) public onlyDao {
        _addDao(account);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function renounceDao() public {
        _removeDao(_msgSender());
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _addDao(address account) internal {
        _daos.add(account);
        emit DaoAdded(account);
    }
<FUNCTION_DELIMINATOR_JINAN789>
    function _removeDao(address account) internal {
        _daos.remove(account);
        emit DaoRemoved(account);
    }
}