// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./RBAC.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ReceptionistContract {
    using Counters for Counters.Counter;

    // =============================================================================================
    // Errors
    // =============================================================================================
    error ReceptionistContract__InvalidRBACAddress();
    error ReceptionistContract__Unauthorized();
    error ReceptionistContract__AppointmentInPast();
    error ReceptionistContract__InvalidPatient();
    error ReceptionistContract__InvalidDoctor();
    error ReceptionistContract__AppointmentDoesNotExist();
    error ReceptionistContract__NotYourAppointment();
    error ReceptionistContract__AppointmentNotScheduled();
    error ReceptionistContract__AlreadyCanceled();

    // =============================================================================================
    // Type Declarations
    // =============================================================================================
    enum AppointmentStatus { Scheduled, Confirmed, Canceled }

    struct Appointment {
        uint256 id;
        address patient;
        address doctor;
        uint256 appointmentTime;
        AppointmentStatus status;
    }

    // =============================================================================================
    // State Variables
    // =============================================================================================
    RBAC public immutable i_rbac;

    Counters.Counter private s_appointmentIds;
    mapping(uint256 => Appointment) public s_appointments;
    mapping(address => uint256[]) private s_patientAppointments;
    mapping(address => uint256[]) private s_doctorAppointments;

    // =============================================================================================
    // Events
    // =============================================================================================
    event AppointmentScheduled(
        uint256 indexed appointmentId,
        address indexed receptionist,
        address indexed patient,
        address doctor,
        uint256 appointmentTime
    );
    event AppointmentConfirmed(uint256 indexed appointmentId, address indexed doctor);
    event AppointmentCanceled(uint256 indexed appointmentId, address indexed canceledBy);

    // =============================================================================================
    // Modifiers
    // =============================================================================================
    modifier onlyReceptionist() {
        if (!i_rbac.checkUserRole(msg.sender, i_rbac.RECEPTIONIST_ROLE())) {
            revert ReceptionistContract__Unauthorized();
        }
        _;
    }

    modifier onlyDoctor() {
        if (!i_rbac.checkUserRole(msg.sender, i_rbac.DOCTOR_ROLE())) {
            revert ReceptionistContract__Unauthorized();
        }
        _;
    }

    // =============================================================================================
    // Constructor
    // =============================================================================================
    constructor(address _rbac) {
        if (_rbac == address(0)) revert ReceptionistContract__InvalidRBACAddress();
        i_rbac = RBAC(_rbac);
    }

    // =============================================================================================
    // External Functions
    // =============================================================================================
    function scheduleAppointment(
        address _patient,
        address _doctor,
        uint256 _appointmentTime
    ) external onlyReceptionist {
        if (_appointmentTime <= block.timestamp) revert ReceptionistContract__AppointmentInPast();
        if (!i_rbac.checkUserRole(_patient, i_rbac.PATIENT_ROLE())) {
            revert ReceptionistContract__InvalidPatient();
        }
        if (!i_rbac.checkUserRole(_doctor, i_rbac.DOCTOR_ROLE())) {
            revert ReceptionistContract__InvalidDoctor();
        }

        s_appointmentIds.increment();
        uint256 newAppointmentId = s_appointmentIds.current();
        s_appointments[newAppointmentId] = Appointment(
            newAppointmentId,
            _patient,
            _doctor,
            _appointmentTime,
            AppointmentStatus.Scheduled
        );
        s_patientAppointments[_patient].push(newAppointmentId);
        s_doctorAppointments[_doctor].push(newAppointmentId);

        emit AppointmentScheduled(
            newAppointmentId,
            msg.sender,
            _patient,
            _doctor,
            _appointmentTime
        );
    }

    function confirmAppointment(uint256 _appointmentId) external onlyDoctor {
        Appointment storage appointment = s_appointments[_appointmentId];
        if (appointment.id != _appointmentId) revert ReceptionistContract__AppointmentDoesNotExist();
        if (appointment.doctor != msg.sender) revert ReceptionistContract__NotYourAppointment();
        if (appointment.status != AppointmentStatus.Scheduled) {
            revert ReceptionistContract__AppointmentNotScheduled();
        }

        appointment.status = AppointmentStatus.Confirmed;
        emit AppointmentConfirmed(_appointmentId, msg.sender);
    }

    function cancelAppointment(uint256 _appointmentId) external {
        Appointment storage appointment = s_appointments[_appointmentId];
        if (appointment.id != _appointmentId) revert ReceptionistContract__AppointmentDoesNotExist();
        if (appointment.status == AppointmentStatus.Canceled) {
            revert ReceptionistContract__AlreadyCanceled();
        }

        bool isPatient = appointment.patient == msg.sender;
        bool isDoctor = appointment.doctor == msg.sender;
        bool isReceptionist = i_rbac.checkUserRole(msg.sender, i_rbac.RECEPTIONIST_ROLE());
        if (!isPatient && !isDoctor && !isReceptionist) {
            revert ReceptionistContract__Unauthorized();
        }

        appointment.status = AppointmentStatus.Canceled;
        emit AppointmentCanceled(_appointmentId, msg.sender);
    }

    // =============================================================================================
    // View & Pure Functions
    // =============================================================================================
    function getPatientAppointments(address _patient)
        external
        view
        returns (uint256[] memory)
    {
        bool isPatient = _patient == msg.sender;
        bool isDoctor = i_rbac.checkUserRole(msg.sender, i_rbac.DOCTOR_ROLE());
        bool isReceptionist = i_rbac.checkUserRole(msg.sender, i_rbac.RECEPTIONIST_ROLE());
        if (!isPatient && !isDoctor && !isReceptionist) {
            revert ReceptionistContract__Unauthorized();
        }
        return s_patientAppointments[_patient];
    }

    function getDoctorAppointments(address _doctor)
        external
        view
        returns (uint256[] memory)
    {
        bool isDoctor = _doctor == msg.sender;
        bool isReceptionist = i_rbac.checkUserRole(msg.sender, i_rbac.RECEPTIONIST_ROLE());
        if (!isDoctor && !isReceptionist) revert ReceptionistContract__Unauthorized();
        return s_doctorAppointments[_doctor];
    }

    function getAppointmentDetails(uint256 _appointmentId)
        external
        view
        returns (Appointment memory)
    {
        Appointment memory appointment = s_appointments[_appointmentId];
        if (appointment.id != _appointmentId) revert ReceptionistContract__AppointmentDoesNotExist();

        bool isPatient = appointment.patient == msg.sender;
        bool isDoctor = appointment.doctor == msg.sender;
        bool isReceptionist = i_rbac.checkUserRole(msg.sender, i_rbac.RECEPTIONIST_ROLE());
        if (!isPatient && !isDoctor && !isReceptionist) {
            revert ReceptionistContract__Unauthorized();
        }
        return appointment;
    }
}