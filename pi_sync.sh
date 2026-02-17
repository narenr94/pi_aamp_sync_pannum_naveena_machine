#!/bin/bash

#=============================================================================
# Middleware-Player-Interface Repository Synchronization Script
# 
# This script handles steps 13-26 of the dev_sprint_25_2 sync process:
# - Filter patch for middleware components
# - Apply filtered patch to middleware-player-interface repository
# - Commit and push changes
# - Get final commit ID for SRCREV updates
#
# Usage: ./pi_sync.sh <start_step> <state_file>
#   start_step: Step number to start from (13-26)
#   state_file: Path to state file for persistence
#=============================================================================

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <start_step> <state_file>"
    exit 1
fi

start_from_step=$1
STATE_FILE=$2

# Source common functions and variables from main script
# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${GREEN}[STEP $1]${NC} $2"
}

# Function to check if step should be executed
should_execute_step() {
    local step_num=$1
    if [ $step_num -ge $start_from_step ]; then
        return 0  # Execute step
    else
        return 1  # Skip step
    fi
}

# Function to skip a step
skip_step() {
    local step_num=$1
    local step_desc="$2"
    echo -e "${YELLOW}[SKIP $step_num]${NC} $step_desc (skipped)"
}

# Function to handle errors
handle_error() {
    print_error "Middleware sync failed at step $1: $2"
    exit 1
}

# Load state if file exists
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
fi

# Functions for state management
save_state() {
    # Since STATE_FILE is now an absolute path, use it directly
    cat > "$STATE_FILE" << EOF
current_step=$current_step
current_date="$current_date"
current_time="$current_time"
commit_message="$commit_message"
dev_sprint_commit="$dev_sprint_commit"
dev_sprint_short_commit="$dev_sprint_short_commit"
feature_branch_commit="$feature_branch_commit"
feature_branch_short_commit="$feature_branch_short_commit"
patch_filename="$patch_filename"
filtered_patch_filename="$filtered_patch_filename"
aamp_final_commit="$aamp_final_commit"
middleware_final_commit="$middleware_final_commit"
no_new_changes=$no_new_changes
middleware_sections=$middleware_sections
current_aamp_srcrev="$current_aamp_srcrev"
current_player_interface_srcrev="$current_player_interface_srcrev"
aamp_updated=$aamp_updated
player_interface_updated=$player_interface_updated
EOF
}

# Initialize variables if not loaded from state
if [ -z "$current_step" ]; then
    current_step=$start_from_step
fi
# Override current_step if resuming from a specific step
current_step=$start_from_step
if [ -z "$middleware_sections" ]; then
    middleware_sections=0
fi
if [ -z "$no_new_changes" ]; then
    no_new_changes=false
fi

print_status "Starting Middleware-Player-Interface synchronization from step $start_from_step"

# Ensure we're in the parent directory
if [ -d "aamp" ] || [ -d "middleware-player-interface" ]; then
    print_status "Already in parent directory"
else
    print_warning "Not in expected parent directory - looking for repositories"
fi

# Step 13: Filter patch for middleware components
if should_execute_step $current_step; then
    print_step $current_step "Filtering patch for middleware components"
    if [ -z "$patch_filename" ]; then
        # Try to find the patch file automatically
        print_warning "patch_filename not set - attempting to find existing patch file"
        patch_files=(*.patch)
        if [ -e "${patch_files[0]}" ]; then
            patch_filename="${patch_files[0]}"
            print_status "Found patch file: $patch_filename"
            save_state
        else
            print_error "No patch file found and patch_filename not set - ensure aamp_sync.sh completed successfully"
            exit 1
        fi
    fi
    filtered_patch_filename="${patch_filename%.*}_mid.patch"
    filter_output=$(python3 ./filter_middleware_patch.py $patch_filename $filtered_patch_filename) || handle_error $current_step "Failed to filter patch for middleware components"
    print_status "Filtered patch created: $filtered_patch_filename"
    echo "$filter_output"

    # Extract the number of processed middleware diff sections
    middleware_sections=$(echo "$filter_output" | grep "Processed" | grep -o '[0-9]\+' | tail -1)
    print_status "Number of middleware diff sections: $middleware_sections"
    save_state
else
    skip_step $current_step "Filtering patch for middleware components"
    # Set default values for skipped step
    if [ -z "$filtered_patch_filename" ]; then
        filtered_patch_filename="${patch_filename%.*}_mid.patch"
    fi
    if [ -z "$middleware_sections" ]; then
        middleware_sections=0
    fi
fi
current_step=$((current_step + 1))

# Step 14: Remove original patch file to avoid lingering files
if should_execute_step $current_step; then
    print_step $current_step "Removing original patch file"
    rm ./$patch_filename || handle_error $current_step "Failed to remove original patch file"
else
    skip_step $current_step "Removing original patch file"
fi
current_step=$((current_step + 1))

# Step 15: Check if middleware-player-interface directory exists, clone if not
if should_execute_step $current_step; then
    print_step $current_step "Checking if middleware-player-interface directory exists"
    if [ ! -d "middleware-player-interface" ]; then
        print_status "middleware-player-interface directory not found, cloning repository..."
        git clone https://github.com/rdkcentral/middleware-player-interface.git || handle_error $current_step "Failed to clone middleware-player-interface repository"
        print_status "Successfully cloned middleware-player-interface repository"
    else
        print_status "middleware-player-interface directory already exists"
    fi
else
    skip_step $current_step "Checking if middleware-player-interface directory exists"
fi
current_step=$((current_step + 1))

# Step 16: Change to middleware-player-interface directory
if should_execute_step $current_step; then
    print_step $current_step "Changing to middleware-player-interface directory"
    cd ./middleware-player-interface || handle_error $current_step "Failed to change to middleware-player-interface directory"
else
    skip_step $current_step "Changing to middleware-player-interface directory"
    # Still change directory if middleware-player-interface exists for later steps
    if [ -d "middleware-player-interface" ]; then
        cd ./middleware-player-interface 2>/dev/null || true
    fi
fi
current_step=$((current_step + 1))

# Step 18: Checkout feature/RDKEMW-13297 branch
if should_execute_step $current_step; then
    print_step $current_step "Checking out feature/RDKEMW-13297 branch in middleware-player-interface"
    git checkout feature/RDKEMW-13297 || handle_error $current_step "Failed to checkout feature/RDKEMW-13297 branch in middleware-player-interface"
else
    skip_step $current_step "Checking out feature/RDKEMW-13297 branch in middleware-player-interface"
fi
current_step=$((current_step + 1))

# Step 19: Pull latest changes
if should_execute_step $current_step; then
    print_step $current_step "Pulling latest changes for middleware-player-interface feature/RDKEMW-13297"
    git pull || handle_error $current_step "Failed to pull latest changes for middleware-player-interface"
else
    skip_step $current_step "Pulling latest changes for middleware-player-interface feature/RDKEMW-13297"
fi
current_step=$((current_step + 1))

# Check if we have middleware changes to apply
if [ "$no_new_changes" = true ]; then
    print_warning "No new changes in aamp, skipping all middleware patch application steps (19-24)"
    print_status "Proceeding directly to get final commit ID"
    # Skip steps 19-24
    current_step=25
elif [ -z "$middleware_sections" ] || [ "$middleware_sections" -eq 0 ]; then
    print_warning "No middleware diff sections found, skipping patch application steps (19-24)"
    print_status "Proceeding directly to get final commit ID"
    # Skip steps 19-24
    current_step=25
else
    print_status "Found $middleware_sections middleware diff sections, proceeding with patch application"
    
    # Step 19: Move filtered patch file
    if should_execute_step $current_step; then
        print_step $current_step "Moving filtered patch file"
        mv ../$filtered_patch_filename ./ || handle_error $current_step "Failed to move filtered patch file"
    else
        skip_step $current_step "Moving filtered patch file"
    fi
    current_step=$((current_step + 1))
    
    # Step 21: Apply patch
    if should_execute_step $current_step; then
        print_step $current_step "Applying patch to middleware-player-interface"
        git apply ./$filtered_patch_filename || handle_error $current_step "Failed to apply patch to middleware-player-interface"
    else
        skip_step $current_step "Applying patch to middleware-player-interface"
    fi
    current_step=$((current_step + 1))
    
    # Step 21: Remove patch file to avoid pushing it to repository
    if should_execute_step $current_step; then
        print_step $current_step "Removing filtered patch file"
        rm ./$filtered_patch_filename || handle_error $current_step "Failed to remove patch file"
    else
        skip_step $current_step "Removing patch file"
    fi
    current_step=$((current_step + 1))
    
    # Step 22: Add all changes
    if should_execute_step $current_step; then
        print_step $current_step "Adding all changes in middleware-player-interface"
        git add --all || handle_error $current_step "Failed to add changes in middleware-player-interface"
    else
        skip_step $current_step "Adding all changes in middleware-player-interface"
    fi
    current_step=$((current_step + 1))
    
    # Step 23: Commit changes
    if should_execute_step $current_step; then
        print_step $current_step "Committing changes in middleware-player-interface"
        git commit -m "$commit_message" || handle_error $current_step "Failed to commit changes in middleware-player-interface"
    else
        skip_step $current_step "Committing changes in middleware-player-interface"
    fi
    current_step=$((current_step + 1))
    
    # Step 24: Push changes to origin
    if should_execute_step $current_step; then
        print_step $current_step "Pushing changes to origin feature/RDKEMW-13297 in middleware-player-interface"
        git push origin feature/RDKEMW-13297 || handle_error $current_step "Failed to push changes to middleware-player-interface origin"
    else
        skip_step $current_step "Pushing changes to origin feature/RDKEMW-13297 in middleware-player-interface"
    fi
    current_step=$((current_step + 1))
fi

# Step 25: Get final commit ID for middleware-player-interface
if should_execute_step $current_step; then
    print_step $current_step "Getting final commit ID for middleware-player-interface"
    middleware_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for middleware-player-interface"
    if [ -z "$middleware_sections" ] || [ "$middleware_sections" -eq 0 ]; then
        print_status "middleware-player-interface final commit ID (no changes applied): $middleware_final_commit"
    else
        print_status "middleware-player-interface final commit ID (changes applied): $middleware_final_commit"
    fi
    save_state
else
    skip_step $current_step "Getting final commit ID for middleware-player-interface"
    # Try to get commit ID if in middleware directory
    if [ -d ".git" ]; then
        middleware_final_commit=$(git log -1 --format="%H" 2>/dev/null) || middleware_final_commit="unknown"
    fi
fi

# Change back to parent directory for next phase
cd ../

print_status "Middleware-Player-Interface synchronization completed successfully"
print_status "Final middleware commit ID: $middleware_final_commit"
print_status "Middleware sections processed: $middleware_sections"