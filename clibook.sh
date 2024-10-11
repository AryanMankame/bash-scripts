#!/bin/bash
# If program abruptly stops remove the temp.json
if [ -f temp.json ]; then
    rm temp.json
fi
if [ ! -f commands.json ]; then
    echo "{}" > commands.json
fi
function create_workflow() {
    jq --arg name "$2" '.[$name]=[]' commands.json > temp.json && mv temp.json commands.json
    echo "Enter the commands for the workflow:"
    truncate -s 0 workflow_commands.txt
    vi workflow_commands.txt
    while IFS= read -r line; do
        jq --arg cmd "$line" --arg name "$2" '.[$name] += [$cmd]' commands.json > temp.json && mv temp.json commands.json
    done < "workflow_commands.txt"
    rm workflow_commands.txt
    echo "Workflow '$2' created successfully!"
}
function update_workflow() {
    if jq -e --arg key "$2" 'has($key) and (.[ $key ] | type == "array")' commands.json > /dev/null; then
        truncate -s 0 workflow_commands.txt
        jq -r --arg key "$2" '.[$key][]' commands.json | while IFS= read -r command; do
            # Append each command to the new file
            echo "$command" >> workflow_commands.txt
        done
        vi workflow_commands.txt
        jq --arg name "$2" '.[$name]=[]' commands.json > temp.json && mv temp.json commands.json
        while IFS= read -r line; do
            jq --arg cmd "$line" --arg name "$2" '.[$name] += [$cmd]' commands.json > temp.json && mv temp.json commands.json
        done < "workflow_commands.txt"
        rm workflow_commands.txt

    else
        echo "Workflow $2 Not Found!"
    fi
}
function run_workflow() {
    if jq -e --arg key "$2" 'has($key) and (.[ $key ] | type == "array")' commands.json > /dev/null; then
        truncate -s 0 run_workflow_commands.sh
        jq -r --arg key "$2" '.[$key][]' commands.json | while IFS= read -r command; do
            # Append each command to the new file
            echo "$command" >> run_workflow_commands.sh
        done
        jq --arg name "$2" '.[$name]=[]' commands.json > temp.json && mv temp.json commands.json
        while IFS= read -r line; do
            jq --arg cmd "$line" --arg name "$2" '.[$name] += [$cmd]' commands.json > temp.json && mv temp.json commands.json
        done < "run_workflow_commands.sh"
        chmod +x run_workflow_commands.sh
        ./run_workflow_commands.sh
        rm run_workflow_commands.sh
    else
        echo "Workflow $2 Not Found!"
    fi
}
function delete_workflow() {
    if jq -e --arg key "$2" 'has($key) and (.[ $key ] | type == "array")' commands.json > /dev/null; then
        jq --arg key "$2" 'del(.[$key])' commands.json > temp.json && mv temp.json commands.json
    else
        echo "Workflow $2 doesn't exist"
    fi
}
case "$1" in 
    "create")
        create_workflow $1 $2
        ;;
    "update")
        update_workflow $1 $2
        ;;
    "delete")
        delete_workflow $1 $2
        ;;
    "run")
        run_workflow $1 $2
        ;;
    *)
        echo "Invalid command. Use 'create', 'update', 'delete', or 'run'"
        ;;
esac