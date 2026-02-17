#!/bin/bash

#=============================================================================
# Meta-RDK-Video Repository Synchronization Script
# 
# This script handles steps 27-40 of the dev_sprint_25_2 sync process:
# - Clone/setup meta-rdk-video repository
# - Update SRCREV values for aamp and player-interface
# - Commit and push SRCREV changes
#
# Usage: ./mrv_sync.sh <start_step> <state_file>
#   start_step: Step number to start from (27-40)
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
    print_error "Meta-rdk-video sync failed at step $1: $2"
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
if [ -z "$aamp_updated" ]; then
    aamp_updated=false
fi
if [ -z "$player_interface_updated" ]; then
    player_interface_updated=false
fi

print_status "Starting Meta-RDK-Video synchronization from step $start_from_step"

# Ensure we're in the parent directory
if [ -d "meta-rdk-video" ]; then
    print_status "Already in parent directory"
else
    print_warning "Not in expected parent directory - looking for meta-rdk-video"
fi

# Step 27: Check if meta-rdk-video directory exists, clone if not
if should_execute_step $current_step; then
    print_step $current_step "Checking if meta-rdk-video directory exists"
    if [ ! -d "meta-rdk-video" ]; then
        print_status "meta-rdk-video directory not found, cloning repository..."
        git clone https://github.com/rdkcentral/meta-rdk-video.git || handle_error $current_step "Failed to clone meta-rdk-video repository"
        print_status "Successfully cloned meta-rdk-video repository"
    else
        print_status "meta-rdk-video directory already exists"
    fi
else
    skip_step $current_step "Checking if meta-rdk-video directory exists"
fi
current_step=$((current_step + 1))

# Step 28: Change to meta-rdk-video directory
if should_execute_step $current_step; then
    print_step $current_step "Changing to meta-rdk-video directory"
    cd ./meta-rdk-video || handle_error $current_step "Failed to change to meta-rdk-video directory"
else
    skip_step $current_step "Changing to meta-rdk-video directory"
    # Still change directory if meta-rdk-video exists for later steps
    if [ -d "meta-rdk-video" ]; then
        cd ./meta-rdk-video 2>/dev/null || true
    fi
fi
current_step=$((current_step + 1))

# Step 29: Checkout develop branch
if should_execute_step $current_step; then
    print_step $current_step "Checking out develop branch"
    git checkout develop || handle_error $current_step "Failed to checkout develop branch"
else
    skip_step $current_step "Checking out develop branch"
fi
current_step=$((current_step + 1))

# Step 30: Pull latest changes for develop
if should_execute_step $current_step; then
    print_step $current_step "Pulling latest changes for develop"
    git pull || handle_error $current_step "Failed to pull latest changes for develop"
else
    skip_step $current_step "Pulling latest changes for develop"
fi
current_step=$((current_step + 1))

# Step 31: Checkout feature/RDKEMW-13297 branch
if should_execute_step $current_step; then
    print_step $current_step "Checking out feature/RDKEMW-13297 branch"
    git checkout feature/RDKEMW-13297 || handle_error $current_step "Failed to checkout feature/RDKEMW-13297 branch"
else
    skip_step $current_step "Checking out feature/RDKEMW-13297 branch"
fi
current_step=$((current_step + 1))

# Step 32: Pull latest changes for feature/RDKEMW-13297
if should_execute_step $current_step; then
    print_step $current_step "Pulling latest changes for feature/RDKEMW-13297"
    git pull || handle_error $current_step "Failed to pull latest changes for feature/RDKEMW-13297"
else
    skip_step $current_step "Pulling latest changes for feature/RDKEMW-13297"
fi
current_step=$((current_step + 1))

# Step 33: Merge develop into feature/RDKEMW-13297
if should_execute_step $current_step; then
    print_step $current_step "Merging develop into feature/RDKEMW-13297"
    git merge develop || handle_error $current_step "Failed to merge develop into feature/RDKEMW-13297"
else
    skip_step $current_step "Merging develop into feature/RDKEMW-13297"
fi
current_step=$((current_step + 1))

# Step 34: Check current SRCREV_aamp in aamp_git.bb
if should_execute_step $current_step; then
    print_step $current_step "Checking current SRCREV_aamp in aamp_git.bb"
    if [ -z "$aamp_final_commit" ]; then
        print_error "aamp_final_commit not set - ensure aamp_sync.sh completed successfully"
        exit 1
    fi
    current_aamp_srcrev=$(cat ./recipes-extended/aamp/aamp_git.bb | grep "SRCREV_aamp = " | cut -d'"' -f2) || handle_error $current_step "Failed to read SRCREV_aamp from aamp_git.bb"
    print_status "Current SRCREV_aamp: $current_aamp_srcrev"
    print_status "Expected SRCREV_aamp: $aamp_final_commit"
    save_state
else
    skip_step $current_step "Checking current SRCREV_aamp in aamp_git.bb"
    # Set default value if skipped
    current_aamp_srcrev="unknown"
fi
current_step=$((current_step + 1))

# Step 35: Update SRCREV_aamp if different
if should_execute_step $current_step; then
    print_step $current_step "Checking if SRCREV_aamp needs update"
    aamp_updated=false
    if [ "$current_aamp_srcrev" != "$aamp_final_commit" ]; then
        print_status "SRCREV_aamp differs from aamp latest commit, updating..."
        sed -i "s/SRCREV_aamp = \"$current_aamp_srcrev\"/SRCREV_aamp = \"$aamp_final_commit\"/" ./recipes-extended/aamp/aamp_git.bb || handle_error $current_step "Failed to update SRCREV_aamp in aamp_git.bb"
        print_status "Updated SRCREV_aamp from $current_aamp_srcrev to $aamp_final_commit"
        aamp_updated=true
        save_state
    else
        print_status "SRCREV_aamp is already up to date, no changes needed"
    fi
else
    skip_step $current_step "Checking if SRCREV_aamp needs update"
    aamp_updated=false
fi
current_step=$((current_step + 1))

# Step 36: Check current SRCREV in player-interface_git.bb
if should_execute_step $current_step; then
    print_step $current_step "Checking current SRCREV in player-interface_git.bb"
    if [ -z "$middleware_final_commit" ]; then
        print_error "middleware_final_commit not set - ensure pi_sync.sh completed successfully"
        exit 1
    fi
    current_player_interface_srcrev=$(cat ./recipes-extended/player-interface/player-interface_git.bb | grep "SRCREV = " | cut -d'"' -f2) || handle_error $current_step "Failed to read SRCREV from player-interface_git.bb"
    print_status "Current SRCREV: $current_player_interface_srcrev"
    print_status "Expected SRCREV: $middleware_final_commit"
    save_state
else
    skip_step $current_step "Checking current SRCREV in player-interface_git.bb"
    # Set default value if skipped
    current_player_interface_srcrev="unknown"
fi
current_step=$((current_step + 1))

# Step 37: Update SRCREV if different
if should_execute_step $current_step; then
    print_step $current_step "Checking if SRCREV needs update"
    player_interface_updated=false
    if [ "$current_player_interface_srcrev" != "$middleware_final_commit" ]; then
        print_status "SRCREV differs from middleware-player-interface latest commit, updating..."
        sed -i "s/SRCREV = \"$current_player_interface_srcrev\"/SRCREV = \"$middleware_final_commit\"/" ./recipes-extended/player-interface/player-interface_git.bb || handle_error $current_step "Failed to update SRCREV in player-interface_git.bb"
        print_status "Updated SRCREV from $current_player_interface_srcrev to $middleware_final_commit"
        player_interface_updated=true
        save_state
    else
        print_status "SRCREV is already up to date, no changes needed"
    fi
else
    skip_step $current_step "Checking if SRCREV needs update"
    player_interface_updated=false
fi
current_step=$((current_step + 1))

# Step 37.5: Get meta-rdk-video final commit ID
print_step "INFO" "Getting meta-rdk-video final commit ID"
meta_rdk_video_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for meta-rdk-video"
print_status "meta-rdk-video final commit ID: $meta_rdk_video_final_commit"
save_state

# Step 38: Commit changes if any updates were made
if should_execute_step $current_step; then
    print_step $current_step "Committing changes if any updates were made"
    if [ "$aamp_updated" = true ] || [ "$player_interface_updated" = true ]; then
        if [ -z "$commit_message" ]; then
            commit_message="dev_sprint_25_2 sync $(date +"%Y-%m-%d") $(date +"%H:%M:%S")"
        fi
        git add --all || handle_error $current_step "Failed to add changes"
        git commit -m "$commit_message" || handle_error $current_step "Failed to commit changes"
        print_status "Changes committed with message: $commit_message"
        
        # Step 39: Push changes to origin
        current_step=$((current_step + 1))
        if should_execute_step $current_step; then
            print_step $current_step "Pushing changes to origin feature/RDKEMW-13297"
            git push origin feature/RDKEMW-13297 || handle_error $current_step "Failed to push changes to origin"
            print_status "Changes pushed to origin feature/RDKEMW-13297"
        else
            skip_step $current_step "Pushing changes to origin feature/RDKEMW-13297"
        fi
        save_state
    else
        print_status "No SRCREV updates needed, skipping commit and push"
        # Still increment for step 39 when no changes
        current_step=$((current_step + 1))
        skip_step $current_step "Pushing changes to origin feature/RDKEMW-13297 (no changes to push)"
    fi
else
    skip_step $current_step "Committing changes if any updates were made"
    current_step=$((current_step + 1))
    skip_step $current_step "Pushing changes to origin feature/RDKEMW-13297"
fi

# Change back to parent directory
cd ../

print_status "Meta-RDK-Video synchronization completed successfully"
print_status "meta-rdk-video final commit ID: $meta_rdk_video_final_commit"
print_status "AAMP SRCREV updated: $aamp_updated"
print_status "Player Interface SRCREV updated: $player_interface_updated"