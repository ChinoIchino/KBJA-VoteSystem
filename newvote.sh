#!/bin/bash

readonly ID_VOTE=($(date +%s))
readonly VOTE_FOLDER_PATH=("/home/chino/Desktop/Project/L3SystemesEtReseaux/proj/FakeSharedEnv/Vote-$ID_VOTE")

readonly LOG_FILE=("$VOTE_FOLDER_PATH/Info.log")
readonly QUESTIONS_FILE=("$VOTE_FOLDER_PATH/Questions.txt")
readonly ANSWERS_FILE=("$VOTE_FOLDER_PATH/Answers.txt") # DEPRECATED Not used, might send it into another script

# Old way of doing
# readonly LOG_FILE=("$VOTE_FOLDER_PATH/CreatedVote-$(date +%d-%m-%Y_%Hh%M).log")

printHelpNewVote(){
    echo "Possible commands:
    - 'nq \"Are apples red ?\" -m' : Create a new question, the title need to be between quotes. The flag -m represent a question with multiple answers
    - 'na \"Depend on the variety !\" : Add an answer to the last opened question. The possible answer need to be between quotes
    - 'debugPrint' : Show every informations of the vote saved
    - 'exit' : exit the currently made vote\n"
}

newVoteEnv(){
    # TODO add the id of the vote based on the ammount of other votes created somehow
    mkdir $VOTE_FOLDER_PATH
    
    questionId=-1

    echo -e "\n------ Entering KBJA-new environment ------";
        
    # Add the date into the log file
    echo "Creation date: $(date)" >> $LOG_FILE

    read -p "KBJA-new> Enter in days when the vote expire: " input
    echo ""

    if echo "$input" | grep -Eq '[0-9]+'; then
        ExpirationDate=$(date +%d-%m-%Y -d "$(date) + $input day")
        echo "Expiration date: $ExpirationDate" >> $LOG_FILE
    else
        echo "Expiration date: NONE" >> $LOG_FILE
    fi

    # Ask for a author name
    read -p "KBJA-new> Enter the author name: " input
    echo ""

    # Add the author machine name and the input the user gave
    echo "Author[$HOSTNAME;$input]" >> $LOG_FILE
    # Skip the line for more digest environment

    

    while true; do
        read -p "KBJA-new> " input
        command=$(echo "$input" | awk '{print $1}')

        if [ "$command" = "exit" ]; then
            echo "Quit_Environment[$HOSTNAME;$(date)]" >> $LOG_FILE
            
            echo "The id of the vote is: $ID_VOTE"
            echo -e "------ Exited successfully from KBJA-new environment ------\n"
            break;
        elif [ "$command" = "help" ]; then
            printHelpNewVote
        elif [ "$command" = "nq" ]; then
            nameOfQuestion=$(echo "$input" | awk -F '"' '{print $2}')
            
            # Verify if there is the flag -m after the question 
            if echo "$input" | grep -Eq '".*".*(-m\b)'; then
                isMultipleChoice=1
            else
                isMultipleChoice=0
            fi
            # echo "Got : $nameOfQuestion And the flag : $flag"

            questionId=$((questionId + 1))
            echo "$(date) $HOSTNAME : Used the command nq[id:$questionId / Question:$nameOfQuestion / Have multiple choice:$isMultipleChoice]" >> $LOG_FILE
            echo "nq[$questionId;$nameOfQuestion;$isMultipleChoice]" >> $QUESTIONS_FILE
        elif [ "$command" = "na" ]; then
            nameOfAnswer=$(echo "$input" | awk -F '"' '{print $2}')
            echo "$(date) $HOSTNAME : Used the command na[id of question:$questionId / Answer:$nameOfAnswer]" >> $LOG_FILE
            echo "na[$questionId;$nameOfAnswer]" >> $QUESTIONS_FILE
        elif [ "$command" = "debugPrint" ]; then
            less $QUESTIONS_FILE
        else
            echo -e "ERROR : Command not found. Having trouble finding a command ? Try the 'help' command.\n"
        fi
        echo ""
    done
}