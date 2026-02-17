#!/bin/bash

#=============================================================================
# dev_sprint_25_2 sync script - Main Orchestrator
# 
# This script synchronizes changes from dev_sprint_25_2 branch to 
# feature/RDKEMW-13297 branch across three RDK Central repositories:
# - aamp
# - middleware-player-interface 
# - meta-rdk-video
#
# This main script handles preprocessing, state management, and orchestrates
# the execution of specialized sync scripts for each repository.
#
# Usage: ./pi_aamp_sync_pannum_naveena_machine.sh [start_step]
#   start_step: (optional) Step number to start from (1-48). Default is 1.
#=============================================================================

set -e  # Exit on any error

# Parse command line arguments
start_from_step=1
if [ $# -eq 1 ]; then
    if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 48 ]; then
        start_from_step=$1
        echo "Starting from step $start_from_step"
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [start_step]"
        echo ""
        echo "This script syncs dev_sprint_25_2 branch changes to feature/RDKEMW-13297 branch"
        echo "for aamp, middleware-player-interface, and meta-rdk-video repositories."
        echo ""
        echo "Arguments:"
        echo "  start_step    Optional. Step number to start from (1-48)."
        echo "                If not provided, starts from step 1."
        echo ""
        echo "State Management:"
        echo "  The script automatically saves progress to 'pi_sync.temp' file."
        echo "  If the script fails, you can resume from the last completed step."
        echo "  When starting from step 1, any existing state file is removed."
        echo "  When resuming from a later step, the state file is loaded automatically."
        echo ""
        echo "Examples:"
        echo "  $0           # Start from step 1 (default)"
        echo "  $0 10        # Start from step 10, skipping steps 1-9"
        echo "  $0 25        # Start from step 25, skipping steps 1-24"
        echo "  $0 45        # Start from step 45, skipping steps 1-44"
        echo ""
        echo "Steps overview:"
        echo "  1-12:   aamp repository operations"
        echo "  13-26:  middleware-player-interface operations"
        echo "  27-40:  meta-rdk-video operations"
        echo "  41-48:  aamp source update operations (OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID)"
        echo ""
        echo "Modular Scripts:"
        echo "  aamp_sync.sh         - Handles aamp repository operations (steps 1-12)"
        echo "  pi_sync.sh           - Handles middleware-player-interface operations (steps 13-26)"
        echo "  mrv_sync.sh          - Handles meta-rdk-video operations (steps 27-40)"
        echo "  sim_source_update.sh - Handles aamp source update operations (steps 41-48)"
        exit 0
    else
        echo "Error: Invalid step number '$1'. Must be a number between 1 and 48."
        echo "Use --help for usage information."
        exit 1
    fi
elif [ $# -gt 1 ]; then
    echo "Error: Too many arguments provided."
    echo "Use --help for usage information."
    exit 1
fi

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

# Function to handle errors
handle_error() {
    print_error "Script failed at step $1: $2"
    print_error "Steps completed successfully up to step $((current_step - 1))"
    
    # Save current state before exiting
    save_state
    print_status "State saved to $STATE_FILE - you can resume using: $0 $current_step"
    
    exit 1
}

# State file for persistence - use absolute path to keep it in sync directory
SYNC_DIR="$(pwd)"
STATE_FILE="$SYNC_DIR/pi_sync.temp"

# Functions for state management
save_state() {
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
    print_status "State saved to $STATE_FILE (step $current_step)"
}

load_state() {
    if [ -f "$STATE_FILE" ]; then
        print_status "Loading previous state from $STATE_FILE"
        source "$STATE_FILE"
        print_status "State loaded: resuming from step $start_from_step (last completed: step $((current_step - 1)))"
        
        # Display key restored variables for verification
        if [ -n "$dev_sprint_commit" ]; then
            print_status "Restored dev_sprint_commit: $dev_sprint_commit"
        fi
        if [ -n "$aamp_final_commit" ]; then
            print_status "Restored aamp_final_commit: $aamp_final_commit"
        fi
        if [ -n "$middleware_final_commit" ]; then
            print_status "Restored middleware_final_commit: $middleware_final_commit"
        fi
        if [ -n "$patch_filename" ]; then
            print_status "Restored patch_filename: $patch_filename"
        fi
        if [ -n "$filtered_patch_filename" ]; then
            print_status "Restored filtered_patch_filename: $filtered_patch_filename"
        fi
        
        # Set current_step to start_from_step for proper continuation
        current_step=$start_from_step
    else
        print_warning "State file $STATE_FILE not found, cannot restore previous state"
        print_warning "This may cause issues if resuming from step > 1"
    fi
}

initialize_state() {
    if [ $start_from_step -eq 1 ]; then
        # Starting fresh - remove old state file if exists
        if [ -f "$STATE_FILE" ]; then
            print_status "Removing existing state file for fresh start"
            rm "$STATE_FILE"
        fi
        print_status "Starting fresh from step 1"
    else
        # Resuming from specific step - try to load state
        print_status "Attempting to resume from step $start_from_step"
        load_state
    fi
}

# Variables
current_step=1
current_date=$(date +"%Y-%m-%d")
current_time=$(date +"%H:%M:%S")
commit_message="dev_sprint_25_2 sync $current_date $current_time"
dev_sprint_commit=""
dev_sprint_short_commit=""
feature_branch_commit=""
feature_branch_short_commit=""
patch_filename=""
filtered_patch_filename=""
aamp_final_commit=""
middleware_final_commit=""
meta_rdk_video_final_commit=""
sim_source_final_commit=""
no_new_changes=false
middleware_sections=0
current_aamp_srcrev=""
current_player_interface_srcrev=""
current_middleware_option_commit_id=""
aamp_updated=false
player_interface_updated=false
middleware_option_updated=false

# Print starting information
initialize_state

# Function to check if required script files exist
check_required_scripts() {
    local missing_scripts=()
    
    if [ ! -f "./aamp_sync.sh" ]; then
        missing_scripts+=("aamp_sync.sh")
    fi
    
    if [ ! -f "./pi_sync.sh" ]; then
        missing_scripts+=("pi_sync.sh")
    fi
    
    if [ ! -f "./mrv_sync.sh" ]; then
        missing_scripts+=("mrv_sync.sh")
    fi
    
    if [ ! -f "./sim_source_update.sh" ]; then
        missing_scripts+=("sim_source_update.sh")
    fi
    
    if [ ${#missing_scripts[@]} -ne 0 ]; then
        print_error "Required script files are missing:"
        for script in "${missing_scripts[@]}"; do
            print_error "  - $script"
        done
        print_error "Please ensure all sync scripts are present in the same directory."
        exit 1
    fi
    
    # Make scripts executable
    chmod +x ./aamp_sync.sh ./pi_sync.sh ./mrv_sync.sh ./sim_source_update.sh
}

# Check for required scripts
check_required_scripts

# Determine which phase to start from
phase_start=""
if [ $start_from_step -ge 1 ] && [ $start_from_step -le 12 ]; then
    phase_start="aamp"
    print_status "Starting with aamp repository phase (steps 1-12)"
elif [ $start_from_step -ge 13 ] && [ $start_from_step -le 26 ]; then
    phase_start="middleware"
    print_status "Starting with middleware-player-interface repository phase (steps 13-26)"
elif [ $start_from_step -ge 27 ] && [ $start_from_step -le 40 ]; then
    phase_start="meta-rdk-video"
    print_status "Starting with meta-rdk-video repository phase (steps 27-40)"
elif [ $start_from_step -ge 41 ] && [ $start_from_step -le 48 ]; then
    phase_start="sim-source-update"
    print_status "Starting with aamp source update phase (steps 41-48)"
fi

# Phase 1: AAMP Repository Operations (Steps 1-12)
if [ "$phase_start" = "aamp" ] || [ -z "$phase_start" ]; then
    print_status "=========================================="
    print_status "PHASE 1: AAMP REPOSITORY SYNCHRONIZATION"
    print_status "=========================================="
    
    # Calculate the start step for aamp_sync.sh (1-based within that script)
    aamp_start_step=$start_from_step
    if [ $aamp_start_step -gt 12 ]; then
        aamp_start_step=13  # Skip aamp phase entirely
    fi
    
    if [ $aamp_start_step -le 12 ]; then
        print_status "Calling aamp_sync.sh with start step $aamp_start_step"
        
        # Call aamp_sync.sh and capture its output
        if ./aamp_sync.sh "$aamp_start_step" "$STATE_FILE"; then
            print_status "AAMP synchronization completed successfully"
            
            # Reload state to get updated variables from aamp_sync.sh
            if [ -f "$STATE_FILE" ]; then
                source "$STATE_FILE"
                print_status "State reloaded after aamp sync"
                # Capture aamp final commit and date/time immediately
                final_aamp_commit="$aamp_final_commit"
                final_current_date="$current_date"
                final_current_time="$current_time"
                final_patch_filename="$patch_filename"
                final_no_new_changes="$no_new_changes"
            fi
        else
            handle_error "12" "aamp_sync.sh failed"
        fi
    else
        print_status "Skipping AAMP phase (starting from step $start_from_step)"
    fi
fi

# Phase 2: Middleware-Player-Interface Repository Operations (Steps 13-26)
if [ "$phase_start" = "middleware" ] || [ -z "$phase_start" ] || [ $start_from_step -le 12 ]; then
    print_status "=========================================================="
    print_status "PHASE 2: MIDDLEWARE-PLAYER-INTERFACE SYNCHRONIZATION"
    print_status "=========================================================="
    
    # Calculate the start step for pi_sync.sh (13-based within that script)
    pi_start_step=$start_from_step
    if [ $pi_start_step -lt 13 ]; then
        pi_start_step=13  # Start from beginning of middleware phase
    elif [ $pi_start_step -gt 26 ]; then
        pi_start_step=27  # Skip middleware phase entirely
    fi
    
    if [ $pi_start_step -le 26 ]; then
        print_status "Calling pi_sync.sh with start step $pi_start_step"
        
        # Call pi_sync.sh and capture its output
        if ./pi_sync.sh "$pi_start_step" "$STATE_FILE"; then
            print_status "Middleware-player-interface synchronization completed successfully"
            
            # Reload state to get updated variables from pi_sync.sh
            if [ -f "$STATE_FILE" ]; then
                source "$STATE_FILE"
                print_status "State reloaded after middleware sync"
                # Capture middleware final commit immediately
                final_middleware_commit="$middleware_final_commit"
                final_middleware_sections="$middleware_sections"
                final_filtered_patch_filename="$filtered_patch_filename"
            fi
        else
            handle_error "26" "pi_sync.sh failed"
        fi
    else
        print_status "Skipping middleware phase (starting from step $start_from_step)"
    fi
fi

# Phase 3: Meta-RDK-Video Repository Operations (Steps 27-40)
if [ "$phase_start" = "meta-rdk-video" ] || [ -z "$phase_start" ] || [ $start_from_step -le 26 ]; then
    print_status "============================================="
    print_status "PHASE 3: META-RDK-VIDEO SYNCHRONIZATION"
    print_status "============================================="
    
    # Calculate the start step for mrv_sync.sh (27-based within that script)
    mrv_start_step=$start_from_step
    if [ $mrv_start_step -lt 27 ]; then
        mrv_start_step=27  # Start from beginning of meta-rdk-video phase
    elif [ $mrv_start_step -gt 40 ]; then
        mrv_start_step=41  # Skip meta-rdk-video phase entirely
    fi
    
    if [ $mrv_start_step -le 40 ]; then
        print_status "Calling mrv_sync.sh with start step $mrv_start_step"
        
        # Call mrv_sync.sh and capture its output
        if ./mrv_sync.sh "$mrv_start_step" "$STATE_FILE"; then
            print_status "Meta-rdk-video synchronization completed successfully"
            
            # Reload state to get updated variables from mrv_sync.sh
            if [ -f "$STATE_FILE" ]; then
                source "$STATE_FILE"
                print_status "State reloaded after meta-rdk-video sync"
                # Capture meta-rdk-video variables immediately
                final_aamp_updated="$aamp_updated"
                final_player_interface_updated="$player_interface_updated"
                final_meta_rdk_video_commit="$meta_rdk_video_final_commit"
            fi
        else
            handle_error "40" "mrv_sync.sh failed"
        fi
    else
        print_status "Skipping meta-rdk-video phase (starting from step $start_from_step)"
    fi
fi

# Phase 4: AAMP Source Update Operations (Steps 41-48)
if [ "$phase_start" = "sim-source-update" ] || [ -z "$phase_start" ] || [ $start_from_step -le 40 ]; then
    print_status "==========================================================="
    print_status "PHASE 4: AAMP SOURCE UPDATE SYNCHRONIZATION"
    print_status "==========================================================="
    
    # Calculate the start step for sim_source_update.sh (41-based within that script)
    sim_start_step=$start_from_step
    if [ $sim_start_step -lt 41 ]; then
        sim_start_step=41  # Start from beginning of sim-source-update phase
    fi
    
    if [ $sim_start_step -le 48 ]; then
        print_status "Calling sim_source_update.sh with start step $sim_start_step"
        
        # Call sim_source_update.sh and capture its output
        if ./sim_source_update.sh "$sim_start_step" "$STATE_FILE"; then
            print_status "AAMP source update synchronization completed successfully"
            
            # Reload state to get updated variables from sim_source_update.sh
            if [ -f "$STATE_FILE" ]; then
                source "$STATE_FILE"
                print_status "State reloaded after aamp source update sync"
                # Capture sim-source-update variables immediately
                final_middleware_option_updated="$middleware_option_updated"
                final_sim_source_commit="$sim_source_final_commit"
                final_middleware_option_commit_id="$current_middleware_option_commit_id"
            fi
        else
            handle_error "48" "sim_source_update.sh failed"
        fi
    else
        print_status "Skipping aamp source update phase (starting from step $start_from_step)"
    fi
fi

# Clean up state file on successful completion
if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    print_status "Removed state file $STATE_FILE after successful completion"
fi

# Success message
echo ""
echo "============================================"
echo -e "${GREEN}SUCCESS: All phases completed successfully!${NC}"
echo "============================================"
echo ""
echo "Summary of operations:"
if [ "$final_no_new_changes" = true ]; then
    echo "- No new changes to sync - aamp repository already up to date"
    echo "- Skipped middleware operations as no new changes were available"
else
    echo "- Synced dev_sprint_25_2 to feature/RDKEMW-13297 in aamp repository"
    if [ -z "$final_middleware_sections" ] || [ "$final_middleware_sections" -eq 0 ]; then
        echo "- No middleware changes found, skipped middleware operations"
    else
        echo "- Applied filtered changes to middleware-player-interface repository ($final_middleware_sections diff sections)"
    fi
fi

# Meta-rdk-video operations summary
echo "- Processed meta-rdk-video repository:"
if [ "$final_aamp_updated" = true ] && [ "$final_player_interface_updated" = true ]; then
    echo "  - Updated both SRCREV_aamp and SRCREV for player-interface"
    echo "  - Committed and pushed changes to feature/RDKEMW-13297"
elif [ "$final_aamp_updated" = true ]; then
    echo "  - Updated SRCREV_aamp only"
    echo "  - Committed and pushed changes to feature/RDKEMW-13297"
elif [ "$final_player_interface_updated" = true ]; then
    echo "  - Updated SRCREV for player-interface only"
    echo "  - Committed and pushed changes to feature/RDKEMW-13297"
else
    echo "  - No SRCREV updates needed - both already up to date"
fi

# AAMP source update operations summary
echo "- Processed aamp source update operations:"
if [ "$final_middleware_option_updated" = true ]; then
    echo "  - Updated OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID to $final_middleware_commit"
    echo "  - Committed and pushed changes to feature/RDKEMW-13297"
else
    echo "  - OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID already up to date ($final_middleware_commit)"
fi

echo ""
echo "New commit IDs:"
echo "- aamp repository: $final_aamp_commit"
echo "- middleware-player-interface repository: $final_middleware_commit"
echo "- meta-rdk-video repository: $final_meta_rdk_video_commit"
if [ -n "$final_sim_source_commit" ]; then
    echo "- aamp repository (after source update): $final_sim_source_commit"
fi
echo ""
echo "SRCREV synchronization status:"
if [ "$final_aamp_updated" = true ]; then
    echo "- aamp_git.bb SRCREV_aamp: Updated to $final_aamp_commit"
else
    echo "- aamp_git.bb SRCREV_aamp: Already synchronized ($final_aamp_commit)"
fi
if [ "$final_player_interface_updated" = true ]; then
    echo "- player-interface_git.bb SRCREV: Updated to $final_middleware_commit"
else
    echo "- player-interface_git.bb SRCREV: Already synchronized ($final_middleware_commit)"
fi
echo ""
echo "AAMP option synchronization status:"
if [ "$final_middleware_option_updated" = true ]; then
    echo "- OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID: Updated to $final_middleware_commit"
else
    echo "- OPTION_MIDDLEWARE_PLAYER_INTERFACE_COMMIT_ID: Already synchronized ($final_middleware_commit)"
fi
echo ""
echo "Patch files (created and cleaned up):"
echo "- Full patch: $final_patch_filename (removed)"
echo "- Filtered middleware patch: $final_filtered_patch_filename (removed after use)"
echo ""
echo "Sync completed on: $final_current_date at $final_current_time"
echo "============================================"

