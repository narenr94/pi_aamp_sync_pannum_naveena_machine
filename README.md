# AAMP to Middleware Player Interface Sync Script

## Overview

This is a simplified sync script that synchronizes changes from the AAMP `dev_sprint_25_2` branch to the `middleware-player-interface` `feature/RDKEMW-13297` branch.

## Process Flow

The script follows these 27 steps:

### Repository Setup (Steps 1-6)
1. Check if `middleware-player-interface` folder exists
2. Clone `middleware-player-interface` repository if needed
3. Switch to middleware-player-interface directory and checkout `feature/RDKEMW-13297`
4. Pull latest changes from the feature branch
5. Read last synced AAMP commit from `aamp_sync_cid.txt`
6. Return to parent directory

### AAMP Repository Setup (Steps 7-14)
7. Check if `aamp` folder exists
8. Clone `aamp` repository if needed
9. Switch to aamp directory and checkout `dev_sprint_25_2`
10. Pull latest changes from dev_sprint_25_2
11. Get latest AAMP commit ID
12. Compare commits to determine if sync is needed
13. Generate patch file between last synced and latest commits
14. Return to parent directory

### Patch Processing (Steps 15-20)
15. Filter patch for middleware components using `filter_middleware_patch.py`
16. Analyze filtered patch to determine if middleware changes exist
17. Remove original patch file
18. Move filtered patch to middleware-player-interface directory
19. Apply filtered patch (if middleware changes exist)
20. Remove filtered patch file

### Commit and Sync (Steps 21-27)
21. Update `aamp_sync_cid.txt` with latest AAMP commit
22. Add all changes to git
23. Commit changes with timestamp
24. Push changes to `feature/RDKEMW-13297`
25. Get final middleware commit ID
26. Return to sync directory
27. Generate final sync report

## Usage

### Basic Usage
```bash
./aamp_middleware_sync.sh
```

### Resume from Specific Step
```bash
./aamp_middleware_sync.sh 15    # Resume from step 15
```

### Help
```bash
./aamp_middleware_sync.sh --help
```

## Key Features

### State Management
- Automatically saves progress to `aamp_middleware_sync.temp`
- Can resume from any step if script fails
- State file is automatically cleaned up on successful completion

### Error Handling
- Comprehensive error checking at each step
- Clear error messages with step numbers
- State preservation for debugging and resumption

### Smart Sync Detection
- Only processes changes if new commits are available
- Exits early if repositories are already synchronized
- Tracks sync status via `aamp_sync_cid.txt`

### Patch Filtering
- Uses `filter_middleware_patch.py` to extract middleware-specific changes
- Only applies patches if middleware changes are detected
- Automatically handles empty patches

## Files

- `aamp_middleware_sync.sh` - Main sync script
- `filter_middleware_patch.py` - Middleware patch filtering utility
- `aamp_middleware_sync.temp` - State file (created/removed automatically)

## Requirements

- Git repositories must be accessible
- Python 3 for patch filtering
- Write access to both repositories
- Network connectivity for git operations

## Repository Structure

The script expects/creates this structure:
```
sync/new/
├── aamp_middleware_sync.sh
├── filter_middleware_patch.py
├── aamp/                           (cloned automatically)
└── middleware-player-interface/    (cloned automatically)
    └── aamp_sync_cid.txt          (tracks last synced commit)
```

## Example Output

```
[STEP 1] Check if middleware-player-interface folder exists
[INFO] middleware-player-interface folder found
[STEP 2] Clone middleware-player-interface repository if needed
[INFO] middleware-player-interface repository already exists, skipping clone
...
[STEP 12] Compare last synced commit with latest commit
[INFO] New changes detected - sync required
[INFO] Last synced: 77af12f799162638fbf14e96f5396def105cb92d
[INFO] Latest:      a1b2c3d4e5f6789012345678901234567890abcd
...
[STEP 16] Analyze filtered patch for middleware changes
[INFO] Middleware changes found: 3 diff sections
[INFO] Middleware patch application required: true
...
============================================
SUCCESS: AAMP to Middleware sync completed!
============================================
```

## Error Recovery

If the script fails:
1. Note the step number from the error message
2. Fix the underlying issue (network, permissions, etc.)
3. Resume using: `./aamp_middleware_sync.sh <step_number>`

Example:
```bash
# If script failed at step 15
./aamp_middleware_sync.sh 15
```

## Differences from Original Multi-Script Approach

This simplified approach:
- Combines all operations into a single script
- Focuses only on AAMP → middleware-player-interface sync
- Removes meta-rdk-video and complex multi-repository coordination
- Provides the same error handling and state management
- Uses the same patch filtering logic