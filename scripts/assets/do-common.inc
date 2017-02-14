: ${ACCOUNT:=test}
: ${REALM:=localhost}
: ${ADMIN_USER:=admin}
: ${ADMIN_PASS:=secret}
: ${LANGUAGE:=en-us}
: ${MEDIA_PATH:=/opt/kazoo/media/prompts/en/us}
: ${KAPPS_PATH:=/var/www/html/monster-ui/apps}
: ${CROSSBAR_URI:=http://$HOST:8000/v2}


function test {
	sup kapps_controller list_apps
}

function create-master-account {
	sup crossbar_maintenance create_account $ACCOUNT $REALM $ADMIN_USER $ADMIN_PASS
}

function load-media {
	sup kazoo_media_maintenance import_prompts $MEDIA_PATH $LANGUAGE
}

function init-apps {
	sup crossbar_maintenance init_apps $KAPPS_PATH $CROSSBAR_URI
}

function add-fs-node {
	sup ecallmgr_maintenance add_fs_node freeswitch@$FREESWITCH_HOST
}

function allow-sbc {
	sup ecallmgr_maintenance allow_sbc $KAMAILIO_HOST $KAMAILIO_IP
}

function get-master-account {
	sup crossbar_maintenance find_account_by_name $ACCOUNT
}

if [[ $1 ]]; then
    "$@"
else
    echo "usage: $(basename $0) {sup|test|create-master-acccount|load-media|init-apps|add-fs-node|allow-sbc|get-master-account}"
    exit 1
fi
