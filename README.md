# PolicyEdu

PolicyEdu is a decentralized voting system smart contract designed for democratic decision-making on educational policies. Built on the Stacks blockchain using Clarity, it enables transparent, weighted voting with role-based access control.

## Features

- **Democratic Proposal Creation**: Authorized voters can create educational policy proposals with titles, descriptions, and categories
- **Weighted Voting System**: Voters have different voting weights based on their roles and expertise
- **Role-Based Access Control**: Admins can register voters with specific roles (teachers, administrators, board members)
- **Time-Limited Voting**: Proposals have defined voting periods (approximately 1 week)
- **Transparent Results**: All votes and results are publicly verifiable on the blockchain
- **Proposal Execution**: Admins can mark passed proposals as executed
- **Contract Management**: Ability to pause/unpause the contract for maintenance

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Voting Period**: 1008 blocks (~1 week at 10-minute block times)
- **Minimum Voting Weight**: 1

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) (for development dependencies)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd PolicyEdu
```

2. Navigate to the contract directory:
```bash
cd PolicyEdu_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Initialize the Contract

```clarity
;; Initialize contract (only contract owner)
(contract-call? .PolicyEdu initialize)
```

### Register Voters

```clarity
;; Register a teacher with voting weight 3
(contract-call? .PolicyEdu register-voter 'SP1EXAMPLE... u3 "teacher")

;; Register an administrator with voting weight 5
(contract-call? .PolicyEdu register-voter 'SP2EXAMPLE... u5 "administrator")
```

### Create a Proposal

```clarity
;; Create a new educational policy proposal
(contract-call? .PolicyEdu create-proposal
  "Implement 1:1 Device Program"
  "Proposal to provide each student with a personal computing device for enhanced learning opportunities and digital literacy development."
  "technology")
```

### Vote on Proposals

```clarity
;; Vote in favor of proposal #1
(contract-call? .PolicyEdu vote u1 true)

;; Vote against proposal #1
(contract-call? .PolicyEdu vote u1 false)
```

### Check Proposal Results

```clarity
;; Get detailed results for proposal #1
(contract-call? .PolicyEdu get-proposal-results u1)
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions

- **`initialize()`**: Initialize the contract with the deployer as admin (weight: 10)
- **`register-voter(voter, weight, role)`**: Register a new voter with specified weight and role
- **`deactivate-voter(voter)`**: Deactivate a voter's ability to participate
- **`set-contract-active(active)`**: Pause or unpause the contract

#### Proposal Management

- **`create-proposal(title, description, category)`**: Create a new policy proposal
- **`vote(proposal-id, vote-for)`**: Cast a weighted vote on a proposal
- **`execute-proposal(proposal-id)`**: Mark a passed proposal as executed (admin only)

### Read-Only Functions

#### Data Retrieval

- **`get-proposal(proposal-id)`**: Get complete proposal details
- **`get-voter-info(voter)`**: Get voter registration information
- **`get-user-vote(proposal-id, voter)`**: Get a specific user's vote on a proposal
- **`get-proposal-counter()`**: Get the current number of proposals created
- **`get-contract-active()`**: Check if the contract is currently active

#### Status Checks

- **`is-admin(address)`**: Check if an address has admin privileges
- **`is-authorized-voter(address)`**: Check if an address can vote
- **`get-proposal-results(proposal-id)`**: Get comprehensive proposal results
- **`is-voting-active(proposal-id)`**: Check if voting is currently open for a proposal

### Error Codes

- **100 (ERR_UNAUTHORIZED)**: Caller lacks required permissions
- **101 (ERR_INVALID_PROPOSAL)**: Proposal data is invalid or operation not allowed
- **102 (ERR_ALREADY_VOTED)**: User has already voted on this proposal
- **103 (ERR_VOTING_CLOSED)**: Voting period has ended
- **104 (ERR_PROPOSAL_NOT_FOUND)**: Proposal ID does not exist
- **105 (ERR_INSUFFICIENT_WEIGHT)**: Voting weight below minimum requirement

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Initialize the contract:
```clarity
(contract-call? .PolicyEdu initialize)
```

3. Register initial voters and test functionality

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Review and configure `settings/Mainnet.toml`
2. Thoroughly test on testnet first
3. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Access Control

- **Admin-Only Functions**: Contract initialization, voter registration, voter deactivation, proposal execution, and contract pause/unpause
- **Voter-Only Functions**: Proposal creation and voting
- **Role Verification**: All functions verify caller permissions before execution

### Voting Integrity

- **One Vote Per Proposal**: Users cannot vote multiple times on the same proposal
- **Time-Bounded Voting**: Proposals have fixed voting periods to prevent manipulation
- **Immutable Votes**: Once cast, votes cannot be changed or withdrawn
- **Weighted Democracy**: Voting power reflects expertise and responsibility levels

### Data Protection

- **Transparent Operations**: All votes and proposals are publicly visible
- **Immutable Records**: Blockchain storage ensures vote tampering is impossible
- **Authorized Participation**: Only registered voters can participate

### Best Practices

1. **Regular Audits**: Periodically review voter registrations and remove inactive participants
2. **Proposal Categories**: Use consistent categorization for better organization
3. **Execution Tracking**: Mark proposals as executed to maintain clear status
4. **Weight Distribution**: Assign voting weights thoughtfully based on roles and expertise
5. **Emergency Procedures**: Use contract pause functionality only when necessary

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test thoroughly using Clarinet
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.