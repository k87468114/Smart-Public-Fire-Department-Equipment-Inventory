# Smart Public Fire Department Equipment Inventory

A comprehensive blockchain-based system for managing fire department equipment inventory, maintenance, and assignments.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of fire department equipment:

### 1. Gear Tracking Contract (`gear-tracking.clar`)
- Manages firefighter protective equipment assignments
- Tracks equipment ownership and status
- Handles equipment check-in/check-out processes
- Maintains equipment condition records

### 2. Maintenance Scheduling Contract (`maintenance-scheduling.clar`)
- Coordinates equipment testing and repair schedules
- Tracks maintenance history and compliance
- Manages maintenance personnel assignments
- Schedules preventive maintenance tasks

### 3. Replacement Planning Contract (`replacement-planning.clar`)
- Schedules aging equipment upgrades
- Tracks equipment lifecycle and depreciation
- Manages replacement budgets and priorities
- Forecasts future equipment needs

### 4. Training Equipment Contract (`training-equipment.clar`)
- Manages practice gear and simulation equipment
- Tracks training equipment availability
- Schedules training sessions and equipment usage
- Maintains training equipment condition

### 5. Emergency Supply Contract (`emergency-supply.clar`)
- Maintains adequate backup equipment inventory
- Tracks emergency supply levels and thresholds
- Manages emergency equipment deployment
- Handles supply replenishment and alerts

## Key Features

- **Equipment Tracking**: Complete lifecycle management from acquisition to disposal
- **Maintenance Management**: Automated scheduling and compliance tracking
- **Assignment Control**: Secure equipment assignment and accountability
- **Inventory Monitoring**: Real-time inventory levels and alerts
- **Compliance Reporting**: Automated compliance and safety reporting

## Data Structures

### Equipment Types
- Protective gear (helmets, coats, pants, boots, gloves)
- Breathing apparatus (SCBA, masks, tanks)
- Tools (axes, hoses, ladders, pumps)
- Vehicles (trucks, ambulances, boats)
- Communication equipment (radios, pagers)

### Status Types
- Available
- Assigned
- In Maintenance
- Out of Service
- Training Use
- Emergency Reserve

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite

## Usage

Deploy contracts in the following order:
1. gear-tracking
2. maintenance-scheduling
3. replacement-planning
4. training-equipment
5. emergency-supply

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing

## Security Features

- Role-based access control
- Equipment ownership verification
- Maintenance compliance enforcement
- Emergency override capabilities
- Audit trail for all transactions
