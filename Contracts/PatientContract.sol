// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./RBAC.sol";
import "./MedicalRecordStorage.sol";

contract PatientContract {
    // =============================================================================================
    // Errors
    // =============================================================================================
    error PatientContract__InvalidRBACAddress();
    error PatientContract__InvalidStorageAddress();
    error PatientContract__Unauthorized();
    error PatientContract__InvalidProviderAddress();
    error PatientContract__InvalidDuration();
    error PatientContract__NoActiveConsent();

    // =============================================================================================
    // Type Declarations
    // =============================================================================================
    struct Consent {
        address provider;
        uint256 expiryTime;
        bool isActive;
    }

    // =============================================================================================
    // State Variables
    // =============================================================================================
    RBAC public immutable i_rbac;
    MedicalRecordStorage public immutable i_storageContract;
    mapping(address => mapping(address => Consent)) private s_consents;

    // =============================================================================================
    // Events
    // =============================================================================================
    event ConsentGiven(address indexed patient, address indexed provider, uint256 expiryTime);
    event ConsentRevoked(address indexed patient, address indexed provider);

    // =============================================================================================
    // Modifiers
    // =============================================================================================
    modifier onlyPatient() {
        if (!i_rbac.checkUserRole(msg.sender, i_rbac.PATIENT_ROLE())) {
            revert PatientContract__Unauthorized();
        }
        _;
    }

    // =============================================================================================
    // Constructor
    // =============================================================================================
    constructor(address _rbac, address _storage) {
        if (_rbac == address(0)) revert PatientContract__InvalidRBACAddress();
        if (_storage == address(0)) revert PatientContract__InvalidStorageAddress();
        i_rbac = RBAC(_rbac);
        i_storageContract = MedicalRecordStorage(_storage);
    }

    // =============================================================================================
    // External Functions
    // =============================================================================================
    function giveConsent(address _provider, uint256 _durationDays) external onlyPatient {
        if (_provider == address(0)) revert PatientContract__InvalidProviderAddress();
        if (_durationDays == 0) revert PatientContract__InvalidDuration();

        uint256 expiryTime = block.timestamp + (_durationDays * 1 days);
        s_consents[msg.sender][_provider] = Consent(_provider, expiryTime, true);

        emit ConsentGiven(msg.sender, _provider, expiryTime);
    }

    function revokeConsent(address _provider) external onlyPatient {
        if (!s_consents[msg.sender][_provider].isActive) {
            revert PatientContract__NoActiveConsent();
        }
        s_consents[msg.sender][_provider].isActive = false;
        emit ConsentRevoked(msg.sender, _provider);
    }

    // =============================================================================================
    // View & Pure Functions
    // =============================================================================================
    function getMyMedicalRecords()
        external
        view
        onlyPatient
        returns (MedicalRecordStorage.MedicalRecord[] memory)
    {
        return i_storageContract.getMedicalRecords(msg.sender);
    }

    function checkConsent(address _patient, address _provider) external view returns (bool) {
        Consent memory consent = s_consents[_patient][_provider];
        return consent.isActive && consent.expiryTime > block.timestamp;
    }
}