#!/usr/bin/env zsh
# Configuration
AI_MODEL="ollama:llama3.1"
# AI_MODEL="openai:gpt-4o-mini"
CONTEXT_KEYWORD="/h"
LOGFILE="${HOME}/.ai_zsh_plugin.log"
PYTHON_SCRIPT="${0:A:h}/ai_helper.py"

# Color codes
PINK='\033[38;5;213m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${LOGFILE}"
}

# AI suggestion widget
ai_suggest_widget() {
    local buffer="${BUFFER}"
    log_message "AI suggest widget activated"
    local prompt
    if [[ "${buffer}" == *"${CONTEXT_KEYWORD}"* ]]; then
        local cmd_part="${buffer%%${CONTEXT_KEYWORD}*}"
        local context="${buffer#*${CONTEXT_KEYWORD}}"
        prompt="Complete this shell command: '${cmd_part}'. Context: ${context}"
    else
        prompt="Suggest a shell command for: ${buffer}"
    fi

    if [[ -z "${prompt}" || "${prompt}" == "Suggest a shell command for: " ]]; then
        echo "Error: Empty prompt. Please enter a command or query."
        zle reset-prompt
        return
    fi
    echo " "
    echo "Fetching AI suggestions..."

    # Call Python script
    local suggestions
    suggestions=$(python3 "${PYTHON_SCRIPT}" "${AI_MODEL}" "${prompt}" "${OS}" "${OS_FAMILY}" "${VERSION}")

    if [[ "${suggestions}" == ERROR:* ]]; then
        echo "${suggestions#ERROR: }"
        zle reset-prompt
        return
    fi

    # Parse suggestions into arrays
    local -a cmds
    local -a advices
    local cmd=""
    local advice=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9]+\) ]]; then
            if [[ -n "$cmd" ]]; then
                cmds+=("$cmd")
                advices+=("$advice")
                cmd=""
                advice=""
            fi
            cmd="${line#*) }"
        elif [[ "$line" =~ ^[[:space:]]*Advice: ]]; then
            advice="${line#*Advice: }"
        fi
    done <<< "$suggestions"
    if [[ -n "$cmd" ]]; then
        cmds+=("$cmd")
        advices+=("$advice")
    fi

    if [[ ${#cmds[@]} -eq 0 ]]; then
        echo "No valid suggestions received."
        zle reset-prompt
        return
    fi

    # Display suggestions with color
    echo "\nSuggested commands:"
    echo "-------------------"
    for ((i=1; i<=${#cmds[@]}; i++)); do
        echo "${PINK}${cmds[$i]}${RESET}"
        echo "   ${CYAN}${advices[$i]}${RESET}"
        echo "------"
    done
    echo "-------------------"
    echo "Use Tab to cycle through choices, Enter to select, or Ctrl-C to cancel."

    local selected=1
    local max_choice=${#cmds[@]}

    # Function to display the current selection with color
    display_selection() {
        echo -n "\r> ${PINK}${cmds[$selected]}${RESET}"
        echo -n "\033[K"  # Clear to end of line
    }

    # Initial display
    display_selection

    while true; do
        read -k 1 -s key
        case "$key" in
            $'\t')  # Tab key
                ((selected++))
                if ((selected > max_choice)); then
                    selected=1
                fi
                display_selection
                ;;
            $'\n'|$'\r')  # Enter key
                echo  # Move to a new line
                BUFFER="${cmds[$selected]}"  # Insert the command into the buffer
                CURSOR=$#BUFFER
                zle redisplay
                return 0
                ;;
            $'\C-e')  # Ctrl-E to execute the selected command directly
                echo  # Move to a new line
                log_message "Executing command: ${cmds[$selected]}"
                zle kill-whole-line  # Clear the current input line
                zle -I  # Clear the current input buffer
                zle reset-prompt  # Reset the prompt to avoid superimposed text
                print -S "${cmds[$selected]}"  # Add command to history
                echo "\n"  # Move to a new line
                echo "--- Command ---"
                echo "${PINK}${cmds[$selected]}${RESET}\n"  # Display the command being executed
                echo "--- Output ---"
                eval "${cmds[$selected]}"  # Execute the selected command directly
                echo "\n--- End of output ---"
                zle accept-line  # Simulate pressing Enter to refresh the prompt
                return 0
                ;;
            $'\C-c')  # Ctrl-C
                echo "\nCancelled."
                zle reset-prompt
                return 1
                ;;
        esac
    done

}

# Register the widget and bind it to Ctrl+Space
zle -N ai_suggest_widget
bindkey '^@' ai_suggest_widget

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS="${NAME}"
    VERSION="${VERSION_ID}"
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VERSION=$(lsb_release -sr)
else
    OS=$(uname -s)
    VERSION=$(uname -r)
fi

OS_FAMILY="Unknown"
case "${OS}" in
    *Ubuntu*|*Debian*|*Mint*) OS_FAMILY="Debian" ;;
    *Fedora*|*CentOS*|*Red\ Hat*|*RHEL*) OS_FAMILY="RedHat" ;;
    *Arch*|*Manjaro*) OS_FAMILY="Arch" ;;
    *SUSE*|*openSUSE*) OS_FAMILY="SUSE" ;;
    *Alpine*) OS_FAMILY="Alpine" ;;
    *Gentoo*) OS_FAMILY="Gentoo" ;;
    *macOS*|*Darwin*) OS_FAMILY="macOS" ;;
esac

log_message "AI Zsh Plugin loaded"