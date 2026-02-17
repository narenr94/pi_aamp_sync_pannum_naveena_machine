# AAMP Repository Synchronization Scripts

A collection of shell scripts for synchronizing changes from the `dev_sprint_25_2` branch to the `feature/RDKEMW-13297` branch across multiple RDK Central repositories.

## Overview

This project provides automated synchronization tools for managing code changes across three interconnected RDK repositories, with additional AAMP source configuration updates:

- **aamp** - Advanced Adaptive Media Player repository
- **middleware-player-interface** - Middleware components for player interface  
- **meta-rdk-video** - RDK video meta layer with SRCREV management
- **aamp source updates** - AAMP configuration synchronization

The synchronization process ensures consistent updates across all repositories while maintaining proper dependency relationships and build configurations.

## Architecture

The sync process is divided into 48 sequential steps, organized across specialized scripts:

```
Main Orchestrator
├── pi_aamp_sync_pannum_naveena_machine.sh (Steps 1-48)
│
├── AAMP Repository Sync
│   └── aamp_sync.sh (Steps 1-12)
│
├── Middleware Player Interface Sync  
│   └── pi_sync.sh (Steps 13-26)
│
├── Meta RDK Video Sync
│   └── mrv_sync.sh (Steps 27-40)
│
├── AAMP Source Update Sync
│   └── sim_source_update.sh (Steps 41-48)
│
└── Utilities
    └── filter_middleware_patch.py
```

## Scripts Description

### Main Orchestrator Script
- **`pi_aamp_sync_pannum_naveena_machine.sh`**
  - Primary entry point for the entire sync process
  - Handles preprocessing, state management, and script orchestration
  - Manages execution flow across all 48 steps
  - Provides resumability from any step number

### Repository-Specific Scripts

#### AAMP Repository (Steps 1-12)
- **`aamp_sync.sh`**
  - Clones/checks aamp repository
  - Merges `dev_sprint_25_2` into `feature/RDKEMW-13297`
  - Generates patch files for middleware filtering
  - Pushes changes and captures commit IDs

#### Middleware Player Interface (Steps 13-26)
- **`pi_sync.sh`**
  - Filters patches for middleware components
  - Applies filtered patches to middleware-player-interface repository
  - Commits and pushes changes
  - Captures final commit ID for SRCREV updates

#### Meta RDK Video (Steps 27-40)
- **`mrv_sync.sh`**
  - Clones/sets up meta-rdk-video repository
  - Updates SRCREV values for aamp and player-interface
  - Commits and pushes SRCREV changes

#### AAMP Source Update (Steps 41-48)
- **`sim_source_update.sh`**
  - Updates OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID in aamp
  - Synchronizes player-interface commit references in aamp build options
  - Commits and pushes configuration changes

### Utility Scripts
- **`filter_middleware_patch.py`**
  - Python script for filtering patch files
  - Extracts middleware-related changes only
  - Adjusts file paths for proper application

## Usage

### Basic Usage
```bash
# Run complete sync process from step 1
./pi_aamp_sync_pannum_naveena_machine.sh

# Resume from a specific step (e.g., step 15)
./pi_aamp_sync_pannum_naveena_machine.sh 15
```

### Individual Script Usage
```bash
# Run AAMP sync only (steps 1-12)
./aamp_sync.sh <start_step> <state_file>

# Run PI sync only (steps 13-26)  
./pi_sync.sh <start_step> <state_file>

# Run MRV sync only (steps 27-40)
./mrv_sync.sh <start_step> <state_file>

# Run AAMP source update only (steps 41-48)
./sim_source_update.sh <start_step> <state_file>
```

### Help
```bash
./pi_aamp_sync_pannum_naveena_machine.sh --help
```

## Features

### State Management
- Persistent state tracking across script executions
- Resume capability from any failed step
- State file management for process continuity

### Error Handling
- Comprehensive error checking and reporting
- Colored output for better visibility (Green/Yellow/Red)
- Graceful failure handling with detailed error messages

### Validation
- Step number validation (1-48 range)
- Repository state verification
- Branch existence and accessibility checks

### Flexibility
- Modular design allows running individual sync phases
- Configurable starting points for troubleshooting
- Support for different execution environments

## Step-by-Step Process

### Phase 1: AAMP Repository (Steps 1-12)
1. Repository setup and validation
2. Branch management and merging
3. Conflict resolution (if needed)
4. Patch generation for middleware components
5. Change validation and testing
6. Commit and push operations

### Phase 2: Middleware Player Interface (Steps 13-26)
7. Patch filtering for middleware components
8. Repository preparation
9. Patch application and validation
10. Build verification
11. Commit and push operations
12. Commit ID extraction

### Phase 3: Meta RDK Video (Steps 27-40)
13. Meta repository setup
14. SRCREV value updates
15. Build configuration validation
16. Final commit and push operations

### Phase 4: AAMP Source Update (Steps 41-48)
17. AAMP configuration repository access
18. OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID synchronization
19. Build option validation and updates
20. Configuration commit and push operations

## Prerequisites

- Bash shell environment
- Git access to RDK Central repositories
- Python 3.x for patch filtering utility
- Appropriate repository access permissions
- Network connectivity to RDK Central

## Error Recovery

The scripts support resuming from any step in case of failures:

1. Check the last successful step from console output
2. Fix any environmental or permission issues
3. Resume using: `./pi_aamp_sync_pannum_naveena_machine.sh <step_number>`

## State Files

The synchronization process uses state files to track progress:
- Enables resumability after interruptions
- Stores commit IDs and repository states
- Maintains process context across script executions

## Logging and Output

- Color-coded status messages (INFO, WARNING, ERROR)
- Step-by-step progress tracking
- Detailed error reporting with context
- Final summary of sync results


## Troubleshooting

Common issues and solutions:
- **Permission denied**: Ensure proper Git repository access
- **Branch not found**: Verify branch names and repository state
- **Patch application failed**: Check for conflicting changes
- **State file issues**: Remove state file and restart if corrupted

