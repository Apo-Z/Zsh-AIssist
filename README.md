# ZSH AI Assistant Plugin

This experimental ZSH plugin aims to integrate AI-powered command suggestions into your terminal. It's a work in progress and may help enhance your command-line experience with AI assistance.

## Features

- Basic AI-powered command suggestions based on your input
- Support for OpenAI GPT and Ollama models (requires separate setup)
- Attempt at context-aware suggestions using a special keyword
- Color-coded output for readability
- Simple interactive selection of suggested commands
- Option to execute selected commands directly
- Basic logging for troubleshooting

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/Apo-Z/zsh-aissist.git
   ```

2. Add the plugin to your `.zshrc`:
   ```
   source /path/to/zsh-aissist/zsh-aissist.zsh
   ```

3. Ensure Python 3 is installed on your system.

4. Install the required Python package:
   ```
   pip install requests
   ```

5. Set up your preferred AI model:
   - For OpenAI: Set the `OPENAI_API_KEY` environment variable with your API key.
   - For Ollama: Make sure the Ollama service is running locally.

## Configuration

You can adjust some basic settings in `zsh-aissist.zsh`:

- `AI_MODEL`: Choose "ollama:llama3.1" or "openai:gpt-4-mini"
- `CONTEXT_KEYWORD`: Set a keyword for providing context (default: "/h")
- `LOGFILE`: Set the path for the log file

## Usage

1. In your terminal, type a command or describe what you're trying to do.
2. Press `Ctrl+Space` to request AI suggestions.
3. The plugin will show AI-generated suggestions (if available).
4. Use `Tab` to cycle through suggestions, `Enter` to select, or `Ctrl+C` to cancel.
5. You can press `Ctrl+E` to try executing the selected command directly.

To provide context for your request, you can use the context keyword:
```
git commit /h This is my first commit for the project
```

## Files

- `zsh-aissist.zsh`: Main plugin file
- `ai_helper.py`: Simple Python script for AI model interaction
- `LICENSE`: License information
- `README.md`: This file

## Contributing

This is a personal project, but suggestions or improvements are welcome. Feel free to open an issue or submit a pull request if you'd like to contribute.

## License

This project is shared under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This plugin is an experiment and may not always provide accurate or useful suggestions. Use the generated commands with caution and always review them before execution.