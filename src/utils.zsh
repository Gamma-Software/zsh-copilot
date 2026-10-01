# Utility functions
function _zsh_copilot_detect_shortcut() {
    # Enable raw input mode
    stty raw -echo

    # Read key sequence
    local key=""
    local sequence=""

    # Read first character
    read -k1 key
    sequence+=$key

    # Handle escape sequences
    if [[ $key == $'\e' ]]; then
        # Read potential modifiers and key
        read -k1 -t 0.1 key
        sequence+=$key
        if [[ $key == "[" ]]; then
            read -k1 -t 0.1 key
            sequence+=$key
            # Read any additional characters
            while read -k1 -t 0.1 key; do
                sequence+=$key
            done
        fi
    fi

    # Restore terminal settings
    stty -raw echo

    # Convert to hex and store in variable
    local hex_sequence=$(echo -n "$sequence" | xxd -p)
    echo "$hex_sequence"
}

function _zsh_copilot_read_shortcut() {
    # Read text input
    local text=""
    read text

    # Convert to hex and store in variable
    echo "$text"
}

function _hex_to_char() {
    echo -n "${(#)$(echo -n $1 | sed 's/\([0-9a-f]\{2\}\)/\\x\1/g')}"
}

function _zsh_copilot_error_reminder() {
    local exit_code=$?
    # Get the last executed command from history
    local last_cmd=$(fc -ln -1)
    # Only show message for non-zero exit codes, ignore common status codes, and non-empty commands
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ] && [ $exit_code -ne 141 ] && [ ! -z "$last_cmd" ] && [ "$last_cmd" != "_zsh_copilot_error_reminder" ]; then
        echo "\033[0;33mTip: Run 'zsh-copilot fix' or 'zcf' to get a suggested fix for this error.\033[0m"
    fi
    return $exit_code
}

function _zsh_copilot_install_prerequisites() {
    local os_type=$(uname -s)
    local missing_deps=()

    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi

    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        return 0
    fi

    echo "\033[0;34mInstalling missing dependencies: ${missing_deps[*]}\033[0m"

    case "$os_type" in
        Linux*)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y ${missing_deps[@]}
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y ${missing_deps[@]}
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y ${missing_deps[@]}
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy --noconfirm ${missing_deps[@]}
            else
                echo "\033[0;31mUnable to detect package manager. Please install ${missing_deps[*]} manually.\033[0m"
                return 1
            fi
            ;;
        Darwin*)
            if ! command -v brew >/dev/null 2>&1; then
                echo "\033[0;34mInstalling Homebrew...\033[0m"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install ${missing_deps[@]}
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows handling
            if [[ " ${missing_deps[@]} " =~ " jq " ]]; then
                echo "\033[0;34mInstalling jq for Windows...\033[0m"
                mkdir -p /usr/bin
                curl -L -o /usr/bin/jq.exe https://github.com/jqlang/jq/releases/latest/download/jq-win64.exe
                chmod +x /usr/bin/jq.exe
            fi
            if [[ " ${missing_deps[@]} " =~ " curl " ]]; then
                echo "\033[0;31mcurl is required but not installed. Please install Git for Windows which includes curl.\033[0m"
                return 1
            fi
            ;;
        *)
            echo "\033[0;31mUnsupported operating system: $os_type\033[0m"
            return 1
            ;;
    esac

    # Verify installation
    local failed=0
    for dep in ${missing_deps[@]}; do
        if ! command -v $dep >/dev/null 2>&1; then
            echo "\033[0;31mFailed to install $dep\033[0m"
            failed=1
        fi
    done

    if [[ $failed -eq 0 ]]; then
        echo "\033[0;32mAll dependencies installed successfully!\033[0m"
        return 0
    else
        return 1
    fi
}

function _zsh_copilot_update() {
    echo "\033[0;34mUpdating zsh-copilot...\033[0m"
    zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/install.sh)"
}


function _zsh_copilot_uninstall() {
    echo "\033[0;34mUninstalling zsh-copilot...\033[0m"

    # Ask for confirmation
    echo "\033[0;31mThis will remove zsh-copilot completely. Are you sure? (y/N)\033[0m"
    read confirm
    if [[ "$confirm" != "y" ]]; then
        echo "\033[0;32mUninstall cancelled.\033[0m"
        return 1
    fi

    # Plugin name
    PLUGIN_NAME="zsh-copilot"

    # Determine ZSH_CUSTOM path if not set
    if [ -z "$ZSH_CUSTOM" ]; then
        ZSH_CUSTOM="$HOME/.oh-my-zsh"
    fi

    PLUGIN_DIR="$ZSH_CUSTOM/plugins/$PLUGIN_NAME"

    # Remove plugin from .zshrc
    if grep -q "plugins=.*$PLUGIN_NAME" "$HOME/.zshrc"; then
        echo "\033[0;34mRemoving plugin from .zshrc...\033[0m"
        # Create backup of .zshrc
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
        # Remove plugin from plugins list
        sed -i.bak "s/$PLUGIN_NAME//" "$HOME/.zshrc"
        # Clean up empty spaces in plugins list
        sed -i.bak 's/plugins=(  *)/plugins=()/' "$HOME/.zshrc"
        sed -i.bak 's/  */ /g' "$HOME/.zshrc"
        echo "\033[0;32mPlugin removed from .zshrc\033[0m"
        echo "\033[0;34mBackup created at ~/.zshrc.backup\033[0m"
    fi

    # Remove plugin directory
    if [ -d "$PLUGIN_DIR" ]; then
        echo "\033[0;34mRemoving plugin directory...\033[0m"
        rm -rf "$PLUGIN_DIR"
        if [ $? -eq 0 ]; then
            echo "\033[0;32mPlugin directory removed successfully\033[0m"
        else
            echo "\033[0;31mFailed to remove plugin directory\033[0m"
            return 1
        fi
    fi

    # Clean up any temporary files
    rm -f "$HOME/.zshrc.bak"

    echo "\033[0;32mUninstallation complete!\033[0m"
    echo "\033[0;34mPlease restart your terminal or run: source ~/.zshrc\033[0m"
}

function _zsh_validate_ping_api() {
    local ping_url="https://api.openai.com/v1/models"
    if [[ -n "$ZSH_COPILOT_API_URL" && "$ZSH_COPILOT_API_URL" != "https://api.openai.com/v1/chat/completions" ]]; then
        if [[ "$ZSH_COPILOT_API_URL" == *"/chat/completions" ]]; then
            ping_url="${ZSH_COPILOT_API_URL%/chat/completions}/models"
        elif [[ "$ZSH_COPILOT_API_URL" == *"/models" ]]; then
            ping_url="$ZSH_COPILOT_API_URL"
        else
            ping_url="${ZSH_COPILOT_API_URL%/}/models"
        fi
    fi
    local response_code=$(curl -s -m 3 -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ZSH_COPILOT_API_KEY" "$ping_url")
    if [[ $response_code -eq 401 ]]; then
        echo "\033[0;31mError: Invalid API key\033[0m"
        return 1
    elif [[ $response_code -eq 429 ]]; then
        echo "\033[0;31mError: Rate limit exceeded\033[0m"
        return 1
    elif [[ $response_code -eq 000 ]]; then
        echo "\033[0;31mError: Could not connect to API at $ping_url. Please check your connection or LLM server.\033[0m"
        return 1
    elif [[ $response_code -ne 200 ]]; then
        echo "\033[0;31mError: API returned status code $response_code\033[0m"
        return 1
    fi
    return 0
}

function _zsh_copilot_show_version() {
    cat "$ZSH_COPILOT_PREFIX/../VERSION"
}

function _zsh_copilot_show_help() {
    echo "Fix, predict, and ask commands using your command line Copilot powered by LLMs."
    echo "Usage: zsh-copilot [options...]"
    echo "       zsh-copilot [options...] '<your-question>'"
    echo "       zsh-copilot config"
    echo "       zsh-copilot update"
    echo "       zsh-copilot uninstall"
    echo "Aliases: zsh-copilot <-> zc"
    echo "Options:"
    echo "  -h                Display this help message."
    echo "  -v                Display the version number."
    echo "  -M <openai_model> Set OpenAI model to <openai_model>, default sets to gpt-3.5-turbo."
    echo "                    Models can be found at https://platform.openai.com/docs/models."
    echo "  -t <max_tokens>   Set max tokens to <max_tokens>, default sets to 800."
    echo "  -r                Print raw output."
    echo "  -o                Print only the output."
    echo "  -d                Print debug information."
    echo "Commands:"
    echo "  config         Configure plugin settings interactively."
    echo "  update           Update the plugin to the latest version."
    echo "  uninstall        Remove the plugin completely."
    echo "  fix             Fix the last failed command."
    echo "  ask <request>    Get a command suggestion for your request."
}