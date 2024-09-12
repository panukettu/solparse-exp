// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Auth, AuthorizationFull} from "../src/utils/AuthorizationFull.sol";
import {__revert} from "../src/utils/Funcs.sol";

struct Init {
    address operator;
    address keeper;
    address owner;
}

library Role {
    bytes32 internal constant KEEPERS = keccak256("auth.role.keepers");
    bytes32 internal constant OPERATOR = keccak256("auth.role.operator");
}

contract TDummy {
    TFullAuth public immutable tAuth;
    mapping(address => uint256) public values;

    constructor(address _tAuth) {
        tAuth = TFullAuth(_tAuth);
    }

    modifier auth() {
        tAuth.authorize(msg.sender, address(this));
        _;
    }

    function setValue(address addr, uint256 val) public auth {
        values[addr] = val;
    }
}

contract TFullAuth is AuthorizationFull {
    using Auth for bytes32;

    mapping(address => uint256) public values;

    uint256 public keeperValue;
    uint256 public adminValue;
    uint256 public operatorValue;

    address public keeper;

    constructor(Init memory init) {
        keeper = init.keeper;
        initAuth(msg.sender).owner = init.owner;
        Role.KEEPERS.setParent(Role.OPERATOR);
        Role.OPERATOR.setLimit(1);

        Auth.grant(init.operator, Role.OPERATOR);
        Auth.grant(init.keeper, Role.KEEPERS);

        Auth.grant(msg.sender, address(this));
        Auth.g
    }

    function setKeeper(
        address _keeper
    ) public authHeld(Role.OPERATOR, 1 minutes) {
        keeper = _keeper;
    }

    function setOperatorValue(uint256 val) public auth(Role.OPERATOR) {
        operatorValue = val;
    }

    function setAdminValue(uint256 val) public auth(Auth.SUDO) {
        adminValue = val;
    }

    function setKeeperValue(uint256 val) public auth(Role.KEEPERS) {
        keeperValue = val;
    }

    function setValueAuth(
        address addr,
        uint256 val
    ) public authOr(Role.OPERATOR, Auth.SUDO) {
        values[addr] = val;
    }
    function setValue(
        address addr,
        uint256 val
    ) public authIf(msg.sender != addr, Role.KEEPERS) {
        values[addr] = val;
    }

    function delegate(
        address addr,
        bytes memory data
    ) public payable guard(addr) {
        (bool success, bytes memory retData) = addr.delegatecall(data);
        if (!success) __revert(retData);
    }
}
