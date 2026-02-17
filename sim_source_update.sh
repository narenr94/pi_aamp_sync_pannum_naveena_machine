#!/bin/bash

#=============================================================================
# AAMP Source Update Script for Player-Interface Option
# 
# This script handles steps 41-48 of the sync process:
# - Updates OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID in aamp
# - Commits and pushes changes if needed
#
# Usage: ./sim_source_update.sh <start_step> <state_file>
#   start_step: Step number to start from (41-48)
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
    print_error "AAMP source update failed at step $1: $2"
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
meta_rdk_video_final_commit="$meta_rdk_video_final_commit"
sim_source_final_commit="$sim_source_final_commit"
no_new_changes=$no_new_changes
middleware_sections=$middleware_sections
current_aamp_srcrev="$current_aamp_srcrev"
current_player_interface_srcrev="$current_player_interface_srcrev"
current_middleware_option_commit_id="$current_middleware_option_commit_id"
aamp_updated=$aamp_updated
player_interface_updated=$player_interface_updated
middleware_option_updated=$middleware_option_updated
EOF
}

# Initialize variables if not loaded from state
if [ -z "$current_step" ]; then
    current_step=41
fi

# Ensure we're in the parent directory
print_step "INFO" "Ensuring we're in the correct directory for aamp operations"
current_sync_dir="$(pwd)"
print_status "Current directory: $current_sync_dir"

# Check if aamp directory exists in current directory or parent directory
if [ -d "aamp" ]; then
    print_status "Found aamp directory in current location"
    aamp_parent_dir="$(pwd)"
elif [ -d "../aamp" ]; then
    print_status "Found aamp directory in parent location"
    cd .. || handle_error $current_step "Failed to change to parent directory"
    aamp_parent_dir="$(pwd)" 
    print_status "Changed to parent directory: $aamp_parent_dir"
else
    handle_error $current_step "aamp directory not found in current or parent directory"
fi

# Step 41: cd into "aamp" directory
if should_execute_step $current_step; then
    print_step $current_step "Changing to aamp directory"
    if [ ! -d "aamp" ]; then
        handle_error $current_step "aamp directory not found in parent directory"
    fi
    cd aamp || handle_error $current_step "Failed to change to aamp directory"
    print_status "Changed to aamp directory: $(pwd)"
    save_state
else
    skip_step $current_step "Changing to aamp directory"
fi
current_step=$((current_step + 1))

# Step 42: git checkout feature/RDKEMW-13297
if should_execute_step $current_step; then
    print_step $current_step "Checking out feature/RDKEMW-13297 branch"
    
    # Ensure we're in the aamp directory (in case step 41 was skipped)
    current_dir=$(basename "$(pwd)")
    if [ "$current_dir" != "aamp" ]; then
        if [ ! -d "aamp" ]; then
            handle_error $current_step "aamp directory not found in parent directory"
        fi
        cd aamp || handle_error $current_step "Failed to change to aamp directory"
    fi
    
    git checkout feature/RDKEMW-13297 || handle_error $current_step "Failed to checkout feature/RDKEMW-13297 branch"
    print_status "Checked out feature/RDKEMW-13297 branch"
    save_state
else
    skip_step $current_step "Checking out feature/RDKEMW-13297 branch"
fi
current_step=$((current_step + 1))

# Step 43: git pull
if should_execute_step $current_step; then
    print_step $current_step "Pulling latest changes from remote"
    
    # Ensure we're in the aamp directory (in case steps 41-42 were skipped)
    current_dir=$(basename "$(pwd)")
    if [ "$current_dir" != "aamp" ]; then
        if [ ! -d "aamp" ]; then
            handle_error $current_step "aamp directory not found in parent directory"
        fi
        cd aamp || handle_error $current_step "Failed to change to aamp directory"
    fi
    
    git pull origin feature/RDKEMW-13297 || handle_error $current_step "Failed to pull latest changes"
    print_status "Pulled latest changes from feature/RDKEMW-13297"
    save_state
else
    skip_step $current_step "Pulling latest changes from remote"
fi
current_step=$((current_step + 1))

# Step 44: Check current default commit id for player-interface in aamp
if should_execute_step $current_step; then
    print_step $current_step "Checking current OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID in aamp"
    if [ -z "$middleware_final_commit" ]; then
        print_error "middleware_final_commit not set - ensure previous sync phases completed successfully"
        exit 1
    fi
    
    # Ensure we're in the aamp directory (in case we skipped step 41)
    current_dir=$(basename "$(pwd)")
    if [ "$current_dir" != "aamp" ]; then
        # We're not in aamp directory, need to navigate there
        cd .. || handle_error $current_step "Failed to change to parent directory"
        if [ ! -d "aamp" ]; then
            handle_error $current_step "aamp directory not found in parent directory"
        fi
        cd aamp || handle_error $current_step "Failed to change to aamp directory"
    fi
    
    # Check if scripts/install_options.sh exists
    if [ ! -f "scripts/install_options.sh" ]; then
        handle_error $current_step "scripts/install_options.sh file not found"
    fi
    
    # Extract current middleware option commit ID
    current_middleware_option_commit_id=$(sed -n '10,40p' scripts/install_options.sh | grep "OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID" | cut -d'"' -f2) || handle_error $current_step "Failed to read OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID from scripts/install_options.sh"
    
    if [ -z "$current_middleware_option_commit_id" ]; then
        handle_error $current_step "OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID not found in scripts/install_options.sh"
    fi
    
    print_status "Current OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID: $current_middleware_option_commit_id"
    print_status "Expected OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID: $middleware_final_commit"
    save_state
else
    skip_step $current_step "Checking current OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID in aamp"
    # Set default value if skipped
    current_middleware_option_commit_id="unknown"
fi
current_step=$((current_step + 1))

# Step 45: Update current default commit id for player-interface in aamp if different
if should_execute_step $current_step; then
    print_step $current_step "Checking if OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID needs update"
    middleware_option_updated=false
    
    # Ensure we're in the aamp directory (in case step 44 was skipped)
    current_dir=$(basename "$(pwd)")
    if [ "$current_dir" != "aamp" ]; then
        # We're not in aamp directory, need to navigate there
        cd .. || handle_error $current_step "Failed to change to parent directory"
        if [ ! -d "aamp" ]; then
            handle_error $current_step "aamp directory not found in parent directory"
        fi
        cd aamp || handle_error $current_step "Failed to change to aamp directory"
    fi
    
    if [ "$current_middleware_option_commit_id" != "$middleware_final_commit" ]; then
        print_status "OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID differs from middleware latest commit, updating..."
        
        # Update the commit ID using sed
        sed -i "s/OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID=\"$current_middleware_option_commit_id\"/OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID=\"$middleware_final_commit\"/" scripts/install_options.sh || handle_error $current_step "Failed to update OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID in scripts/install_options.sh"
        
        print_status "Updated OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID from $current_middleware_option_commit_id to $middleware_final_commit"
        middleware_option_updated=true
        save_state
    else
        print_status "OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID is already up to date, no changes needed"
        print_status "Skipping remaining steps as no change required"
        
        # Get final commit ID even if no changes were made
        sim_source_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for aamp"
        print_status "aamp final commit ID (no changes): $sim_source_final_commit"
        save_state
        
        # Set remaining steps as completed by setting current_step appropriately
        current_step=49  # This will skip steps 46-48
    fi
else
    skip_step $current_step "Checking if OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID needs update"
    middleware_option_updated=false
fi
current_step=$((current_step + 1))

# Step 46: git add --all (only if changes were made)
if should_execute_step $current_step && [ "$middleware_option_updated" = true ]; then
    print_step $current_step "Adding all changes to git"
    git add --all || handle_error $current_step "Failed to add changes to git"
    print_status "Added all changes to git staging area"
    save_state
else
    if [ "$middleware_option_updated" = true ]; then
        skip_step $current_step "Adding all changes to git"
    else
        skip_step $current_step "Adding all changes to git (no changes made)"
    fi
fi
current_step=$((current_step + 1))

# Step 47: git commit (only if changes were made)
if should_execute_step $current_step && [ "$middleware_option_updated" = true ]; then
    print_step $current_step "Committing changes"
    git commit -m "sync OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID" || handle_error $current_step "Failed to commit changes"
    print_status "Committed changes with message: sync OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID"
    
    # Get final commit ID after changes
    sim_source_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for aamp"
    print_status "aamp final commit ID (after changes): $sim_source_final_commit"
    save_state
else
    if [ "$middleware_option_updated" = true ]; then
        skip_step $current_step "Committing changes"
    else
        skip_step $current_step "Committing changes (no changes made)"
    fi
fi
current_step=$((current_step + 1))

# Step 48: git push (only if changes were made)
if should_execute_step $current_step && [ "$middleware_option_updated" = true ]; then
    print_step $current_step "Pushing changes to remote"
    git push origin feature/RDKEMW-13297 || handle_error $current_step "Failed to push changes to remote"
    print_status "Pushed changes to feature/RDKEMW-13297 branch"
    save_state
else
    if [ "$middleware_option_updated" = true ]; then
        skip_step $current_step "Pushing changes to remote"
    else
        skip_step $current_step "Pushing changes to remote (no changes made)"
    fi
fi

print_status "AAMP source update completed successfully"
print_status "Middleware option updated: $middleware_option_updated"
if [ -n "$sim_source_final_commit" ]; then
    print_status "Final aamp commit ID: $sim_source_final_commit"
fi
