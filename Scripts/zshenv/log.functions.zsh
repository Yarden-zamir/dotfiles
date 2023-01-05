function +(){
    dir=~/logs/$(date +"%Y/%m")
    mkdir -p $dir
    file=$dir/$(date +"%d").log
    time_stamp=$(date +"%H:%M")
    echo $time_stamp : $@ >> $file
}
function ++(){
    dir=~/logs/$(date +"%Y/%m")
    file=$dir/$(date +"%d").log
    cat $file
}
function +++(){
    dir=~/logs/$(date +"%Y/%m")
    file=$dir/$(date +"%d").log
    code $file
}