// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./RBAC.sol";
import "./PatientContract.sol";

contract PharmacistContract {
    // =============================================================================================
    // Errors
    // =============================================================================================
    error PharmacistContract__InvalidRBACAddress();
    error PharmacistContract__InvalidPatientContractAddress();
    error PharmacistContract__Unauthorized();
    error PharmacistContract__NoPatientConsent();
    error PharmacistContract__InvalidPrescriptionIndex();
    error PharmacistContract__AlreadyDispensed();
    error PharmacistContract__PrescriptionExpired();

    // =============================================================================================
    // Type Declarations
    // =============================================================================================
    struct Medication {
        string name;
        string dosage;
        uint256 prescribedAt;
        uint256 validUntil;
        bool dispensed;
    }

    // =============================================================================================
    // State Variables
    // =============================================================================================
    RBAC public immutable i_rbac;
    PatientContract public immutable i_patientContract;
    mapping(address => Medication[]) private s_patientMedications;

    // =============================================================================================
    // Events
    // =============================================================================================
    event MedicineDispensed(
        address indexed pharmacist,
        address indexed patient,
        string medicine,
        uint256 timestamp
    );
    event PrescriptionFilled(
        address indexed pharmacist,
        address indexed patient,
        uint256 indexed prescriptionIndex
    );

    // =============================================================================================
    // Modifiers
    // =============================================================================================
    modifier onlyPharmacist() {
        if (!i_rbac.checkUserRole(msg.sender, i_rbac.PHARMACIST_ROLE())) {
            revert PharmacistContract__Unauthorized();
        }
        _;
    }

    // =============================================================================================
    // Constructor
    // =============================================================================================
    constructor(address _rbac, address _patientContract) {
        if (_rbac == address(0)) revert PharmacistContract__InvalidRBACAddress();
        if (_patientContract == address(0))
            revert PharmacistContract__InvalidPatientContractAddress();
        i_rbac = RBAC(_rbac);
        i_patientContract = PatientContract(_patientContract);
    }

    // =============================================================================================
    // External Functions
    // =============================================================================================
    function dispenseMedicine(
        address _patient,
        string calldata _medicine,
        string calldata _dosage,
        uint256 _validDays
    ) external onlyPharmacist {
        if (!i_patientContract.checkConsent(_patient, msg.sender)) {
            revert PharmacistContract__NoPatientConsent();
        }

        s_patientMedications[_patient].push(
            Medication(
                _medicine,
                _dosage,
                block.timestamp,
                block.timestamp + (_validDays * 1 days),
                false
            )
        );

        emit MedicineDispensed(msg.sender, _patient, _medicine, block.timestamp);
    }

    function fillPrescription(address _patient, uint256 _prescriptionIndex)
        external
        onlyPharmacist
    {
        if (_prescriptionIndex >= s_patientMedications[_patient].length) {
            revert PharmacistContract__InvalidPrescriptionIndex();
        }
        if (s_patientMedications[_patient][_prescriptionIndex].dispensed) {
            revert PharmacistContract__AlreadyDispensed();
        }
        if (s_patientMedications[_patient][_prescriptionIndex].validUntil <= block.timestamp) {
            revert PharmacistContract__PrescriptionExpired();
        }

        s_patientMedications[_patient][_prescriptionIndex].dispensed = true;
        emit PrescriptionFilled(msg.sender, _patient, _prescriptionIndex);
    }

    // =============================================================================================
    // View & Pure Functions
    // =============================================================================================
    function getPatientMedications(address _patient)
        external
        view
        onlyPharmacist
        returns (Medication[] memory)
    {
        if (!i_patientContract.checkConsent(_patient, msg.sender)) {
            revert PharmacistContract__NoPatientConsent();
        }
        return s_patientMedications[_patient];
    }
}