# FactoryPulse Smart Contract

## Overview

FactoryPulse is a blockchain-based IoT integration solution designed for manufacturing equipment management. This smart contract enables secure tracking of equipment status, maintenance records, and operational metrics on the Stacks blockchain.

## Features

- **Equipment Registry**: Register and manage manufacturing equipment with ownership tracking
- **Status Management**: Monitor and update equipment operational status (idle, running, maintenance, error)
- **Maintenance Tracking**: Record and retrieve maintenance history with timestamps and detailed descriptions
- **Metrics Reporting**: Store and access real-time equipment performance metrics including:
  - Temperature
  - Vibration levels
  - Power consumption
  - Operational hours
- **Access Control**: Granular permission system with owner, admin, and authorized reporter roles

## Technical Details

- Built for Stacks blockchain using Clarity smart contract language
- Compatible with Clarity 3.0
- Uses `stacks-block-height` for timestamp tracking
- Implements comprehensive validation for all data inputs
- Includes robust error handling with descriptive error codes

## Functions

### Administrative Functions

- `register-equipment`: Add new equipment to the registry
- `authorize-reporter`: Grant permission to report equipment metrics
- `remove-reporter`: Revoke reporting permissions
- `set-admin`: Assign a new admin address

### Operational Functions

- `update-equipment-status`: Change equipment operational status
- `add-maintenance-record`: Record maintenance activities
- `report-equipment-metrics`: Submit performance metrics

### Read-Only Functions

- `get-equipment-details`: Retrieve equipment information
- `get-maintenance-record`: Access maintenance history
- `get-latest-metrics`: View equipment performance data
- `is-authorized`: Check if an address has reporting permissions

## Error Codes

| Code | Description |
|------|-------------|
| u100 | Equipment ID already exists |
| u101 | Equipment not found |
| u400 | Invalid status value |
| u401 | Temperature out of valid range |
| u402 | Invalid metrics values |
| u403 | Unauthorized access |
| u405 | Invalid input parameters |

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.15.1 or later
- [Stacks CLI](https://github.com/blockstack/stacks.js) (optional for deployment)

### Setup

1. Clone the repository
2. Install dependencies
3. Run tests with Clarinet

```bash
$ git clone https://github.com/yourusername/factory-pulse.git
$ cd factory-pulse
$ clarinet check
$ clarinet test
```

## Deployment

1. Configure your deployment settings in `Clarinet.toml`
2. Deploy using Clarinet:

```bash
$ clarinet deploy --network testnet
```

## Security Considerations

- All critical functions include authorization checks
- Input validation prevents data corruption
- Equipment ownership is strictly enforced

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. Meaning full contributions will be merged into the main branch.