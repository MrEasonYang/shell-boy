#! /bin/bash

latest_version=
distribution=
current_version=

get_shell_config() {
    IFS=';'$'\n'
    local config=($(cat auto-chacha20-config))
    local line
    for item in ${config[@]}
    do
        IFS=:
        line=($item)
        case ${line[0]} in
            current-version)
                current_version=${line[1]}
                ;;
        esac
    done
    IFS=$' \t\n'
}

check() {
    local version_data=$(curl -s https://download.libsodium.org/libsodium/releases/ | awk -F '"' '/libsodium/{print $2}' | grep 'tar.gz$'  | awk -F '-' '{print $2}' | awk -F '.' '{printf("%d.%d.%d\n", $1, $2, $3)}')
    local factor
    local array
    local count
    for item in $version_data
    do
        IFS=.
        array=($item)
        IFS=$' \t\n'
        count=0
        factor=1000000
        declare -a data
        for number in ${array[@]}
        do
            count=`expr $count + $(( 10#$number )) \* $factor`
            data+=($count)
            factor=`expr $factor / 1000`
        done
    done
    get_latest_version $data
}

get_latest_version() {
    declare -a sorted_data
    sorted_data=($(for item in ${data[@]}; do echo $item; done | sort -nur))
    version_data=${sorted_data[0]}
    local right=`expr $version_data % 1000`
    local middle=`expr $version_data / 1000 % 1000`
    local left=`expr $version_data / 1000000`
    latest_version="$left.$middle.$right"
}

yum-dependence() {
    yum -y update
    yum -y install m2crypto gcc make
}

apt-dependence() {
    apt-get -y update
    apt-get -y install gcc build-essential python-m2crypto
}

check_distribution() {
    if cat /etc/*release|grep -q -i centos;then
        return 1
    elif cat /etc/*release|grep -q -i rhel;then
        return 1
    elif cat /etc/*release|grep -q -i ubuntu;then
        return 0
    elif cat /etc/*release|grep -q -i debian;then
        return 0
    fi
}

init_environment() {
    if [ 1 -eq $distribution ];then
        yum-dependence
    elif [ 0 -eq $distribution ];then
        apt-dependence
    fi
}

install() {
    curl -s https://download.libsodium.org/libsodium/releases/libsodium-$latest_version.tar.gz -o libsodium.tar.gz
    tar -zvxf libsodium.tar.gz
    cd libsodium-$latest_version
    ./configure
    make && make install
    echo "include ld.so.conf.d/*.conf" > /etc/ld.so.conf
    echo "/lib" >> /etc/ld.so.conf
    echo "/usr/lib64" >> /etc/ld.so.conf
    echo "/usr/local/lib" >> /etc/ld.so.conf
    ldconfig
    cd ..
    rm libsodium.tar.gz
    rm -rf libsodium-$latest_version
    sed -i 's/current-version:.*;/current-version:'$latest_version';/g' ./auto-chacha20-config
}

get_shell_config
check
if [ "$latest_version" != "$current_version" ];then
    check_distribution
    distribution=$?
    init_environment
    install
fi
