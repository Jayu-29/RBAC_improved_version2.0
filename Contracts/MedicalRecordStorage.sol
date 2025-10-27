// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./RBAC.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MedicalRecordStorage is ReentrancyGuard {
    using Counters for Counters.Counter;

    // =============================================================================================
    // Errors
    // =============================================================================================
    error MedicalRecordStorage__InvalidRBACAddress();
    error MedicalRecordStorage__Unauthorized();
    error MedicalRecordStorage__InvalidPatient();
    error MedicalRecordStorage__RecordDoesNotExist();
    error MedicalRecordStorage__RecordIsArchived();
    error MedicalRecordStorage__AlreadyArchived();

    // =============================================================================================
    // Type Declarations
    // =============================================================================================
    struct MedicalRecord {
        uint256 id;
        address doctor;
        string diagnosis;
        string treatment;
        uint256 timestamp;
        bool isActive;
    }

    // =============================================================================================
    // State Variables
    // =============================================================================================
    RBAC public immutable i_rbac;
    address public s_authorizedContractAddress; // Stores the DoctorContract address

    Counters.Counter private s_recordIds;
    mapping(address => uint256[]) private s_patientRecordIds;
    mapping(uint256 => MedicalRecord) private s_records;

    // =============================================================================================
    // Events
    // =============================================================================================
    event RecordAdded(
        uint256 indexed recordId,
        address indexed doctor,
        address indexed patient,
        uint256 timestamp
    );
    event RecordUpdated(uint256 indexed recordId, address indexed doctor, uint256 timestamp);
    event RecordArchived(uint256 indexed recordId, address indexed archivedBy, uint256 timestamp);

    // =============================================================================================
    // Modifiers
    // =============================================================================================
    modifier onlyAuthorized() {
        if (msg.sender != s_authorizedContractAddress && !i_rbac.checkUserRole(msg.sender, i_rbac.ADMIN_ROLE())) {
            revert MedicalRecordStorage__Unauthorized();
        }
        _;
    }

    // =============================================================================================
    // Constructor and Authorization Function
    // =============================================================================================
    constructor(address _rbac) {
        if (_rbac == address(0)) revert MedicalRecordStorage__InvalidRBACAddress();
        i_rbac = RBAC(_rbac);
    }

    function authorizeContract(address _contractAddress) external {
        if (!i_rbac.checkUserRole(msg.sender, i_rbac.ADMIN_ROLE())) {
            revert MedicalRecordStorage__Unauthorized();
        }
        s_authorizedContractAddress = _contractAddress;
    }

    // =============================================================================================
    // External Functions
    // =============================================================================================
    function addMedicalRecord(
        address _doctor,
        address _patient,
        string calldata _diagnosis,
        string calldata _treatment
    ) external nonReentrant onlyAuthorized {
        if (!i_rbac.checkUserRole(_patient, i_rbac.PATIENT_ROLE())) {
            revert MedicalRecordStorage__InvalidPatient();
        }

        s_recordIds.increment();
        uint256 newRecordId = s_recordIds.current();
        s_records[newRecordId] = MedicalRecord(
            newRecordId,
            _doctor,
            _diagnosis,
            _treatment,
            block.timestamp,
            true
        );
        s_patientRecordIds[_patient].push(newRecordId);

        emit RecordAdded(newRecordId, _doctor, _patient, block.timestamp);
    }

    function updateMedicalRecord(
        uint256 _recordId,
        string calldata _diagnosis,
        string calldata _treatment
    ) external nonReentrant onlyAuthorized {
        if (s_records[_recordId].id != _recordId) revert MedicalRecordStorage__RecordDoesNotExist();
        if (!s_records[_recordId].isActive) revert MedicalRecordStorage__RecordIsArchived();

        s_records[_recordId].diagnosis = _diagnosis;
        s_records[_recordId].treatment = _treatment;

        emit RecordUpdated(_recordId, msg.sender, block.timestamp);
    }

    function archiveRecord(uint256 _recordId) external onlyAuthorized {
        if (s_records[_recordId].id != _recordId) revert MedicalRecordStorage__RecordDoesNotExist();
        if (!s_records[_recordId].isActive) revert MedicalRecordStorage__AlreadyArchived();

        s_records[_recordId].isActive = false;

        emit RecordArchived(_recordId, msg.sender, block.timestamp);
    }

    // =============================================================================================
    // View & Pure Functions
    // =============================================================================================
    function getMedicalRecords(address _patient)
        external
        view
        returns (MedicalRecord[] memory)
    {
        uint256[] memory ids = s_patientRecordIds[_patient];
        MedicalRecord[] memory patientRecords = new MedicalRecord[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            patientRecords[i] = s_records[ids[i]];
        }
        return patientRecords;
    }

    function getMedicalRecord(uint256 _recordId)
        external
        view
        returns (MedicalRecord memory)
    {
        if (s_records[_recordId].id != _recordId) revert MedicalRecordStorage__RecordDoesNotExist();
        return s_records[_recordId];
    }
}