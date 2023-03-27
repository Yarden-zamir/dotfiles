log_file_type="log"
function +(){
    dir=~/logs/$(date +"%Y/%m")
    mkdir -p $dir
    file=$dir/$(date +"%d").$log_file_type
    time_stamp=$(date +"%H:%M")
    echo "$time_stamp : $@" >> $file
}
function ++(){
    dir=~/logs/$(date +"%Y/%m")
    file=$dir/$(date +"%d").$log_file_type
    cat $file
}
function +++(){
    dir=~/logs/$(date +"%Y/%m")
    file=$dir/$(date +"%d").$log_file_type
    code $dir
    code $file
}