# zsh-copilot

A lightweight Zsh plugin that predict your next command using llm. You can also ask to create a command.

## Installation

## Preliminaries

Make sure you have [`cURL`](https://curl.se/) and [`jq`](https://stedolan.github.io/jq/) installed.

If you would like to have markdown rendering with option `-m`, [`glow`](https://github.com/charmbracelet/glow) is required (Recommend).

Acquire your private api-key from [OpenAI](https://platform.openai.com/account/api-keys).

### Via installer

It's simple and easy to use. Just run the following command in your terminal:

```sh
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Gamma-Software/zsh-copilot/refs/heads/master/install.sh)"
```

### Manual (Git Clone)

1. Clone this repository into `$ZSH_CUSTOM/plugins` (by default `~/.oh-my-zsh/plugins`)

```sh
git clone https://github.com/Gamma-Software/zsh-copilot ${ZSH_CUSTOM:-~/.oh-my-zsh}/plugins/zsh-copilot
```

2. Add the plugin to the list of plugins for Oh My Zsh to load (inside `~/.zshrc`):

```sh
plugins=(
   # other plugins...
   zsh-copilot
)
```

3. Add the following to your `$ZSH_CUSTOM/plugins/zsh-copilot/.env` file:
```sh
ZSH_COPILOT_API_KEY="<Your API key here>"
```

4. Restart your terminal or run:
```sh
source ~/.zshrc
```

## Uninstallation

Run the command:
```sh
zsh-copilot uninstall
```

## Features

### Direct ChatGPT Interaction

## Usage

Fill your OpenAI api key as `ZSH_ASK_API_KEY` (see [INSTALL.md](INSTALL.md) for detail information), then just run

```
zsh-copilot who are you
```

To fix previous command error.

```
zsh-copilot fix
```

Note: You can also use `zcf` instead of `zsh-copilot fix`.

To ask to create a command.

```
zsh-copilot ask <command to generate>
```

Note: You can also use `zca` instead of `zsh-copilot ask`.

For instance, you can ask to create a command to search for a file in the current directory.

```
zsh-copilot ask search for the file "test.txt" in the current directory
```

Use `-c` for dialogue format communication.

```
zsh-copilot -c chat with me
```

Use `-m` for markdown rendering (`glow` required)

```
zsh-copilot -m how to code quick sort in python
```

Use `-s` for streaming display (doesn't work with `-m` yet)

```
zsh-copilot -s write a poem for me
```

Use `-i` to inherits history from last chat (which is recorded in ZSH_COPILOT_HISTORY).

```
zsh-copilot -i tell me more about it
```

Use `-h` for more information.

```
zsh-copilot -h
```

## Local & Custom LLM Support

`zsh-copilot` supports any OpenAI-compatible API endpoint, allowing you to run completely offline using local models (e.g., **LM Studio**, **Ollama**, **vLLM**, or **LocalAI**).

### Configuration via CLI

Run the interactive configuration tool:
```sh
zsh-copilot config
```
Select option `2` to set the **API Endpoint URL**, option `1` for the **Model**, and option `3` to adjust **Max Tokens** (useful for reasoning models).

### Manual Configuration (`.env`)

You can also set these variables in `$ZSH_CUSTOM/plugins/zsh-copilot/.env`:

#### LM Studio
```sh
ZSH_COPILOT_API_URL="http://localhost:1234/v1/chat/completions"
ZSH_COPILOT_MODEL="<your-model-identifier>"
ZSH_COPILOT_API_KEY="not-needed"
ZSH_COPILOT_TOKENS=4000
```

#### Ollama
```sh
ZSH_COPILOT_API_URL="http://localhost:11434/v1/chat/completions"
ZSH_COPILOT_MODEL="qwen2.5-coder:7b"
ZSH_COPILOT_API_KEY="ollama"
ZSH_COPILOT_TOKENS=2000
```

#### vLLM / LocalAI
```sh
ZSH_COPILOT_API_URL="http://localhost:8000/v1/chat/completions"
ZSH_COPILOT_MODEL="<your-model-name>"
ZSH_COPILOT_API_KEY="not-needed"
```

### Command Prediction and Generation
This plugin provides two powerful command-line features:

1. **Command Prediction** (Option+p or Ctrl+x p)
   - Analyzes your recent command history
   - Suggests the next likely command based on your patterns
   - Press Option+p (Mac) or Ctrl+x p to see the prediction
   - The predicted command appears in your command line ready to execute

2. **Command Generation** (Option+a or Ctrl+x a)
   - Type what you want to do in plain English
   - Press Option+a (Mac) or Ctrl+x a to generate the command
   - Example: Type "find all PDF files modified today" and press Option+a
   - The generated command appears in your command line ready to execute

3. **Error Fixing** (Option+f or Ctrl+x f)
   - Automatically captures the last failed command and its error
   - Generates a corrected version of the command
   - Press Option+f (Mac) or Ctrl+x f to see the fixed command
   - The corrected command appears in your command line ready to execute

Both features:
- Place commands directly in your command line
- Allow you to edit before executing
- Can be cancelled with Ctrl+C
- Support full command-line editing

Have fun!

## Alias

You can use `zsh-copilot` as `zc`. For fixing errors, you can use `zcf`. For asking to create a command, you can use `zca`.

## License

This project is licensed under [MIT license](http://opensource.org/licenses/MIT). For the full text of the license, see the [LICENSE](LICENSE) file.