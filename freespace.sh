#!/bin/bash

# Default timeout value in hours
timeout=48
recursive=0

# Parsing command-line options
while getopts "rt:" opt; do
  case ${opt} in
    r )
      recursive=1
      ;;
    t )
      timeout=$OPTARG
      ;;
    \? )
      echo "Usage: cmd [-r] [-t timeout] file [file...]"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# Function to handle each file
process_file() {
  local file=$1
  local dir=$(dirname "$file")
  local basename=$(basename "$file")
  
  if [[ -f "$file" && ! "$basename" =~ ^fc-.* ]]; then
    if file "$file" | grep -qE 'gzip compressed|bzip2 compressed|Zip archive'; then
      # Move and touch the file if it's already compressed
      mv "$file" "${dir}/fc-${basename}"
      touch "${dir}/fc-${basename}"
    else
      # Zip the file if it's not compressed
      zip "${dir}/fc-${basename}.zip" "$file" && rm "$file"
    fi
  elif [[ -f "$file" && "$basename" =~ ^fc-.* ]]; then
    # Check if the file is older than the timeout and delete if necessary
    if [[ $(find "$file" -type f -mmin +$((timeout * 60))) ]]; then
      rm "$file"
    fi
  fi
}

# Function to process directories
process_directory() {
  local directory=$1
  for entry in "$directory"/*; do
    if [[ -d "$entry" && $recursive -eq 1 ]]; then
      process_directory "$entry"
    elif [[ -f "$entry" ]]; then
      process_file "$entry"
    fi
  done
}

# Main loop over all arguments
for arg in "$@"; do
  if [[ -d "$arg" ]]; then
    process_directory "$arg"
  elif [[ -f "$arg" ]]; then
    process_file "$arg"
  fi
done

