#!/bin/sh
#
# m2-ai-tools installer
# Deploys Magento 2 AI skills to your project for use with AI coding assistants.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s claude
#   curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s codex
#   curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s copilot
#   curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s cursor
#   curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s gemini
#   curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s opencode
#
# Copyright (c) Monsoon Consulting. All rights reserved.

set -e

# --- Configuration ---

REPO_URL="${M2_SKILLS_REPO_URL:-https://github.com/monsoonconsulting/m2-ai-tools.git}"
BRANCH="${M2_SKILLS_BRANCH:-main}"

CLR_OK='\033[0;32m'
CLR_ERR='\033[0;31m'
CLR_WARN='\033[0;33m'
CLR_NOTE='\033[0;34m'
CLR_OFF='\033[0m'

SKILL_COUNT=0
SKILL_NAMES=""
HAS_GIT=0
TEMP_DIR=""

# --- Messages ---

msg_banner() {
    echo ""
    echo "${CLR_NOTE}--- m2-ai-tools installer ---${CLR_OFF}"
    echo ""
}

msg_ok() {
    echo "${CLR_OK}>>>${CLR_OFF} $1"
}

msg_warn() {
    echo "${CLR_WARN}[!]${CLR_OFF} $1"
}

msg_err() {
    echo "${CLR_ERR}[x]${CLR_OFF} $1"
}

msg_note() {
    echo "${CLR_NOTE}-->${CLR_OFF} $1"
}

# --- Helpers ---

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

trap cleanup EXIT

resolve_platform_path() {
    case "$1" in
        claude)   echo ".claude/skills" ;;
        codex)    echo ".codex/skills" ;;
        copilot)  echo ".github/skills" ;;
        cursor)   echo ".cursor/skills" ;;
        gemini)   echo ".gemini/skills" ;;
        opencode) echo ".opencode/skills" ;;
        *)
            msg_err "Unrecognized platform: $1"
            show_usage
            ;;
    esac
}

verify_tools() {
    for tool in curl tar mkdir; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            msg_err "Missing required command: $tool"
            exit 1
        fi
    done

    if command -v git >/dev/null 2>&1; then
        HAS_GIT=1
    else
        HAS_GIT=0
        msg_warn "git not available — falling back to archive download"
    fi
}

find_magento_root() {
    dir="$(pwd)"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/app/etc/env.php" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$(pwd)"
}

# --- Deploy ---

deploy_skill() {
    src="$1"
    dest_dir="$2"
    name="$3"
    target="$dest_dir/$name"

    if [ -d "$target" ]; then
        rm -rf "$target"
        cp -r "$src" "$target"
        msg_ok "Updated $name"
    else
        cp -r "$src" "$target"
        msg_ok "Installed $name"
    fi

    SKILL_COUNT=$((SKILL_COUNT + 1))
    SKILL_NAMES="$SKILL_NAMES $name"
}

deploy_all_skills() {
    repo_root="$1"
    dest_dir="$2"
    src_dir="$repo_root/skills"

    if [ ! -d "$src_dir" ]; then
        msg_err "Skills directory missing from repository"
        return 1
    fi

    # Deploy the _shared directory (referenced by all skills)
    if [ -d "$src_dir/_shared" ]; then
        deploy_skill "$src_dir/_shared" "$dest_dir" "_shared"
    fi

    # Deploy all m2-* skill directories
    found=0
    for skill_path in "$src_dir"/m2-*; do
        if [ -d "$skill_path" ]; then
            deploy_skill "$skill_path" "$dest_dir" "$(basename "$skill_path")"
            found=1
        fi
    done

    if [ "$found" = "0" ]; then
        msg_warn "No m2-* skills found in repository"
    fi

    return 0
}

# --- Fetch ---

fetch_via_git() {
    dest_dir="$1"
    TEMP_DIR=$(mktemp -d)

    msg_note "Cloning repository (branch: $BRANCH)..."
    if ! git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        msg_err "Git clone failed"
        return 1
    fi

    deploy_all_skills "$TEMP_DIR" "$dest_dir"
}

fetch_via_archive() {
    dest_dir="$1"
    TEMP_DIR=$(mktemp -d)
    archive_url="${REPO_URL%.git}/archive/refs/heads/$BRANCH.tar.gz"

    msg_note "Downloading archive..."
    if ! curl -fsSL "$archive_url" -o "$TEMP_DIR/repo.tar.gz"; then
        msg_err "Archive download failed"
        return 1
    fi

    msg_note "Extracting..."
    if ! tar -xzf "$TEMP_DIR/repo.tar.gz" -C "$TEMP_DIR"; then
        msg_err "Extraction failed"
        return 1
    fi

    extracted=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*-*" | head -1)
    if [ -z "$extracted" ]; then
        msg_err "Could not locate extracted content"
        return 1
    fi

    deploy_all_skills "$extracted" "$dest_dir"
}

# --- Usage ---

show_usage() {
    echo "Usage: $0 <platform>"
    echo ""
    echo "Supported platforms:"
    echo "  claude    .claude/skills/"
    echo "  codex     .codex/skills/"
    echo "  copilot   .github/skills/"
    echo "  cursor    .cursor/skills/"
    echo "  gemini    .gemini/skills/"
    echo "  opencode  .opencode/skills/"
    echo ""
    echo "Examples:"
    echo "  curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s claude"
    echo "  curl -fsSL https://raw.githubusercontent.com/monsoonconsulting/m2-ai-tools/refs/heads/main/install.sh | sh -s cursor"
    echo ""
    echo "Environment variables:"
    echo "  M2_SKILLS_REPO_URL   Override the repository URL"
    echo "  M2_SKILLS_BRANCH     Branch to install from (default: main)"
    exit 1
}

# --- Entry point ---

run() {
    msg_banner

    if [ -z "$1" ]; then
        msg_err "Platform argument required"
        show_usage
    fi

    platform="$1"
    skills_rel=$(resolve_platform_path "$platform")

    msg_note "Platform: $platform"

    verify_tools

    project_root=$(find_magento_root)
    msg_note "Project root: $project_root"

    skills_dir="$project_root/$skills_rel"

    if [ ! -d "$skills_dir" ]; then
        mkdir -p "$skills_dir"
        msg_ok "Created $skills_rel"
    else
        msg_note "Using existing $skills_rel"
    fi

    if [ "$HAS_GIT" = "1" ]; then
        fetch_via_git "$skills_dir" || fetch_via_archive "$skills_dir"
    else
        fetch_via_archive "$skills_dir"
    fi

    echo ""
    echo "${CLR_OK}--- Done ---${CLR_OFF}"
    echo ""
    echo "Deployed ${CLR_OK}${SKILL_COUNT}${CLR_OFF} skills to ${skills_dir}"
    if [ -n "$SKILL_NAMES" ]; then
        for s in $SKILL_NAMES; do
            echo "  $s"
        done
    fi
    echo ""
    echo "Try: \"Create a new Magento 2 module\" or \"Add a plugin\""
    echo ""
}

run "$@"
