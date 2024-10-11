#!/bin/bash
FILE_PATH="$HOME" 
# touch $FILE_PATH/workflow_commands.txt
# If the program abruptly stops, remove the temp.json
if [ -f "$FILE_PATH/temp.json" ]; then
    rm "$FILE_PATH/temp.json"
fi

# Create commands.json file if it doesn't exist
if [ ! -f "$FILE_PATH/commands.json" ]; then
    echo "{}" > "$FILE_PATH/commands.json"
fi

function create_workflow() {
    jq --arg name "$2" '.[$name]=[]' "$FILE_PATH/commands.json" > "$FILE_PATH/temp.json" && mv "$FILE_PATH/temp.json" "$FILE_PATH/commands.json"
    echo "Enter the commands for the workflow:"
    truncate -s 0 "$FILE_PATH/workflow_commands.txt"
    vi "$FILE_PATH/workflow_commands.txt"
    while IFS= read -r line; do
        jq --arg cmd "$line" --arg name "$2" '.[$name] += [$cmd]' "$FILE_PATH/commands.json" > "$FILE_PATH/temp.json" && mv "$FILE_PATH/temp.json" "$FILE_PATH/commands.json"
    done < "$FILE_PATH/workflow_commands.txt"
    rm "$FILE_PATH/workflow_commands.txt"
    echo "Workflow '$2' created successfully!"
}

function update_workflow() {
    if jq -e --arg key "$2" 'has($key) and (.[ $key ] | type == "array")' "$FILE_PATH/commands.json" > /dev/null; then
        truncate -s 0 "$FILE_PATH/workflow_commands.txt"
        jq -r --arg key "$2" '.[$key][]' "$FILE_PATH/commands.json" | while IFS= read -r command; do
            echo "$command" >> "$FILE_PATH/workflow_commands.txt"
        done
        vi "$FILE_PATH/workflow_commands.txt"
        jq --arg name "$2" '.[$name]=[]' "$FILE_PATH/commands.json" > "$FILE_PATH/temp.json" && mv "$FILE_PATH/temp.json" "$FILE_PATH/commands.json"
        while IFS= read -r line; do
            jq --arg cmd "$line" --arg name "$2" '.[$name] += [$cmd]' "$FILE_PATH/commands.json" > "$FILE_PATH/temp.json" && mv "$FILE_PATH/temp.json" "$FILE_PATH/commands.json"
        done < "$FILE_PATH/workflow_commands.txt"
        rm "$FILE_PATH/workflow_commands.txt"
    else
        echo "Workflow $2 Not Found!"
    fi
}

function run_workflow() {
    if jq -e --arg key "$2" 'has($key) and (.[ $key ] | type == "array")' "$FILE_PATH/commands.json" > /dev/null; then
        truncate -s 0 "$FILE_PATH/run_workflow_commands.sh"
        jq -r --arg key "$2" '.[$key][]' "$FILE_PATH/commands.json" | while IFS= read -r command; do
            echo "$command" >> "$FILE_PATH/run_workflow_commands.sh"
        done
        chmod +x "$FILE_PATH/run_workflow_commands.sh"
        "$FILE_PATH/run_workflow_commands.sh"
        rm "$FILE_PATH/run_workflow_commands.sh"
    else
        echo "Workflow $2 Not Found!"
    fi
}

function delete_workflow() {
    if jq -e --arg key "$2" 'has($key) and (.[ $key ] | type == "array")' "$FILE_PATH/commands.json" > /dev/null; then
        jq --arg key "$2" 'del(.[$key])' "$FILE_PATH/commands.json" > "$FILE_PATH/temp.json" && mv "$FILE_PATH/temp.json" "$FILE_PATH/commands.json"
    else
        echo "Workflow $2 doesn't exist"
    fi
}

case "$1" in 
    "create")
        create_workflow "$1" "$2"
        ;;
    "update")
        update_workflow "$1" "$2"
        ;;
    "delete")
        delete_workflow "$1" "$2"
        ;;
    "run")
        run_workflow "$1" "$2"
        ;;
    *)
        echo "Invalid command. Use 'create', 'update', 'delete', or 'run'"
        ;;
esac
