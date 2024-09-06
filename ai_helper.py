import sys
import json
import requests
from os import getenv


def get_ai_suggestions(ai_model, prompt, os, os_family, version):
    system_prompt = f"""You are an AI assistant specialized in providing precise and efficient shell commands for {os} ({os_family}) version {version}. Your role is to suggest the most relevant and safe commands based on the user's input. Follow these guidelines strictly:

    1. Provide 2 to 3 commands, each with an accompanying advice.
    2. Do NOT suggest commands to install packages or software. Assume all necessary tools are already installed.
    3. Tailor your suggestions to {os_family}-specific commands when relevant.
    4. If the user's input is incomplete or unclear, provide the most likely completion or interpretation.
    5. For system administration tasks, prefer commands that don't require sudo, unless absolutely necessary.
    6. If a task requires multiple steps, combine them into a single command using && where appropriate.
    7. Use short flags (-a) instead of long options (--all) when it doesn't impact readability.
    8. If applicable, use command substitution, pipes, or redirection to create more efficient one-liners.
    9. For file operations, prefer safe commands that prompt for confirmation on destructive actions.
    10. If the user's request is ambiguous, provide variants addressing different possible interpretations.
    11. Provide your response in JSON format with 'commands' as the main key, containing an array of objects with 'command' and 'advice' keys.
    12. Always assume the user has the necessary permissions to execute the commands.

    Remember, your suggestions should be directly executable and highly relevant to the user's input and their {os} ({os_family}) system."""

    provider, model = ai_model.split(':')

    try:
        if provider == "openai":
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {getenv('OPENAI_API_KEY')}"
            }
            data = {
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.7,
                "response_format": {"type": "json_object"}
            }
            response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=data)
            if response.status_code == 200:
                result = response.json()['choices'][0]['message']['content']
            else:
                return f"ERROR: {response.json().get('error', {}).get('message', 'Unknown error')}"
        elif provider == "ollama":
            data = {
                "model": model,
                "prompt": prompt,
                "system": system_prompt,
                "stream": False,
                "format": "json"
            }
            response = requests.post("http://localhost:11434/api/generate", json=data)
            if response.status_code == 200:
                result = response.json().get('response', '')
            else:
                return f"ERROR: {response.text}"
        else:
            return f"ERROR: Unsupported AI provider: {provider}"
    except Exception as e:
        return f"ERROR: {str(e)}"

    try:
        commands = json.loads(result)['commands']
        output = ""
        for i, cmd in enumerate(commands, 1):
            output += f"{i}) {cmd['command']}\n   Advice: {cmd['advice']}\n\n"
        return output.strip()
    except (json.JSONDecodeError, KeyError):
        return "ERROR: Invalid JSON response from AI."

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("ERROR: Incorrect number of arguments")
        sys.exit(1)

    ai_model, prompt, os, os_family, version = sys.argv[1:]
    print(get_ai_suggestions(ai_model, prompt, os, os_family, version))