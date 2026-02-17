#!/bin/bash

#=============================================================================
# AAMP Repository Synchronization Script
# 
# This script handles steps 1-12 of the dev_sprint_25_2 sync process:
# - Clone/check aamp repository
# - Merge dev_sprint_25_2 into feature/RDKEMW-13297
# - Generate patch file for middleware filtering
# - Push changes and get final commit ID
#
# Usage: ./aamp_sync.sh <start_step> <state_file>
#   start_step: Step number to start from (1-12)
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
    print_error "AAMP sync failed at step $1: $2"
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
if [ -z "$current_date" ]; then
    current_date=$(date +"%Y-%m-%d")
fi
if [ -z "$current_time" ]; then
    current_time=$(date +"%H:%M:%S")
fi
if [ -z "$commit_message" ]; then
    commit_message="dev_sprint_25_2 sync $current_date $current_time"
fi
if [ -z "$no_new_changes" ]; then
    no_new_changes=false
fi

print_status "Starting AAMP synchronization from step $start_from_step"

# Step 1: Check if aamp directory exists, clone if not
if should_execute_step $current_step; then
    print_step $current_step "Checking if aamp directory exists"
    if [ ! -d "aamp" ]; then
        print_status "aamp directory not found, cloning repository..."
        git clone https://github.com/rdkcentral/aamp.git || handle_error $current_step "Failed to clone aamp repository"
        print_status "Successfully cloned aamp repository"
    else
        print_status "aamp directory already exists"
    fi
else
    skip_step $current_step "Checking if aamp directory exists"
fi
current_step=$((current_step + 1))

# Step 2: Change to aamp directory
if should_execute_step $current_step; then
    print_step $current_step "Changing to aamp directory"
    cd ./aamp || handle_error $current_step "Failed to change to aamp directory"
else
    skip_step $current_step "Changing to aamp directory"
    # Still change directory if aamp exists for later steps
    if [ -d "aamp" ]; then
        cd ./aamp 2>/dev/null || true
    fi
fi
current_step=$((current_step + 1))

# Step 3: Checkout dev_sprint_25_2 branch
if should_execute_step $current_step; then
    print_step $current_step "Checking out dev_sprint_25_2 branch"
    git checkout dev_sprint_25_2 || handle_error $current_step "Failed to checkout dev_sprint_25_2 branch"
else
    skip_step $current_step "Checking out dev_sprint_25_2 branch"
fi
current_step=$((current_step + 1))

# Step 4: Pull latest changes for dev_sprint_25_2
if should_execute_step $current_step; then
    print_step $current_step "Pulling latest changes for dev_sprint_25_2"
    git pull || handle_error $current_step "Failed to pull latest changes for dev_sprint_25_2"
else
    skip_step $current_step "Pulling latest changes for dev_sprint_25_2"
fi
current_step=$((current_step + 1))

# Step 5: Get latest commit ID from dev_sprint_25_2
if should_execute_step $current_step; then
    print_step $current_step "Getting latest commit ID from dev_sprint_25_2"
    dev_sprint_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get latest commit ID from dev_sprint_25_2"
    dev_sprint_short_commit=$(git log -1 --format="%h") || handle_error $current_step "Failed to get short commit ID from dev_sprint_25_2"
    print_status "dev_sprint_25_2 latest commit: $dev_sprint_commit"
    save_state
else
    skip_step $current_step "Getting latest commit ID from dev_sprint_25_2"
fi
current_step=$((current_step + 1))

# Step 6: Checkout feature/RDKEMW-13297 branch
if should_execute_step $current_step; then
    print_step $current_step "Checking out feature/RDKEMW-13297 branch"
    git checkout feature/RDKEMW-13297 || handle_error $current_step "Failed to checkout feature/RDKEMW-13297 branch"
else
    skip_step $current_step "Checking out feature/RDKEMW-13297 branch"
fi
current_step=$((current_step + 1))

# Step 7: Pull latest changes for feature/RDKEMW-13297
if should_execute_step $current_step; then
    print_step $current_step "Pulling latest changes for feature/RDKEMW-13297"
    git pull || handle_error $current_step "Failed to pull latest changes for feature/RDKEMW-13297"
else
    skip_step $current_step "Pulling latest changes for feature/RDKEMW-13297"
fi
current_step=$((current_step + 1))

# Step 8: Get second commit ID (likely the previously merged dev_sprint_25_2)
if should_execute_step $current_step; then
    print_step $current_step "Getting second commit ID from feature/RDKEMW-13297"
    feature_branch_commit=$(git log -2 --format="%H" | sed -n '2p') || handle_error $current_step "Failed to get second commit ID from feature/RDKEMW-13297"
    feature_branch_short_commit=$(git log -2 --format="%h" | sed -n '2p') || handle_error $current_step "Failed to get short second commit ID from feature/RDKEMW-13297"
    print_status "feature/RDKEMW-13297 second commit: $feature_branch_commit"
    save_state
else
    skip_step $current_step "Getting second commit ID from feature/RDKEMW-13297"
fi
current_step=$((current_step + 1))

# Step 9: Generate diff patch
if should_execute_step $current_step; then
    print_step $current_step "Generating diff patch"
    patch_filename="${dev_sprint_short_commit}_${feature_branch_short_commit}.patch"
    git diff $feature_branch_commit $dev_sprint_commit > ../$patch_filename || handle_error $current_step "Failed to generate diff patch"
    print_status "Patch file created: $patch_filename"
    save_state
else
    skip_step $current_step "Generating diff patch"
    # If skipping, try to infer patch filename from existing files
    if [ -z "$patch_filename" ] && [ -n "$dev_sprint_short_commit" ] && [ -n "$feature_branch_short_commit" ]; then
        patch_filename="${dev_sprint_short_commit}_${feature_branch_short_commit}.patch"
        save_state
    fi
fi
current_step=$((current_step + 1))

# Step 10: Merge dev_sprint_25_2 into feature/RDKEMW-13297
if should_execute_step $current_step; then
    print_step $current_step "Merging dev_sprint_25_2 into feature/RDKEMW-13297"
    merge_output=$(git merge dev_sprint_25_2 2>&1) || handle_error $current_step "Failed to merge dev_sprint_25_2 into feature/RDKEMW-13297"
    echo "$merge_output"

    # Check if already up to date
    if echo "$merge_output" | grep -q "Already up to date"; then
        print_warning "Already up to date - no new changes to sync"
        print_status "Skipping add and push steps (11-12) as no new changes were merged"
        
        # Still get the latest commit ID for success message
        aamp_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for aamp"
        print_status "aamp current commit ID: $aamp_final_commit"
        
        # Set flag to skip middleware patch application steps later
        no_new_changes=true
        save_state
    else
        print_status "New changes merged successfully"
        no_new_changes=false
        save_state
        current_step=$((current_step + 1))
        
        # Step 11: Add all changes
        if should_execute_step $current_step; then
            print_step $current_step "Adding all changes"
            git add --all || handle_error $current_step "Failed to add changes"
        else
            skip_step $current_step "Adding all changes"
        fi
        current_step=$((current_step + 1))
        
        # Step 12a: Commit changes (if needed)
        if should_execute_step $current_step; then
            print_step $current_step "Committing merge changes"
            # Check if there are staged changes to commit
            if git diff --cached --quiet; then
                print_status "No staged changes to commit (merge was fast-forward)"
            else
                git commit -m "Merge dev_sprint_25_2 into feature/RDKEMW-13297" || handle_error $current_step "Failed to commit merge changes"
                print_status "Merge changes committed successfully"
            fi
            
            # Step 12b: Push changes to origin
            print_step $current_step "Pushing changes to origin feature/RDKEMW-13297"
            git push origin feature/RDKEMW-13297 || handle_error $current_step "Failed to push changes to origin"
            aamp_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for aamp"
            print_status "aamp push completed. New commit ID: $aamp_final_commit"
            save_state
        else
            skip_step $current_step "Committing merge changes"
            # Still get the commit ID for later use
            aamp_final_commit=$(git log -1 --format="%H") || handle_error $current_step "Failed to get final commit ID for aamp"
            save_state
        fi
    fi
else
    skip_step $current_step "Merging dev_sprint_25_2 into feature/RDKEMW-13297"
    # Still try to get the commit ID for later use if in aamp directory
    if [ -d ".git" ]; then
        aamp_final_commit=$(git log -1 --format="%H" 2>/dev/null) || aamp_final_commit="unknown"
        save_state
    fi
fi

# Change back to parent directory for next phase
cd ../

print_status "AAMP synchronization completed successfully"
print_status "Final aamp commit ID: $aamp_final_commit"
print_status "Patch file generated: $patch_filename"
print_status "No new changes flag: $no_new_changes"