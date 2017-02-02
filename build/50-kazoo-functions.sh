# FIXES

function get-ipv4 {
    local interface="${1:-eth0}"
    if linux::cmd::exists 'ip'; then
        ip -o -f inet addr show $interface | sed 's/.*inet \(.*\)\/.*/\1/'
    elif linux::cmd::exists 'ifconfig'; then
        ifconfig $interface | grep 'inet ' | cut -d':' -f2 | awk '{print $1}'
    elif linux::cmd::exists 'hostname'; then
        hostname -i | head -1
    fi
}

function kazoo::build-amqp-uri-list {
    local list="$1"
    local label="${2:-amqp_uri}"
    local prefix='amqp'
    local uris=($(kazoo::build-amqp-uris "$list" "$prefix"))
    local hosts
    local host
    for host in "${uris[@]}"; do
        hosts+="$label = \"$host\"\n"
    done
    echo -e "$hosts" | head -n -1
}
