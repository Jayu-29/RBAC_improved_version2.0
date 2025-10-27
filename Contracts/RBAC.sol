// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RBAC is AccessControl {
    // =============================================================================================
    // Errors
    // =============================================================================================
    error RBAC__InvalidAddress();
    error RBAC__UserAlreadyHasRole();
    error RBAC__UserDoesNotExist();
    error RBAC__UserDoesNotHaveRole();

    // =============================================================================================
    // Type Declarations
    // =============================================================================================
    struct User {
        address userAddress;
        bytes32 role;
        uint256 createdAt;
        bool isActive;
    }

    // =============================================================================================
    // State Variables
    // =============================================================================================
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR");
    bytes32 public constant NURSE_ROLE = keccak256("NURSE");
    bytes32 public constant RECEPTIONIST_ROLE = keccak256("RECEPTIONIST");
    bytes32 public constant PHARMACIST_ROLE = keccak256("PHARMACIST");
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT");

    mapping(address => User) public s_users;
    address[] public s_allUsers;

    // =============================================================================================
    // Events
    // =============================================================================================
    event UserAdded(address indexed user, bytes32 indexed role, uint256 timestamp);
    event UserStatusChanged(address indexed user, bool isActive, uint256 timestamp);
    event RoleRevoked(address indexed user, bytes32 indexed role, uint256 timestamp);

    // =============================================================================================
    // Constructor
    // =============================================================================================
    constructor() {
        // Grant the necessary roles to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        // Set up the role hierarchy
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(DOCTOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(NURSE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RECEPTIONIST_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PHARMACIST_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PATIENT_ROLE, ADMIN_ROLE);

        // Add the deployer (admin) to the custom user management system
        s_users[msg.sender] = User(msg.sender, ADMIN_ROLE, block.timestamp, true);
        s_allUsers.push(msg.sender);
    }

    // =============================================================================================
    // External Functions
    // =============================================================================================
    function addUser(address _user, bytes32 _role) external onlyRole(ADMIN_ROLE) {
        if (_user == address(0)) revert RBAC__InvalidAddress();
        if (hasRole(_role, _user)) revert RBAC__UserAlreadyHasRole();

        _grantRole(_role, _user);
        if (s_users[_user].userAddress == address(0)) {
            s_allUsers.push(_user);
        }
        s_users[_user] = User(_user, _role, block.timestamp, true);

        emit UserAdded(_user, _role, block.timestamp);
    }

    function revokeUserRole(address _user, bytes32 _role) external onlyRole(ADMIN_ROLE) {
        if (!hasRole(_role, _user)) revert RBAC__UserDoesNotHaveRole();
        _revokeRole(_role, _user);
        emit RoleRevoked(_user, _role, block.timestamp);
    }

    function setUserStatus(address _user, bool _status) external onlyRole(ADMIN_ROLE) {
        if (s_users[_user].userAddress == address(0)) revert RBAC__UserDoesNotExist();
        s_users[_user].isActive = _status;
        emit UserStatusChanged(_user, _status, block.timestamp);
    }

    // =============================================================================================
    // View & Pure Functions
    // =============================================================================================
    function checkUserRole(address _user, bytes32 _role) public view returns (bool) {
        return hasRole(_role, _user) && s_users[_user].isActive;
    }

    function getAllUsers() public view onlyRole(ADMIN_ROLE) returns (address[] memory) {
        return s_allUsers;
    }
}