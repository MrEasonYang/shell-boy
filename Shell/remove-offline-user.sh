#! /bin/bash

for user_pts in $(who|awk '{print $2}')
do
    pkill -kill -t $user_pts
    echo $user_pts 'has been killed'
done
