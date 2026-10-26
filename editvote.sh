#!/bin/bash

#TODO implement a safe exit trap

readonly SHARED_FOLDER=("/home/chino/Desktop/Project/L3SystemesEtReseaux/proj/FakeSharedEnv/")

printHelpEditVote(){
    echo "Possible commands:"
    echo "- modq [id of question] \"Are apples green ?\" : Modify the question with the id given, the new question need to be between quotes (WIP)"
    echo "- moda [id of question] [id of answer] \"Depend on the maturity\" : Modify the answer to a question, the order of the answers are from top to bottom, the new answer need to be between quotes (WIP)"
    echo "- modexp [New deadline in days] : Change the expiration date to which other users can answer to this vote. It add the given ammount of days to today's date (WIP)"
    echo "- rmq [id of question] : Remove the question with the given id (WIP)"
    echo "- rma [id of question] [id of answer] : Delete the answer to a question, the order of the answers are from top to bottom"
    echo -e "- ls : Display all informations about the questions and answers inside the current vote\n"
}

# Display all the question of the current vote, with a user friendly display
printQuestionsClean(){
    local questionFile="$1"

    mapfile -t questionFileSegmented < <(echo "$(less $questionFile)" | awk -F '\n' '{for(i=1; i<=NF; i++) print $i}')
    sizeOfFileArray="${#questionFileSegmented[@]}"
    cursor=0

    # echo "Got SizeArray:$sizeOfFileArray"
    while (( $cursor < $sizeOfFileArray )); do
        currCommand=$(echo "${questionFileSegmented[$cursor]}" | awk -F '[' '{print $1}')
        currInfo=$(echo "${questionFileSegmented[$cursor]}" | awk -F '[' '{print $2}')
        # echo "Got currCommand=$currCommand // currInfo=$currInfo"
        if [[ "$currCommand" == "nq" ]]; then
            # echo "Got a question"
            answerCounter=0
            
            idQuestion=$(echo "$currInfo" | awk -F ';' '{print $1}')
            questionName=$(echo "$currInfo" | awk -F ';' '{print $2}')
            isAMultChoice=$(echo "$currInfo" | awk -F ';' '{print $3}' | awk -F ']' '{print $1}')

            # If its not the first question, add a line break, for more digest display
            if [[ "$idQuestion" != "0" ]]; then
                echo ""
            fi
            
            # echo "IsAMultChoice='$isAMultChoice'"
            if [[ "$isAMultChoice" == "1" ]]; then
                echo "IdQuestion[$idQuestion] '$questionName' // Is a multiple choice question"
            else
                echo "IdQuestion[$idQuestion] '$questionName'"
            fi
        elif [[ "$currCommand" == "na" ]]; then
            # echo "Got a answer"
            answerName=$(echo "$currInfo" | awk -F ';' '{print $2}' | awk -F ']' '{print $1}')
            
            echo "  IdAnswer[$answerCounter] '$answerName'"
            answerCounter=$((answerCounter + 1))
        fi

        cursor=$((cursor + 1))
    done
    echo ""
}

editVoteEnv(){
    local idOfVote="$1"
    
    # Save the path to the vote folder and verify if it exist
    questionFolder=("$SHARED_FOLDER/Vote-$idOfVote")
    if [ ! -e "$questionFolder" ]; then
        echo -e "ERROR: Vote unavailable. Id[$idOfVote] wasn't found\n"
        return
    fi

    # Save the path to the log file and verify if it exist
    logFile=("$questionFolder/Info.log")
    if [ ! -e "$logFile" ]; then
        echo -e "ERROR: Vote unavailable. The vote id[$idOfVote] doesn't contain any author identity.\n"
        return
    fi

    questionFile=("$questionFolder/Questions.txt")

    # Save the file content inside a array
    readarray -t logFileArray < "$logFile"
    sizeOfFileArray="${#logFileArray[@]}"
    cursor=0

    while (( $cursor < $sizeOfFileArray )); do
        currItem=$(echo "${logFileArray[$cursor]})")
        if echo "$currItem" | grep -Eq 'Author.*'; then
            break
        fi
        cursor=$((cursor + 1))
    done

    # If the cursor is equal to the file size, then it didn't found the author
    if [[ "$cursor" == "$sizeOfFileArray" ]]; then
        echo -e "ERROR: The author informations weren't found. This vote seems broken, no one can modify it.\n" 
        return
    fi

    authorizedUser=$(echo "${logFileArray[$cursor]}" | awk -F '[' '{print $2}' | awk -F ';' '{print $1}')
    if [[ "$HOSTNAME" != "$authorizedUser" ]]; then
        echo -e "ERROR: You are not the author of this vote. You are not allowed to modify this vote.\n"
        return
    fi

    echo "Author entered the edit environment at $(date)" >> $logFile

    echo -e "\n------ Entering KBJA-edit Environment ------"

    while true; do
        read -p "KBJA-edit> " input
        command=$(echo "$input" | awk '{print $1}')

        if [ "$command" == "exit" ]; then
            echo "Author quit the edit environment at $(date)" >> $logFile
            echo -e "------ Exited successfully from KBJA-edit environment ------\n"
            break;
        elif [ "$command" == "help" ]; then
            printHelpEditVote
        elif [ "$command" == "ls" ]; then
            printQuestionsClean "$questionFile"
        elif [ "$command" == "modq" ]; then
            echo "WIP"
            #TODO Implement
        elif [ "$command" == "moda" ]; then
            echo "WIP"
            #TODO Implement
        elif [ "$command" == "modexp" ]; then
            echo "WIP"
            #TODO Implement
        elif [ "$command" == "rmq" ]; then
            echo "WIP"
            #TODO Implement
        elif [ "$command" == "rma" ]; then
            validCommand=true

            idOfQuestion=$(echo "$input" | awk -F ' ' '{print $2}')
            idOfAnswer=$(echo "$input" | awk -F ' ' '{print $3}')

            if [[ ! "$idOfQuestion" =~ ^[0-9]+$ ]]; then
                echo -e "ERROR: The question id '$idOfQuestion' is not a valid value.\n"
                validCommand=false
            fi

            if [[ ! "$idOfAnswer" =~ ^[0-9]+$ && $validCommand == true ]]; then
                echo -e "ERROR: The answer id '$idOfAnswer' is not a valid value.\n"
                validCommand=false
            fi

            if [[ $validCommand == true ]]; then
                mapfile -t questionFileSegmented < "$questionFile"
                sizeOfFileArray="${#questionFileSegmented[@]}"
                cursor=0
                
                currAswIndex=-1

                validCommand=false

                # Goes to the question id given
                while (( $cursor < $sizeOfFileArray )); do
                    currLine=$(echo "${questionFileSegmented[$cursor]}" | awk -F '[' '{print $1}')
                    
                    # If its a question increment the question index
                    if [[ "$currLine" == "nq" ]]; then
                        currAswIndex=$((currAswIndex + 1))
                        # If the question index is equal to the given id, it break the while loop that search inside the file
                        if [[ "$currAswIndex" == "$idOfQuestion" ]]; then
                            validCommand=true
                            break
                        fi
                    fi

                    cursor=$((cursor + 1))
                done

                if [[ $validCommand == false ]]; then
                    echo -e "ERROR: The question id wasn't found, please enter a valid question id.\n"
                fi

                if [[ $validCommand == true ]]; then
                    # Verify if the answer id don't leak into another question
                    for (( i=0; i<=$idOfAnswer; i++ ));do
                        currLine=$(echo "${questionFileSegmented[$((cursor + i + 1))]}" | awk -F '[' '{print $1}')

                        # If in the next indexes there is a question, then it has leaked
                        if [[ "$currLine" == "nq" ]]; then
                            echo -e "ERROR : The id of the answer have leaked into another question, please enter a valid answer id.\n"
                            validCommand=false
                            break
                        fi

                        if [[ "$i" == "$idOfAnswer" ]]; then
                            cursor=$((cursor + i + 1))
                        fi                    
                    done
                fi

                # If the answer id didnt leak, delete the answer, and fix the file
                if [[ $validCommand == true ]]; then
                    #Override the current index with the next one to "delete" the unwanted answer
                    while (( $cursor <= $sizeOfFileArray )); do
                        questionFileSegmented[$cursor]="${questionFileSegmented[$((cursor + 1))]}"
                        cursor=$((cursor + 1))    
                    done
                
                    echo "$(date) $HOSTNAME : Modified the vote with the command 'rma $idOfQuestion $idOfAnswer'" >> $logFile

                    #Override the current file with the modified one
                    printf "%s\n" "${questionFileSegmented[@]}">$questionFile
                fi
            fi
        else
            echo -e "ERROR : Command not found. Having trouble finding a command ? Try the 'help' command.\n"
        fi
    done
}