# SOAT Conecta Lawyer Registry Data Model

A comprehensive data model for managing lawyer registry information in the SOAT Conecta system.

## Overview

This repository contains JSON Schema definitions and example data for the SOAT Conecta Lawyer Registry system. The data model provides a structured approach to storing and managing information about lawyers, law firms, specializations, certifications, and addresses.

## Data Model Entities

### 1. Lawyer (`schemas/lawyer.schema.json`)

The core entity representing a lawyer in the registry.

**Key Attributes:**
- `id`: Unique identifier (UUID v4)
- `firstName`, `lastName`: Lawyer's name
- `registrationNumber`: Official bar association registration number
- `email`: Primary email address
- `phone`: Primary phone number
- `status`: Current status (active, inactive, suspended, retired)
- `licenseDate`: Date when the lawyer was licensed
- `specializations`: Array of legal specializations
- `certifications`: Array of professional certifications
- `lawFirm`: Associated law firm
- `address`: Primary address
- `createdAt`, `updatedAt`: Timestamps

### 2. Law Firm (`schemas/lawfirm.schema.json`)

Represents a law firm or legal organization.

**Key Attributes:**
- `id`: Unique identifier (UUID v4)
- `name`: Law firm name
- `registrationNumber`: Business registration number
- `email`, `phone`, `website`: Contact information
- `address`: Primary address
- `foundedDate`: Date when the law firm was founded
- `size`: Firm size (solo, small, medium, large, enterprise)
- `createdAt`, `updatedAt`: Timestamps

### 3. Specialization (`schemas/specialization.schema.json`)

Represents a legal specialization or practice area.

**Key Attributes:**
- `id`: Unique identifier
- `name`: Specialization name
- `category`: Category of law (criminal, civil, corporate, family, labor, tax, intellectual_property, real_estate, immigration, environmental, administrative, constitutional, international)
- `yearsOfExperience`: Years of experience in this specialization
- `certifiedDate`: Date when certified in this specialization

### 4. Certification (`schemas/certification.schema.json`)

Represents a professional certification or credential.

**Key Attributes:**
- `id`: Unique identifier
- `name`: Certification name
- `issuingOrganization`: Organization that issued the certification
- `certificationNumber`: Certification number or ID
- `issueDate`: Date when the certification was issued
- `expiryDate`: Date when the certification expires
- `status`: Current status (active, expired, revoked, suspended)

### 5. Address (`schemas/address.schema.json`)

Represents a physical address.

**Key Attributes:**
- `street`: Street address
- `streetNumber`: Street number
- `apartment`: Apartment, suite, or unit number
- `city`: City name
- `state`: State or province
- `postalCode`: Postal or ZIP code
- `country`: Country name or code
- `coordinates`: Geographic coordinates (latitude, longitude)

## Directory Structure

```
├── schemas/              # JSON Schema definitions
│   ├── lawyer.schema.json
│   ├── lawfirm.schema.json
│   ├── specialization.schema.json
│   ├── certification.schema.json
│   └── address.schema.json
├── examples/             # Example data files
│   ├── lawyer-example.json
│   └── lawfirm-example.json
└── README.md            # This file
```

## Usage

### Validating Data

Use a JSON Schema validator to validate your data against the schemas:

```bash
# Example using ajv-cli
npm install -g ajv-cli
ajv validate -s schemas/lawyer.schema.json -d examples/lawyer-example.json
```

### Integration

These schemas can be used to:
- Generate database schemas
- Validate API requests and responses
- Generate TypeScript/Java/Python types
- Document API contracts
- Generate forms and validation rules

## Example Data

See the `examples/` directory for complete example data files demonstrating the data model usage.

### Lawyer Example

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "firstName": "Maria",
  "lastName": "Silva",
  "registrationNumber": "OAB123456",
  "email": "maria.silva@lawfirm.com",
  "status": "active",
  "specializations": [...],
  "certifications": [...],
  "lawFirm": {...},
  "address": {...}
}
```

## Validation Rules

- **UUIDs**: All entity IDs follow UUID v4 format
- **Registration Numbers**: Must be 6-20 alphanumeric characters
- **Email**: Must be valid email format
- **Phone**: Must follow E.164 international format
- **Dates**: ISO 8601 date format (YYYY-MM-DD)
- **Timestamps**: ISO 8601 date-time format with timezone

## Status Values

### Lawyer Status
- `active`: Currently practicing
- `inactive`: Not currently practicing
- `suspended`: Temporarily suspended
- `retired`: Retired from practice

### Certification Status
- `active`: Currently valid
- `expired`: Past expiry date
- `revoked`: Certification revoked
- `suspended`: Temporarily suspended

## License

Copyright © 2026 SOAT Conecta