#!/bin/bash

readonly SHARED_FOLDER=("/home/chino/Desktop/Project/L3SystemesEtReseaux/proj/FakeSharedEnv/")

# Create a function for modifying previous answers

aswVoteEnv(){
    # There isn't any verification for what is given into the idOfVote
    # Because it SHOULDN'T BE anything else than a int
    local idOfVote="$1"

    # Save the path to the folder inside questionFolder and verify if it exist
    questionFolder=("$SHARED_FOLDER/Vote-$idOfVote")
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

    # Save the Questions.txt content inside a array
    readarray -t fileArray < "$questionFile"
    sizeOfFileArray="${#fileArray[@]}"
    cursor=0

    echo -e "Got the amm of line of the array: $sizeOfFileArray"

    echo -e "\n------ Entering KBJA-rep Environment ------"

    # currLine=$(echo "${fileArray[$cursor]}" | awk -F '[' '{print $2}' | awk -F ']' '{print $1}')
    # isMultChoice=$(echo "$currLine" | awk -F ';' '{print $3}')
    # currIndex=$(echo "$currLine" | awk -F ';' '{print $1}')
    # oldIndex=$((currIndex))

    # echo -e "Got the information\ncurrLine=$currLine\ncurrIndex=$currIndex\noldIndex=$oldIndex\n" 

    answersArray=()
    answersArrayCursor=0
    while (( $cursor < $sizeOfFileArray )); do
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

        # oldIndex=$((currIndex))
    
        # cursor=$((cursor + 1))
        read -p "KBJA-asw> Answer: " input
        
        # TODO Verify if the input is correct and save it inside Answers.txt
        answersArray[answersArrayCursor]=$(echo "asw[$oldIndex;$input]")
        answersArrayCursor=$((answersArrayCursor + 1))
    done

    echo -e "\n\nGot the answers:"
    for list in "${answersArray[@]}"
    do
        for item in $list
        do
            echo $item
        done
    done



    # while true; do
    #     read -p "KBJA-asw> " input
    #     command=$(echo "$input" | awk '{print $1}')

    #     if [ "$command" = "exit" ]; then
    #         echo -e "------ Exited successfully from KBJA-asw Environment ------\n"
    #         break;
    #     else
    #          echo -e "ERROR : Command not found. Having trouble finding a command ? Try the 'help' command.\n"
    #     fi
    # done

    # while IFS= read -r readLine; do
    #     information=(echo "$readLine" | awk '[' '{print $2}')
    #     currentId=(echo "$information" | awk ';' '{print $1}')
    #     oldId=$((currentId))
    #     readQuestionAnswers "$information"

    #     while ( old)

    #     echo "Line: $line"
    # done < $QuestionFile
}
