#!/bin/bash  

clone_collection() {
   REST_ENDPOINT=$1
   collection_name=$2
   read_token=$3
   echo $REST_ENDPOINT
   
   END_TIME=$EPOCHSECONDS
   #Date is rounded for days, so, we need to be at least one day ahead
   let "END_TIME=END_TIME+100000"
   
   rm /tmp/$collection_name.jq.json 
   
   # loop in intervals of 4 monthes.
   DELTA=10000000
   
   # loop until the time NS was created.
   while [ $END_TIME -gt 1325447430 ]
   do
       let "START_TIME=END_TIME-DELTA"
       
       START_TIME_STRING=$(date -d @$START_TIME +%Y-%m-%d)
       END_TIME_STRING=$(date -d @$END_TIME +%Y-%m-%d)
       echo $START_TIME_STRING $END_TIME_STRING
       
       if [[ $collection_name == entries ]]; then
           wget $REST_ENDPOINT/api/v1/$collection_name.json'?find[date][$gte]='$START_TIME'000&find[date][$lte]='$END_TIME'000&count=1000000'$read_token -O /tmp/$collection_name.json 
       else
           wget $REST_ENDPOINT/api/v1/$collection_name'.json?find[created_at][$gte]='$START_TIME_STRING'&find[created_at][$lte]='$END_TIME_STRING'&count=1000000'$read_token -O /tmp/$collection_name.json
       fi
       jq '.[]' /tmp/$collection_name.json >> /tmp/$collection_name.jq.json 
       let "END_TIME=END_TIME-DELTA"
    done
   mongoimport --uri "mongodb://username:password@localhost:27017/Nightscout" --mode=upsert --collection=$collection_name --file=/tmp/$collection_name.jq.json

}

clone_collections() {
    REST_ENDPOINT=$1  
	read_token=$2
    for collection in entries activity devicestatus food profile treatments;
    do echo cloning  "<$collection>"; 
    clone_collection $REST_ENDPOINT $collection $read_token
    done
}

# Try 5 times to get the user input.
for i in {1..5}
do
    read -rep "If you want to copy your old nightscout site, please state the name here"$'\n'"(for example: https://site.herokuapp.com). To skip presses enter."$'\n'"You will be able to run this in the future if needed. "$'\n'"site name: " rest_endpoint
    if [[ -z "$rest_endpoint" ]]
    then
        echo "No site selcted, exiting."
        exit
    fi
    #check if url ends with /, and if yes remove it.
    if [[ "$rest_endpoint" =~ '/'$ ]]; then 
        echo "yes"
        rest_endpoint=${rest_endpoint::-1}
    fi

    read -rep "If you have a read token, enter it now. For example: read-c9b67850b67acf82"$'\n'"If you don't know how to use a token press enter."$'\n'"read_token:" read_token
    if [[ ! -z "$read_token" ]]
    then
        echo "Token exists"
        read_token="&token="$read_token
    fi

    # do a sanity check before actually starting to copy.
    wget $rest_endpoint/api/v1/entries'.json?find[date][$gte]=1662845659&count=1'$read_token -O /tmp/entries.json
    ret_code=$?
    if [ ! $ret_code = 0 ]; then
        echo "Accesseing site " $rest_endpoint "failed, please try again, enter to skip."
        continue;
     fi

     echo Starting to copy $rest_endpoint
     clone_collections $rest_endpoint $read_token
     # Add log
     rm -rf /tmp/Logs
     echo -e "Data copied from another Nightscout     $(date)\n" | cat - /xDrip/Logs > /tmp/Logs
     sudo /bin/cp -f /tmp/Logs /xDrip/Logs
     exit 0
   
done
 
