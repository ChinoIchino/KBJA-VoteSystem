#!/bin/bash

source newvote.sh
source repvote.sh
source editvote.sh

printHelpMain(){
    echo "Available commands:"
    echo "- newvote : enter the vote creation environment"
    echo "- repvote <id of vote>: answer a vote, if the vote have already been answered, modify the registered answers"
    echo -e "- editvote <id of vote>: edit a previously created vote, only the author is authorized to do so (WIP)\n"
}
safeExit(){
    echo -e "\nDETECTED NON-SAFE EXIT\nWrapping up the program, please use the exit command next time.\n"
    #TODO Add safe exit (saving important information, etc...)

    exit 0
}

# Adding a trap in case the user use, ctrl+C or another method to quit non safely
trap safeExit INT TERM

echo "------ Entering KBJA Environment ------"

while true; do
    read -p "KBJA> " input
    
    command=$(echo "$input" | awk '{print $1}')
    
    if [ "$command" = "exit" ]; then
        echo -e "------ Exited Successfully KBJA Environment ------\n"
        break;
    elif [ "$command" = "help" ]; then
        printHelpMain
    elif [ "$command" = "newvote" ]; then
        newVoteEnv
    elif [ "$command" = "repvote" ]; then
        possibleId=$(echo "$input" | awk -F ' ' '{print $2}')
        repVoteEnvMod "$possibleId"

        # Override the repVoteEnv trap with the main one
        trap safeExit INT TERM
    elif [ "$command" = "editvote" ]; then
        possibleId=$(echo "$input" | awk -F ' ' '{print $2}')
        editVoteEnv "$possibleId"
        
        trap safeExit INT TERM
    else
        echo -e "ERROR : Command not found. Having trouble finding a command ? Try the 'help' command.\n"
    fi
done
