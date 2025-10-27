# Blockchain-Based Healthcare Management System with Hybrid RBAC

A secure, decentralized healthcare management system built on Ethereum blockchain, featuring a novel Hybrid Role-Based Access Control (RBAC) model and multi-contract architecture for managing sensitive medical records with granular permission control.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Security Model](#security-model)
- [Smart Contracts](#smart-contracts)
- [Setup & Deployment](#setup--deployment)
- [Testing Guide](#testing-guide)
- [Technical Specifications](#technical-specifications)
- [License](#license)

## Overview

This project implements a comprehensive healthcare data management solution on the Ethereum blockchain. The system employs a multi-contract architecture to manage medical records, patient consent, and role-based permissions for healthcare professionals with maximum security and flexibility.

### Key Features

- **Hybrid RBAC Model**: Dual-layered access control combining OpenZeppelin's battle-tested AccessControl with custom dynamic management
- **Gated Access Pattern**: Defense-in-depth security preventing unauthorized direct access to sensitive data
- **Real-time Permission Management**: Dynamic enable/disable capabilities without permanent role revocation
- **Patient-Centric Consent**: Granular control over data sharing and medication dispensing
- **Complete Audit Trail**: Immutable blockchain records of all healthcare interactions

### Core Objectives

1. **Enforce Least Privilege**: Users receive only the minimum permissions necessary for their specific healthcare role
2. **Dynamic Administrative Control**: Real-time access management without altering permanent role assignments
3. **Secure Inter-Contract Communication**: Protected data storage through pre-authorized contract whitelisting
4. **Standards-Based Security**: Built on OpenZeppelin's audited libraries to maximize trust and security

## Architecture

### System Design

The system implements a modular, layered architecture with clear separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                     Admin Layer                        │
│                    (RBAC Contract)                     │
└────────────────────┬───────────────────────────────────┘
                     │
        ┌────────────┼─────────────┬───────────┐
        │            │             │           │
┌───────▼──────┐ ┌───▼──────┐ ┌───▼──────┐ ┌───▼──────┐
│   Doctor     │ │ Patient  │ │Pharmacist│ │Reception │
│  Contract    │ │ Contract │ │ Contract │ │ Contract │
└───────┬──────┘ └────┬─────┘ └────┬─────┘ └──────────┘
        │             │            │
        └─────────────┼────────────┘
                      │
        ┌─────────────▼─────────────┐
        │  MedicalRecordStorage     │
        │    (Data Vault Layer)     │
        └───────────────────────────┘
```

### Contract Relationships

- **RBAC Contract**: Central authority for all permission checks
- **Storage Contract**: Secured data vault with gated access
- **Interface Contracts**: Role-specific gateways (Doctor, Patient, Pharmacist, Receptionist)

## Security Model

### Hybrid RBAC Architecture

The system implements a two-layered security model:

#### Layer 1: Foundation (OpenZeppelin AccessControl)

- Manages cryptographic role assignments using `bytes32` role hashes
- Provides core `hasRole()` verification
- Implements hierarchical admin roles with `DEFAULT_ADMIN_ROLE`
- Battle-tested, community-audited implementation

#### Layer 2: Custom Management Layer

- Adds `isActive` boolean flag to user accounts via `s_users` mapping
- Central `checkUserRole()` function performs dual verification:
  1. Role possession check (OpenZeppelin)
  2. Account active status check (Custom)
- Enables temporary access revocation without role removal
- Provides granular real-time control for administrators

```solidity
// Hybrid RBAC Check Pattern
function checkUserRole(address user, bytes32 role) public view returns (bool) {
    return hasRole(role, user) && s_users[user].isActive;
}
```

### Gated Access Pattern

The `MedicalRecordStorage` contract implements a zero-trust security model:

```solidity
modifier onlyAuthorized() {
    require(
        authorizedContracts[msg.sender] || hasRole(ADMIN_ROLE, msg.sender),
        "Unauthorized access"
    );
    _;
}
```

**Security Benefits:**

- Prevents direct manipulation of sensitive data
- Enforces business logic through authorized gateways
- Maintains separation between data storage and access control
- Reduces attack surface significantly

### Additional Security Measures

- **ReentrancyGuard**: Protection against re-entrancy attacks on state-changing functions
- **Safe Counter Incrementing**: OpenZeppelin's Counter library for overflow-safe ID generation
- **Event Logging**: Comprehensive event emissions for off-chain monitoring and audit trails

## Smart Contracts

### 1. RBAC.sol

**Purpose**: Central authority and permission management hub

**Key Functions:**

- `addUser(address _user, bytes32 _role)`: Register new users with specific roles
- `removeUser(address _user)`: Deactivate user accounts
- `grantRole(bytes32 role, address account)`: Assign roles (OpenZeppelin)
- `checkUserRole(address user, bytes32 role)`: Hybrid permission verification

**Role Definitions:**

```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR_ROLE");
bytes32 public constant PATIENT_ROLE = keccak256("PATIENT_ROLE");
bytes32 public constant PHARMACIST_ROLE = keccak256("PHARMACIST_ROLE");
bytes32 public constant RECEPTIONIST_ROLE = keccak256("RECEPTIONIST_ROLE");
```

### 2. MedicalRecordStorage.sol

**Purpose**: Secure data vault for medical records

**Security Features:**

- Gated Access Pattern with `onlyAuthorized` modifier
- Whitelisted contract authorization system
- Admin override capabilities for emergency access

**Key Functions:**

- `authorizeContract(address _contract)`: Whitelist trusted contracts
- `addMedicalRecord(...)`: Store new medical records (restricted)
- `getMedicalRecords(address _patient)`: Retrieve patient records (restricted)

**Data Structure:**

```solidity
struct MedicalRecord {
    uint256 id;
    address patient;
    address doctor;
    string diagnosis;
    string treatment;
    uint256 timestamp;
}
```

### 3. DoctorContract.sol

**Purpose**: Gateway for medical professional interactions

**Key Features:**

- `onlyDoctor` modifier for role verification
- Authenticated forwarding to storage layer
- Medical record creation and retrieval

**Key Functions:**

- `addMedicalRecord(address _patient, string memory _diagnosis, string memory _treatment)`
- `getPatientRecords(address _patient)`: View patient history

### 4. PatientContract.sol

**Purpose**: Patient interface and consent management

**Key Features:**

- Self-service record access
- Consent management for pharmacists
- Privacy-first design

**Key Functions:**

- `getMyMedicalRecords()`: View own records
- `giveConsentToPharmacist(address _pharmacist)`: Grant medication access
- `revokeConsentFromPharmacist(address _pharmacist)`: Revoke access

### 5. PharmacistContract.sol

**Purpose**: Medication dispensing with consent verification

**Key Features:**

- Consent-based access model
- Integration with patient consent system
- Medication dispensing tracking

**Key Functions:**

- `dispenseMedication(address _patient, string memory _medication)`: Dispense with consent check

### 6. ReceptionistContract.sol

**Purpose**: Appointment lifecycle management

**Key Features:**

- Multi-party appointment workflow
- Status tracking (Pending, Confirmed, Cancelled, Completed)
- Role-based action permissions

**Key Functions:**

- `scheduleAppointment(address _patient, address _doctor, uint256 _timestamp)`: Create appointments
- `confirmAppointment(uint256 _appointmentId)`: Doctor confirmation
- `cancelAppointment(uint256 _appointmentId)`: Multi-party cancellation

## Setup & Deployment

### Prerequisites

- **Remix IDE**: https://remix.ethereum.org
- **MetaMask**: Browser extension for Ethereum interaction
- **Test Network**: Ganache, Hardhat Network, or Ethereum testnet (Sepolia recommended)

### Environment Setup

1. **Open Remix IDE** in your browser
2. **Create Project Structure**:
   ```
   contracts/
   ├── RBAC.sol
   ├── MedicalRecordStorage.sol
   ├── DoctorContract.sol
   ├── PatientContract.sol
   ├── PharmacistContract.sol
   └── ReceptionistContract.sol
   ```

3. **Configure Compiler**:
   - Solidity Version: `^0.8.18`
   - Enable Optimization: `200 runs`
   - EVM Version: `london` or higher

### Deployment Sequence

**CRITICAL**: Deploy contracts in the exact order specified below. Each contract depends on previously deployed addresses.

#### Step 1: Deploy RBAC Contract

```solidity
// No constructor parameters required
// Deployer becomes DEFAULT_ADMIN_ROLE
```

**Action**: Copy the deployed contract address.

#### Step 2: Deploy MedicalRecordStorage

```solidity
constructor(address _rbacAddress)
```

**Parameters**:
- `_rbacAddress`: Address from Step 1

**Action**: Copy the deployed contract address.

#### Step 3: Deploy DoctorContract

```solidity
constructor(address _rbacAddress, address _storageAddress)
```

**Parameters**:
- `_rbacAddress`: Address from Step 1
- `_storageAddress`: Address from Step 2

**Action**: Copy the deployed contract address.

#### Step 4: Deploy PatientContract

```solidity
constructor(address _rbacAddress, address _storageAddress)
```

**Parameters**:
- `_rbacAddress`: Address from Step 1
- `_storageAddress`: Address from Step 2

**Action**: Copy the deployed contract address.

#### Step 5: Deploy PharmacistContract

```solidity
constructor(address _rbacAddress, address _patientAddress)
```

**Parameters**:
- `_rbacAddress`: Address from Step 1
- `_patientAddress`: Address from Step 4

#### Step 6: Deploy ReceptionistContract

```solidity
constructor(address _rbacAddress)
```

**Parameters**:
- `_rbacAddress`: Address from Step 1

### Post-Deployment Configuration

#### Authorize DoctorContract

**Account**: Admin (deployer account)

**Contract**: MedicalRecordStorage

**Function**: `authorizeContract(address _contract)`

**Parameters**:
- `_contract`: DoctorContract address from Step 3

This step is **mandatory** for the system to function. Without it, doctors cannot write medical records.

## Testing Guide

Follow this comprehensive workflow to test all system capabilities.

### Account Setup

Configure the following accounts in Remix:

| Account Index | Role | Usage |
|---------------|------|-------|
| Account 0 | Admin | System deployment and management |
| Account 1 | Doctor | Medical record creation |
| Account 2 | Patient | Record access and consent |
| Account 3 | Pharmacist | Medication dispensing |
| Account 4 | Receptionist | Appointment scheduling |

### Test Scenario 1: User Registration

**Objective**: Create users with appropriate roles

**Account**: Admin (Account 0)

**Contract**: RBAC

**Steps**:

1. Create Doctor:
   ```solidity
   addUser(
       "0x...", // Account 1 address
       keccak256("DOCTOR_ROLE")
   )
   ```

2. Create Patient:
   ```solidity
   addUser(
       "0x...", // Account 2 address
       keccak256("PATIENT_ROLE")
   )
   ```

3. Create Pharmacist:
   ```solidity
   addUser(
       "0x...", // Account 3 address
       keccak256("PHARMACIST_ROLE")
   )
   ```

4. Create Receptionist:
   ```solidity
   addUser(
       "0x...", // Account 4 address
       keccak256("RECEPTIONIST_ROLE")
   )
   ```

**Verification**: Call `checkUserRole()` for each account to confirm active status.

### Test Scenario 2: Medical Record Creation

**Objective**: Doctor creates a medical record for patient

**Account**: Doctor (Account 1)

**Contract**: DoctorContract

**Function**: `addMedicalRecord()`

**Parameters**:
```solidity
_patient: "0x..." // Patient address (Account 2)
_diagnosis: "Acute Bronchitis"
_treatment: "Prescribed antibiotics and rest"
```

**Expected Result**: Transaction succeeds, event `MedicalRecordAdded` emitted

**Verification**: 
- Check transaction logs for event emission
- Patient should see record in next test

### Test Scenario 3: Patient Record Access

**Objective**: Patient views their own medical records

**Account**: Patient (Account 2)

**Contract**: PatientContract

**Function**: `getMyMedicalRecords()`

**Expected Result**: Array containing the record created in Scenario 2

**Verification**:
```
Record ID: 1
Patient: 0x... (Account 2)
Doctor: 0x... (Account 1)
Diagnosis: "Acute Bronchitis"
Treatment: "Prescribed antibiotics and rest"
Timestamp: [Unix timestamp]
```

### Test Scenario 4: Consent Management

**Objective**: Patient grants pharmacist access

**Account**: Patient (Account 2)

**Contract**: PatientContract

**Steps**:

1. Grant Consent:
   ```solidity
   giveConsentToPharmacist("0x...") // Pharmacist address (Account 3)
   ```

2. Verify Consent:
   ```solidity
   hasConsentedToPharmacist("0x...", "0x...") // Returns true
   ```

### Test Scenario 5: Medication Dispensing

**Objective**: Pharmacist dispenses medication with consent

**Account**: Pharmacist (Account 3)

**Contract**: PharmacistContract

**Function**: `dispenseMedication()`

**Parameters**:
```solidity
_patient: "0x..." // Patient address (Account 2)
_medication: "Amoxicillin 500mg - 10 days"
```

**Expected Result**: Transaction succeeds, event emitted

**Negative Test**: Try dispensing without consent (should fail)

### Test Scenario 6: Appointment Workflow

**Objective**: Complete appointment lifecycle

**Steps**:

1. **Schedule Appointment** (Receptionist - Account 4)
   ```solidity
   scheduleAppointment(
       "0x...", // Patient (Account 2)
       "0x...", // Doctor (Account 1)
       1730000000 // Future timestamp
   )
   ```

2. **Confirm Appointment** (Doctor - Account 1)
   ```solidity
   confirmAppointment(1) // appointmentId
   ```

3. **Cancel Appointment** (Patient - Account 2)
   ```solidity
   cancelAppointment(1) // appointmentId
   ```

### Test Scenario 7: Security Validation

**Objective**: Verify access control enforcement

**Negative Tests**:

1. **Unauthorized Record Access**:
   - Switch to Account 3 (Pharmacist)
   - Try calling `DoctorContract.addMedicalRecord()`
   - **Expected**: Transaction reverts with "Only doctors"

2. **Direct Storage Access**:
   - Try calling `MedicalRecordStorage.addMedicalRecord()` from any non-authorized account
   - **Expected**: Transaction reverts with "Unauthorized access"

3. **Inactive User**:
   - Admin deactivates doctor: `removeUser(Account 1)`
   - Doctor tries to add record
   - **Expected**: Transaction reverts

### Test Scenario 8: Administrative Functions

**Objective**: Test admin controls

**Account**: Admin (Account 0)

**Tests**:

1. **User Deactivation**:
   ```solidity
   removeUser("0x...") // Deactivate Account 1
   ```

2. **Emergency Storage Access**:
   - Admin can directly access storage
   - Call `MedicalRecordStorage.getMedicalRecords()`

3. **Contract Authorization Management**:
   ```solidity
   revokeContractAuthorization("0x...") // Remove DoctorContract
   ```

## Technical Specifications

### Smart Contract Details

| Contract | Size | Functions | Events | Modifiers |
|----------|------|-----------|--------|-----------|
| RBAC | ~8KB | 8 | 3 | 2 |
| MedicalRecordStorage | ~6KB | 6 | 2 | 2 |
| DoctorContract | ~5KB | 4 | 1 | 1 |
| PatientContract | ~5KB | 5 | 2 | 1 |
| PharmacistContract | ~4KB | 3 | 1 | 1 |
| ReceptionistContract | ~7KB | 7 | 4 | 1 |

### Gas Optimization

- Struct packing for efficient storage
- Minimal external calls
- Batch operations where applicable
- Optimized storage patterns

### Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Solidity | ^0.8.18 |
| Framework | OpenZeppelin Contracts | 4.x |
| Development | Remix IDE | Latest |
| Testing | Remix VM / Testnet | - |

### Dependencies

```json
{
  "@openzeppelin/contracts": "^4.9.0",
  "contracts": [
    "access/AccessControl.sol",
    "security/ReentrancyGuard.sol",
    "utils/Counters.sol"
  ]
}
```

### Network Requirements

- **Minimum Gas Limit**: 8,000,000
- **Recommended Networks**: Sepolia, Goerli, or private Hardhat network
- **Storage Costs**: ~2.5M gas for full deployment

## License

This project is released under the MIT License.

---

## Additional Resources

- **OpenZeppelin Documentation**: https://docs.openzeppelin.com/
- **Solidity Documentation**: https://docs.soliditylang.org/
- **Remix IDE**: https://remix.ethereum.org/

## Contributing

Contributions are welcome! Please ensure all security patterns are maintained and new features include comprehensive tests.

## Security Notice

This is an educational project. Before deploying to mainnet:
- Conduct professional security audit
- Implement comprehensive testing suite
- Add emergency pause mechanisms
- Consider gas optimization for production use

---

**Version**: 2.0.0
**Last Updated**: October 2025
