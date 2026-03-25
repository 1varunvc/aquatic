# Project Specification: Aquatic CLI Toolkit

## 1. Project Overview
Aquatic is a unified, open-source command-line toolkit for video processing, Git tagging, data parsing, and browser automation. 
It uses a router pattern. The main executable is `aquatic`, which routes commands to modular sub-scripts prefixed with `aquatic-`.

## 2. General AI Instructions
When generating or modifying code for this project, you MUST adhere to the following strict guidelines. Do not deviate from these formatting, logging, or architectural standards. 
**CRITICAL:** Absolutely no emojis are allowed in any script outputs, logs, or comments.

## 3. Architecture & Naming Conventions
* **Router:** The main entry point is `aquatic` (Bash). It receives a command and shifts arguments to the respective sub-script.
* **Sub-scripts:** Must be named `aquatic-<command-name>.<ext>`.
* **Browser Snippets:** Must be named `aquatic-snippet-platform-<name>.js`. The router injects variables using `sed` and copies the output to the macOS clipboard using `pbcopy`.

## 4. Header Standard
Every single file (Bash, Node.js, or Browser JS) MUST start with the exact following header block, adapted for the specific language's comment syntax.

For Bash:
```bash
#!/bin/bash

###############################################################################
# Script Name : aquatic-script-name.sh
# Description : Brief description of what the script does.
#
# Author      : Varun Chawla
# Created On  : [Current Date]
# Last Updated: [Current Date]
# Version     : 1.0
# Usage       : aquatic command <arg1> [optional_arg]
# Requirements: [List dependencies like ffmpeg, gh, node, etc.]
###############################################################################
```

For JS, use `//` for the border and block comments, but keep the exact same textual layout.

## 5. Logging & Output Standards
Console outputs must be clean, professional, and strictly formatted.
* Success messages: `echo "[OK] Operation successful."`
* Info messages: `echo "[INFO] Processing 15 files..."`
* Error messages: `echo "[ERROR] File not found."`
* Process separators: `echo "-----------------------------------"`

## 6. Error Handling & Validation
* Always validate required inputs at the very top of the script.
* If arguments are missing, print the Usage instructions and `exit 1`.
* Example:
```bash
if [ -z "$1" ]; then
    echo "Usage: aquatic command <required_arg> [optional_arg]"
    exit 1
fi
```
* Provide default fallbacks for optional parameters using Bash parameter expansion (e.g., `FPS="${3:-30}"`).
* Always validate directory existence before `cd`ing into it:
  `cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }`

## 7. Technology Stack Rules
* **Bash:** Prefer POSIX compliance where possible. Rely on standard macOS tools (`sed`, `awk`, `pbcopy`).
* **Video:** Use `ffmpeg`.
* **Git:** Use the GitHub CLI (`gh api`) and `jq` for JSON parsing.
* **Data:** Use Node.js (`#!/usr/bin/env node`) with standard built-in modules (`fs`, `path`) whenever possible to minimize `package.json` dependencies.
