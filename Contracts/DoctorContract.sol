// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./RBAC.sol";
import "./MedicalRecordStorage.sol";

contract DoctorContract {
    // =============================================================================================
    // Errors
    // =============================================================================================
    error DoctorContract__InvalidRBACAddress();
    error DoctorContract__InvalidStorageAddress();
    error DoctorContract__Unauthorized();

    // =============================================================================================
    // State Variables
    // =============================================================================================
    RBAC public immutable i_rbac;
    MedicalRecordStorage public immutable i_storageContract;

    // =============================================================================================
    // Events
    // =============================================================================================
    event ConsultationCompleted(address indexed doctor, address indexed patient, uint256 timestamp);

    // =============================================================================================
    // Modifiers
    // =============================================================================================
    modifier onlyDoctor() {
        if (!i_rbac.checkUserRole(msg.sender, i_rbac.DOCTOR_ROLE())) {
            revert DoctorContract__Unauthorized();
        }
        _;
    }

    // =============================================================================================
    // Constructor
    // =============================================================================================
    constructor(address _rbac, address _storage) {
        if (_rbac == address(0)) revert DoctorContract__InvalidRBACAddress();
        if (_storage == address(0)) revert DoctorContract__InvalidStorageAddress();
        i_rbac = RBAC(_rbac);
        i_storageContract = MedicalRecordStorage(_storage);
    }

    // =============================================================================================
    // External Functions
    // =============================================================================================
    function addMedicalRecord(
        address _patient,
        string calldata _diagnosis,
        string calldata _treatment
    ) external onlyDoctor {
        i_storageContract.addMedicalRecord(msg.sender, _patient, _diagnosis, _treatment);
        emit ConsultationCompleted(msg.sender, _patient, block.timestamp);
    }

    function updateMedicalRecord(
        uint256 _recordId,
        string calldata _diagnosis,
        string calldata _treatment
    ) external onlyDoctor {
        i_storageContract.updateMedicalRecord(_recordId, _diagnosis, _treatment);
    }

    function archiveRecord(uint256 _recordId) external onlyDoctor {
        i_storageContract.archiveRecord(_recordId);
    }
}