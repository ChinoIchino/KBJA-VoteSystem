#!/bin/bash

# TODO Create a function for modifying previous answers

# Needed to call it something else than SHARED_FOLDER, because the var name is already used inside editvote.sh
readonly SHARED_FOLDER_REP=("/home/chino/Desktop/Project/L3SystemesEtReseaux/proj/FakeSharedEnv/")

# If the user quit abruptly inside the answer environment, it send him back to the main one
repSafeExit(){
    echo -e "\nDETECTED NON-SAFE EXIT\nAll responses given won't be saved\n"
    echo "$(date) $HOSTNAME : Quit abruptly, his answers weren't saved" >> $logFile
}

# Append a new vote
repVoteEnv(){
    trap 'repSafeExit; return' INT TERM

    # There isn't any verification for what is given into the idOfVote
    # Because it SHOULDN'T BE anything else than a int
    local idOfVote="$1"

    local offset="$2"
    echo "Got offset='$offset'"

    # Save the path to the folder inside questionFolder and verify if it exist
    questionFolder=("$SHARED_FOLDER_REP/Vote-$idOfVote")
    if [ ! -e "$questionFolder" ]; then
        echo -e "ERROR: Vote unavailable. Id[$idOfVote] wasn't found\n"
        return
    fi

    # Save the path to the questions file and verify if it exist
    questionFile=("$questionFolder/Questions.txt")
    if [ ! -e "$questionFile" ]; then
        echo -e "ERROR: Vote unavailable. The vote id[$idOfVote] doesn't contain any questions.\n"
        return
    fi

    logFile=("$questionFolder/Info.log")

    if [[ "$offset" == "" ]]; then
        echo "$(date) $HOSTNAME : Started answering the vote" >> $logFile
    else
        echo "$(date) $HOSTNAME : Started modifying his answers" >> $logFile
    fi

    # Save the Questions.txt content inside a array
    readarray -t fileArray < "$questionFile"
    sizeOfFileArray="${#fileArray[@]}"
    cursor=0

    echo -e "Got the amm of line of the array: $sizeOfFileArray"

    echo -e "\n------ Entering KBJA-rep Environment ------"

    answersArray=()
    answersArrayCursor=0
    while (( $cursor < $sizeOfFileArray )); do
        if [[ $forceQuit == true ]]; then
            return;
        fi

        # Get the question line
        currLine=$(echo "${fileArray[$cursor]}" | awk -F '[' '{print $2}' | awk -F ']' '{print $1}')
        
        # Get the attributs of the question 
        isMultChoice=$(echo "$currLine" | awk -F ';' '{print $3}')
        currIndex=$(echo "$currLine" | awk -F ';' '{print $1}')
        currText=$(echo "$currLine" | awk -F ';' '{print $2}')
        
        # Update the oldIndex
        oldIndex=$((currIndex))

        if (( isMultChoice == 1 )); then
            echo -e "\n$currText (Might have multiple answers):"
        else
            echo -e "\n$currText"
        fi

        cursor=$((cursor + 1))
        answerNumber=1
        
        currLine=$(echo "${fileArray[$cursor]}" | awk -F '[' '{print $2}' | awk -F ']' '{print $1}')
        currIndex=$(echo "$currLine" | awk -F ';' '{print $1}')
        while (( $oldIndex == $currIndex )); do
            currAnswer=$(echo "$currLine" | awk -F ';' '{print $2}')
            
            echo "$answerNumber: $currAnswer"

            answerNumber=$((answerNumber + 1))
            cursor=$((cursor + 1))

            # A verification so that the variable currLine doesn't get incremented
            # when its the last answer of the entire file
            if (( $cursor >= $sizeOfFileArray )); then
                break;
            fi

            currLine=$(echo "${fileArray[$cursor]}" | awk -F '[' '{print $2}' | awk -F ']' '{print $1}')
            currIndex=$(echo "$currLine" | awk -F ';' '{print $1}')
        done

        read -p "KBJA-asw> Answer: " input
        
        # Verify if the current response is conform
        if [[ $isMultChoice == 1 ]]; then
            mapfile -t segmentedResponses < <(echo "$input" | awk -F ' ' '{for(i=1; i<=NF; i++) print $i}')
            newChoices=()

            # Goes by every responses given for the question
            for currInput in "${segmentedResponses[@]}"; do
                # echo "CurrInput : $currInput"
                validAnswer=true

                # Verify if the current answer is a number and the number is a valid answer
                if [[ $currInput =~ ^[0-9]+$ ]] && (( $currInput > 0 && $currInput < $answerNumber )); then
                    # Verify if the answer was not already stored
                    for currItem in "${newChoices[@]}"; do
                        if [[ "$currItem" == "$currInput" ]]; then
                            validAnswer=$((false))
                            break
                        fi
                    done
                else
                    validAnswer=$((false))
                fi


                # If its a new valid answer it goes into the answers
                if [[ $validAnswer == true ]]; then
                    # TODO delete those prints in final release
                    # I'm keeping this print just in case
                    # echo -e "No duplicates were found, adding it into the choices\ncurrItem=$currInput"
                    newChoices+=("$currInput")
                fi
            done

            # If there is at least one valid choice
            if [[ "${#newChoices[@]}" -ge 1 ]]; then
                # Save all the answers into the "asw[questionId;<All the answers>]" format
                answersArray[answersArrayCursor]=$(echo "asw[$oldIndex;")
                for chosenItem in "${newChoices[@]}"; do
                    answersArray[answersArrayCursor]+=$(echo "$chosenItem ")
                done
                answersArray[answersArrayCursor]+="]"

                answersArrayCursor=$((answersArrayCursor + 1))
            else
                echo "It isn't a correct answer! Please use spaces between multiple answers"

                # Goes back to the un-answered question
                answerNumber=$((answerNumber - 1))
                cursor=$((cursor - 1 - $answerNumber))
            fi
        else
            if [[ $input =~ ^[0-9]+$ ]] && (( input > 0 && input < $answerNumber )); then
                answersArray[answersArrayCursor]=$(echo "asw[$oldIndex;$input]")
                answersArrayCursor=$((answersArrayCursor + 1))
            else
                echo "It isn't a correct answer!"

                # Goes back to the un-answered question
                answerNumber=$((answerNumber - 1))
                cursor=$((cursor - 1 - $answerNumber))
            fi
        fi
    done


    echo "$(date) $HOSTNAME : Finished answering all the questions" >> $logFile
    
    # TODO Delete all comments below in final product
    # Used to verify what will be saved inside the Answers.txt
    # echo -e "\n\nGot the answers:"
    # for index in $(seq 0 $((answersArrayCursor))); do
    #     echo "${answersArray[$index]}"
    # done
    
    # Save all the answers inside Answers.txt
    answersFile=("$questionFolder/Answers.txt")

    # If a offset wasn't given, then its the first time the user is answering to the vote
    if [[ "$offset" == "" ]]; then
        echo -e "newasw[$HOSTNAME]" >> $answersFile
        for index in $(seq 0 $((answersArrayCursor - 1))); do
            echo -n -e "${answersArray[$index]}\n" >> $answersFile
        done
    else
        # Taking the content of the Answers.txt file
        aswFileContent=$(less $answersFile)
        # Segmenting it into a array
        mapfile -t aswFileSegmented < <(echo "$aswFileContent" | awk -F '\n' '{for(i=1; i<=NF; i++) print $i}')

        for index in $(seq 0 $((answersArrayCursor - 1))); do
            offset=$((offset + 1))
            aswFileSegmented[$offset]="${answersArray[$index]}"
        done
        # Needed to use a printf because i would have been searching a alternative for a eternity
        printf "%s\n" "${aswFileSegmented[@]}">$answersFile
    fi

    echo -e "All the question have been answered\n------ Exited successfully from KBJA-asw environment ------\n"

}

# Verify if the user have already responded to the vote or no.
# Both possibility will call repVoteEnv() after verifying.
# If the user had already registered answers to the vote, the new responses will override the old ones.
repVoteEnvMod(){
    local idOfVote="$1"

    # Save the path to the folder inside questionFolder and verify if it exist
    questionFolder=("$SHARED_FOLDER_REP/Vote-$idOfVote")
    if [ ! -e "$questionFolder" ]; then
        echo -e "ERROR: Vote unavailable. Id[$idOfVote] wasn't found\n"
        return
    fi

    # Save the path to the questions file and verify if it exist
    questionFile=("$questionFolder/Questions.txt")
    if [ ! -e "$questionFile" ]; then
        echo -e "ERROR: Vote unavailable. The vote id[$idOfVote] doesn't contain any questions.\n"
        return
    fi

    # Save the path to the answers file and verify if it exist
    answersFile=("$questionFolder/Answers.txt")
    if [ ! -e "$answersFile" ]; then
        repVoteEnv "$idOfVote"
        return
    fi

    readarray -t fileArray < "$answersFile"
    sizeOfFileArray="${#fileArray[@]}"
    cursor=0

    while (( $cursor < $sizeOfFileArray )); do
        currLine=$(echo "${fileArray[$cursor]}" | awk -F '[' '{print $1}')
        if [[ "$currLine" == "newasw" ]]; then
            currUser=$(echo "${fileArray[$cursor]}" | awk -F '[' '{print $2}' | awk -F ']' '{print $1}')
            # echo "About to compare $currUser == $HOSTNAME"
            if [[ "$currUser" == "$HOSTNAME" ]]; then
                break
            fi
        fi
        cursor=$((cursor + 1))
    done

    if [[ "$cursor" == "$sizeOfFileArray" ]]; then
        repVoteEnv "$idOfVote"
    else
        echo "You have already answered this vote, the new answers will override the old ones."
        repVoteEnv "$idOfVote" "$cursor"
    fi
}
