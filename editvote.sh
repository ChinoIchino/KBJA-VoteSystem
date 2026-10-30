#!/bin/bash

#TODO add all the logs mod
#TODO Verify if someone answered already the question. If yes, stop the modifications with a error message

readonly SHARED_FOLDER=("/home/chino/Desktop/Project/L3SystemesEtReseaux/proj/FakeSharedEnv/")

printHelpEditVote(){
    echo "Possible commands:"
    echo "- modq [id of question] \"Are apples green ?\" : Modify the question with the id given, the new question need to be between quotes"
    echo "- moda [id of question] [id of answer] \"Depend on the maturity\" : Modify the answer to a question, the order of the answers are from top to bottom, the new answer need to be between quotes"
    echo "- modexp [New deadline in days] : Change the expiration date to which other users can answer to this vote. It add the given ammount of days to today's date (WIP)"
    echo "- rmq [id of question] : Remove the question with the given id"
    echo "- rma [id of question] [id of answer] : Delete the answer to a question, the order of the answers are from top to bottom"
    echo -e "- ls : Display all informations about the questions and answers inside the current vote\n"
}

editSafeExit(){
    echo -e "\nDETECTED NON-SAFE EXIT\nAll edits made have been saved\n"
    echo "Quit abruptly, the edit environment at $(date)" >> $logFile
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

    if [ -s $questionFolder/Answers.txt ]; then
        echo -e "ERROR: Someone have already answered this vote. It is not possible anymore to edit it.\n"
        return
    fi

    echo "Author entered the edit environment at $(date)" >> $logFile

    trap 'editSafeExit; return' INT TERM

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
            validCommand=true

            if ! echo "$input" | grep -Eq 'modq[[:space:]][0-9]+[[:space:]]".*"'; then
                echo -e "ERROR: The command syntax isn't correct. Please use it like that : modq <id of question> \"The new question\"\n"
                validCommand=false
            fi

            idOfQuestion=$(echo "$input" | awk -F ' ' '{print $2}')

            if [[ $validCommand == true ]]; then
                newQuestion=$(echo "$input" | awk -F '"' '{print $2}')

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
            fi

            # If the question and answer id were found, modify the values at cursor
            if [[ $validCommand == true ]]; then
                questionFileSegmented[$cursor]=$(echo "${questionFileSegmented[$cursor]}" | awk -v newQuestion="$newQuestion" '{sub(/;.*;/, ";" newQuestion ";"); print;}')
                printf "%s\n" "${questionFileSegmented[@]}">$questionFile

                echo "$(date) Modified a question with the command : modq $idOfQuestion \"$newQuestion\"" >> $logFile
            else
                echo -e "ERROR: The question id wasn't found, please enter a valid question id.\n"
            fi
        elif [ "$command" == "moda" ]; then
            validCommand=true

            if ! echo "$input" | grep -Eq 'moda[[:space:]][0-9]+[[:space:]][0-9]+[[:space:]]".*"'; then
                echo -e "ERROR: The command syntax isn't correct. Please use it like that : moda <id of question> <id of answer> \"The new answer\"\n"
                validCommand=false
            fi

            idOfQuestion=$(echo "$input" | awk -F ' ' '{print $2}')
            idOfAnswer=$(echo "$input" | awk -F ' ' '{print $3}')

            if [[ $validCommand == true ]]; then
                newAnswer=$(echo "$input" | awk -F '"' '{print $2}')
                # echo "Got newAnswer='$newAnswer'"

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
                else
                    echo -e "ERROR: The question id wasn't found, please enter a valid question id.\n"
                fi

                # If the question and answer id were found, modify the values at cursor
                if [[ $validCommand == true ]]; then
                    # echo -e "About to modify the line, cursor=$cursor\nThen new line: '${questionFileSegmented[$cursor]}'"
                    questionFileSegmented[$cursor]=$(echo "${questionFileSegmented[$cursor]}" | awk -v newAsw="$newAnswer" '{sub(/;.*]/, ";" newAsw "]"); print;}')
                    # echo "The new line:'${questionFileSegmented[$cursor]}'"
                    printf "%s\n" "${questionFileSegmented[@]}">$questionFile

                    echo "$(date) Modified a answer with the command : moda $idOfQuestion $idOfAnswer \"$newAnswer\"" >> $logFile
                fi
            fi
        elif [ "$command" == "modexp" ]; then
            validCommand=true

            if ! echo "$input" | grep -Eq '^modexp[[:space:]][0-9]+$'; then
                validCommand=false
                echo -e "ERROR: The command syntax isn't correct. Please it like that: modexp <ammount of days from today>\n"
            fi

            if [[ "$validCommand" == "true" ]]; then
                ammDays=$(echo "$input" | awk -F ' ' '{print $2}')

                mapfile -t logFileSegmented < "$logFile"
                sizeOfFileArray="${#logFileSegmented[@]}"
                cursor=0

                while (( $cursor < $sizeOfFileArray )); do
                    currLine=$(echo "${logFileSegmented[$cursor]}")
                    if echo "$currLine" | grep -Eq 'Expiration date:.*'; then
                        echo "Found the line : '$currLine'"
                        break
                    fi
                    cursor=$((cursor + 1))
                done

                newExpirationDate=$(date +%d-%m-%Y -d "$(date) + $ammDays day")
                logFileSegmented[$cursor]=$(echo "Expiration date: $newExpirationDate")
                printf "%s\n" "${logFileSegmented[@]}">$logFile

                echo "$(date) Modified the expiration date with the command : modexp $ammDays" >> $logFile
            fi
        elif [ "$command" == "rmq" ]; then
            validCommand=true

            idOfQuestion=$(echo "$input" | awk -F ' ' '{print $2}')

            if [[ ! "$idOfQuestion" =~ ^[0-9]+$ ]]; then
                echo -e "ERROR: The question id '$idOfQuestion' is not a valid value.\n"
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
            fi

            if [[ $validCommand == true ]]; then
                ammountOfAnswers=0
                tempCursor=$((cursor + 1))

                # Look at how much answer the question have
                while (( $tempCursor < $sizeOfFileArray )); do
                    # echo "Got tempC=$tempCursor"
                    currLine=$(echo "${questionFileSegmented[$tempCursor]}" | awk -F '[' '{print $1}')
                    # echo "Got currLine=$currLine"
                    
                    if [[ "$currLine" == "na" ]]; then
                        ammountOfAnswers=$((ammountOfAnswers + 1))
                    else
                        break
                    fi

                    tempCursor=$((tempCursor + 1))
                done

                # echo "Found the ammount of answers = $ammountOfAnswers"
                # Moves all lines after the question to delete on top of it
                while (( "$cursor + $ammountOfAnswers" < $sizeOfFileArray )); do
                    nextIndex=$((cursor + ammountOfAnswers + 1))
                    # echo "Got cursor=$cursor/asw=$ammountOfAnswers/nextIndex=$nextIndex"
                    # echo "About to change : '${questionFileSegmented[$cursor]}' -> '${questionFileSegmented[$nextIndex]}'"
                    questionFileSegmented[$cursor]="${questionFileSegmented[$nextIndex]}"

                    cursor=$((cursor + 1))
                done

                # Save everything inside the file
                printf "%s\n" "${questionFileSegmented[@]}">$questionFile
                # Cut off the part that was moved but not overwritten
                sed -i "${cursor},\$d" "$questionFile"

                # TODO Maybe do whats written under
                # There is probably a better way to do that, by formating while overriding
                # the lines in the while loop above, but its almost 11 pm and can't be asked 
                # to find something like that 
                mapfile -t fileToFormat < "$questionFile"
                
                cursor=0
                currId=-1
                sizeOfFileArray="${#fileToFormat[@]}"
                while (( $cursor < $sizeOfFileArray )); do
                    currCommand=$(echo "${fileToFormat[$cursor]}" | awk -F '[' '{print $1}')

                    if [[ "$currCommand" == "nq" ]]; then
                        currId=$((currId + 1))
                    fi

                    fileToFormat[$cursor]=$(echo "${fileToFormat[$cursor]}" | awk -v newId="$currId" '{sub(/\[[0-9]+;/, "[" newId ";"); print;}')
                    cursor=$((cursor + 1))
                done

                printf "%s\n" "${fileToFormat[@]}">$questionFile
                
                echo "$(date) Removed a question with the command : rmq $idOfQuestion" >> $logFile
            else
                echo -e "ERROR: The question id wasn't found, please enter a valid question id.\n"
            fi


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

                    #Override the current file with the modified one
                    printf "%s\n" "${questionFileSegmented[@]}">$questionFile

                    echo "$(date) Removed a answer with the command : rma $idOfQuestion $idOfAnswer" >> $logFile
                fi
            fi
        else
            echo -e "ERROR : Command not found. Having trouble finding a command ? Try the 'help' command.\n"
        fi
    done
}