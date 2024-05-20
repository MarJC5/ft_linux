#!/bin/bash

# Function to parse INI style config file with section handling
parse_ini() {
    local section="$1"
    local key="$2"
    local config_file="$3"
    local in_section=false
    local value=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Remove leading and trailing whitespace
        line=$(echo "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')
        # Match sections
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            if [[ "${BASH_REMATCH[1]}" == "$section" ]]; then
                in_section=true
            else
                in_section=false
            fi
        # Match key=value; allows spaces around '='
        elif $in_section && [[ "$line" =~ ^$key[[:space:]]*=[[:space:]]*(.*) ]]; then
            value="${BASH_REMATCH[1]}"
            echo "$value"
            return 0
        fi
    done < "$config_file"
    return 1
}