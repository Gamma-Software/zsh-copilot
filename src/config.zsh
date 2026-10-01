# Configuration related functions
function _setup-zsh-copilot() {
    # Set the plugin directory as the prefix
    typeset -g ZSH_COPILOT_PREFIX=${SCRIPT_PATH:A:h}
    typeset -g ZSH_COPILOT_PLUGIN_DIR=${ZSH_COPILOT_PREFIX}/../

    # Source .env file if it exists
    if [[ -f "$ZSH_COPILOT_PLUGIN_DIR/.env" ]]; then
        source "$ZSH_COPILOT_PLUGIN_DIR/.env"
    fi

    (( ! ${+ZSH_COPILOT_REPO} )) &&
    typeset -g ZSH_COPILOT_REPO="https://github.com/Gamma-Software/zsh-copilot"

    # Get the corresponding endpoint for your desired model.
    (( ! ${+ZSH_COPILOT_API_URL} )) &&
    typeset -g ZSH_COPILOT_API_URL="https://api.openai.com/v1/chat/completions"

    # Automatically append /chat/completions if base URL was provided
    if [[ -n "$ZSH_COPILOT_API_URL" && "$ZSH_COPILOT_API_URL" != *"/chat/completions" ]]; then
        typeset -g ZSH_COPILOT_API_URL="${ZSH_COPILOT_API_URL%/}/chat/completions"
    fi

    # Fill up your API key here (not strictly required for local/custom endpoints)
    if (( ! ${+ZSH_COPILOT_API_KEY} )); then
        if [[ "$ZSH_COPILOT_API_URL" != "https://api.openai.com/v1/chat/completions" ]]; then
            typeset -g ZSH_COPILOT_API_KEY="not-needed"
        else
            echo "Error: ZSH_COPILOT_API_KEY is not set."
            echo "Please reinstall the plugin and follow the setup instructions at:"
            echo "https://github.com/Gamma-Software/zsh-copilot#installation"
            return 1
        fi
    fi

    # Default configurations
    (( ! ${+ZSH_COPILOT_MODEL} )) &&
    typeset -g ZSH_COPILOT_MODEL="gpt-3.5-turbo"
    (( ! ${+ZSH_COPILOT_TOKENS} )) &&
    typeset -g ZSH_COPILOT_TOKENS=800

    (( ! ${+ZSH_COPILOT_CONVERSATION} )) &&
    typeset -g ZSH_COPILOT_CONVERSATION=false
    (( ! ${+ZSH_COPILOT_INHERITS} )) &&
    typeset -g ZSH_COPILOT_INHERITS=false
    (( ! ${+ZSH_COPILOT_MARKDOWN} )) &&
    typeset -g ZSH_COPILOT_MARKDOWN=false
    (( ! ${+ZSH_COPILOT_STREAM} )) &&
    typeset -g ZSH_COPILOT_STREAM=false
    (( ! ${+ZSH_COPILOT_HISTORY} )) &&
    typeset -g ZSH_COPILOT_HISTORY=""
    (( ! ${+ZSH_COPILOT_INITIALROLE} )) &&
    typeset -g ZSH_COPILOT_INITIALROLE="system"
    (( ! ${+ZSH_COPILOT_INITIALPROMPT} )) &&
    typeset -g ZSH_COPILOT_INITIALPROMPT="You are a large language model trained by OpenAI. Answer as concisely as possible.\nKnowledge cutoff: {knowledge_cutoff} Current date: {current_date}"

    # Default shortcuts
    (( ! ${+ZSH_COPILOT_SHORTCUT_PREDICT} )) &&
    typeset -g ZSH_COPILOT_SHORTCUT_PREDICT="c593"
    (( ! ${+ZSH_COPILOT_SHORTCUT_ASK} )) &&
    typeset -g ZSH_COPILOT_SHORTCUT_ASK="c3a6"
    (( ! ${+ZSH_COPILOT_SHORTCUT_FIX} )) &&
    typeset -g ZSH_COPILOT_SHORTCUT_FIX="c692"
}

function _zsh_copilot_configure() {
    local env_file="$ZSH_COPILOT_PLUGIN_DIR/.env"

    # Show current configuration
    function show_current_config() {
        echo "\033[0;34mCurrent Configuration:\033[0m"
        echo "\033[1;33m1.\033[0m Model: ${ZSH_COPILOT_MODEL}"
        echo "\033[1;33m2.\033[0m API Endpoint URL: ${ZSH_COPILOT_API_URL}"
        echo "\033[1;33m3.\033[0m Max Tokens: ${ZSH_COPILOT_TOKENS}"
        echo "\033[1;33m4.\033[0m API Key: ${ZSH_COPILOT_API_KEY}"
        echo "\033[1;33m5.\033[0m Predict Shortcut: ${ZSH_COPILOT_SHORTCUT_PREDICT}"
        echo "\033[1;33m6.\033[0m Ask Shortcut: ${ZSH_COPILOT_SHORTCUT_ASK}"
        echo "\033[1;33m7.\033[0m Fix Shortcut: ${ZSH_COPILOT_SHORTCUT_FIX}"
        echo "\033[1;33m8.\033[0m Exit"
    }

    # Create .env file if it doesn't exist
    if [[ ! -f "$env_file" ]]; then
        echo "\033[0;34mCreating new .env file...\033[0m"
        cat > "$env_file" << EOL
ZSH_COPILOT_API_URL=${ZSH_COPILOT_API_URL}
ZSH_COPILOT_MODEL=${ZSH_COPILOT_MODEL}
ZSH_COPILOT_TOKENS=${ZSH_COPILOT_TOKENS}
ZSH_COPILOT_API_KEY=${ZSH_COPILOT_API_KEY}
ZSH_COPILOT_SHORTCUT_PREDICT=${ZSH_COPILOT_SHORTCUT_PREDICT}
ZSH_COPILOT_SHORTCUT_ASK=${ZSH_COPILOT_SHORTCUT_ASK}
ZSH_COPILOT_SHORTCUT_FIX=${ZSH_COPILOT_SHORTCUT_FIX}
EOL
    fi

    # Update configuration
    function update_config() {
        local param=$1
        local value=$2
        local param_name=$3

        # Create backup only if file exists
        if [[ -f "$env_file" ]]; then
            cp "$env_file" "$env_file.backup"
        fi

        if grep -q "^$param=" "$env_file"; then
            # Update existing parameter
            sed -i.bak "s|^$param=.*|$param=$value|" "$env_file"
        else
            # Add new parameter
            echo "$param=$value" >> "$env_file"
        fi

        if [ $? -eq 0 ]; then
            echo "\033[0;32m$param_name updated successfully!\033[0m"
            source "$env_file"
        else
            echo "\033[0;31mFailed to update $param_name.\033[0m"
            if [[ -f "$env_file.backup" ]]; then
                mv "$env_file.backup" "$env_file"
                echo "\033[0;34mRestored from backup.\033[0m"
            fi
        fi

        # Clean up
        rm -f "$env_file.bak"
        rm -f "$env_file.backup"
    }

    while true; do
        show_current_config
        echo "\n\033[0;34mWhat would you like to modify? (1-8):\033[0m"
        read choice

        case $choice in
            1)
                echo "\033[0;34mEnter new model (e.g., gpt-3.5-turbo, gpt-4, or local model id):\033[0m"
                read new_model
                update_config "ZSH_COPILOT_MODEL" "$new_model" "Model"
                ;;
            2)
                echo "\033[0;34mEnter new API Endpoint URL (e.g., https://api.openai.com/v1/chat/completions or http://localhost:1234/v1/chat/completions):\033[0m"
                read new_url
                if [ -n "$new_url" ]; then
                    if [[ "$new_url" != *"/chat/completions" ]]; then
                        new_url="${new_url%/}/chat/completions"
                    fi
                    update_config "ZSH_COPILOT_API_URL" "$new_url" "API Endpoint URL"
                else
                    echo "\033[0;31mAPI Endpoint URL cannot be empty.\033[0m"
                fi
                ;;
            3)
                echo "\033[0;34mEnter new max tokens (50-100000):\033[0m"
                read new_tokens
                if [[ "$new_tokens" =~ ^[0-9]+$ ]] && [ "$new_tokens" -ge 50 ] && [ "$new_tokens" -le 100000 ]; then
                    update_config "ZSH_COPILOT_TOKENS" "$new_tokens" "Max tokens"
                else
                    echo "\033[0;31mInvalid token value. Please enter a number between 50 and 100000.\033[0m"
                fi
                ;;
            4)
                echo "\033[0;34mEnter API key (or 'not-needed' if using local LLM):\033[0m"
                read new_key
                if [ -n "$new_key" ]; then
                    update_config "ZSH_COPILOT_API_KEY" "$new_key" "API key"
                else
                    echo "\033[0;31mAPI key cannot be empty.\033[0m"
                fi
                ;;
            5)
                echo "\033[0;34mPress the desired shortcut for predict command:\033[0m"
                local sequence=$(_zsh_copilot_read_shortcut)
                if [[ -n "$sequence" ]]; then
                    update_config "ZSH_COPILOT_SHORTCUT_PREDICT" "$sequence" "Predict shortcut"
                fi
                ;;
            6)
                echo "\033[0;34mPress the desired shortcut for ask command:\033[0m"
                local sequence=$(_zsh_copilot_read_shortcut)
                if [[ -n "$sequence" ]]; then
                    update_config "ZSH_COPILOT_SHORTCUT_ASK" "$sequence" "Ask shortcut"
                fi
                ;;
            7)
                echo "\033[0;34mPress the desired shortcut for fix command:\033[0m"
                local sequence=$(_zsh_copilot_read_shortcut)
                if [[ -n "$sequence" ]]; then
                    update_config "ZSH_COPILOT_SHORTCUT_FIX" "$sequence" "Fix shortcut"
                fi
                ;;
            8)
                echo "\033[0;32mConfiguration complete!\033[0m"
                return 0
                ;;
            *)
                echo "\033[0;31mInvalid choice. Please select 1-8.\033[0m"
                ;;
        esac
        echo
    done
}