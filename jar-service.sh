# ----------------------
# @name      jar-service
# @author    jiangKlijna
# ----------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Match command
case "$1" in
    install)
        jar_service_install "$2"
        ;;
    remove)
        jar_service_remove "$2"
        ;;
    regist)
        jar_service_regist "$2"
        ;;
    unreg)
        jar_service_unreg "$2"
        ;;
    start)
        jar_service_start "$2"
        ;;
    stop)
        jar_service_stop "$2"
        ;;
    reboot)
        jar_service_reboot "$2"
        ;;
    *)
        echo_usage
        ;;
esac

cd "$SCRIPT_DIR"
exit 0

# [install] unzip jar_file to jar_dir
jar_service_install() {
    local jar_file="$1"
    local jar_file_path="$(dirname "$jar_file")"
    local jar_name="$(basename "$jar_file" .jar)"
    local jar_suffix=".jar"

    cd "$jar_file_path"

    # Delete existing directory
    if [ -d "$jar_name" ]; then
        rm -rf "$jar_name"
    fi

    # Create directory and move jar
    mkdir -p "$jar_name"
    mv "$jar_file" "$jar_name/"

    cd "$jar_name"

    # Unzip jar
    if command -v unzip &> /dev/null; then
        unzip -q "$jar_name$jar_suffix"
    elif command -v jar &> /dev/null; then
        jar -xf "$jar_name$jar_suffix"
    fi
    mv "$jar_name$jar_suffix" ../

    # Get main class
    local main_class
    main_class=$(get_jar_main_class "$jar_file_path/$jar_name")

    echo "jar_dir is $PWD"
    echo "start cmd is $(get_java) -cp \"$PWD\" $main_class"

    # Create startup script
    echo "$(get_java) -cp \"$PWD\" $main_class" > "$PWD/startup.sh"
    chmod +x "$PWD/startup.sh"

    echo "install success!"
}

# [remove] delete jar_dir
jar_service_remove() {
    local jar_file="$1"
    local jar_file_path="$(dirname "$jar_file")"
    local jar_name="$(basename "$jar_file" .jar)"

    cd "$jar_file_path"

    if [ -d "$jar_name" ]; then
        rm -rf "$jar_name"
    fi

    echo "remove success!"
}

# [regist] regist system service (systemd)
jar_service_regist() {
    local jar_dir="$1"
    local jar_dir_path="$(cd "$1" && pwd)"
    local jar_dir_name="$(basename "$jar_dir_path")"
    local service_name="jar-service-$jar_dir_name"

    echo "ServiceName set $service_name"
    echo "JarDir set $jar_dir_path"

    local main_class
    main_class=$(get_jar_main_class "$jar_dir_path")
    echo "MainClass set $main_class"

    # Create systemd service file
    local service_file="/etc/systemd/system/${service_name}.service"

    if [ -f "$service_file" ]; then
        echo "Service $service_name already exists"
        return 1
    fi

    cat > "$service_file" << EOF
[Unit]
Description=Jar Service - $jar_dir_name
After=network.target

[Service]
Type=simple
WorkingDirectory=$jar_dir_path
ExecStart=$(get_java) -cp "$jar_dir_path" $main_class
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "$service_name"

    echo "regist system service success!"
}

# [unreg] unregist system service
jar_service_unreg() {
    local jar_dir="$1"
    local jar_dir_name="$(basename "$jar_dir")"
    local service_name="jar-service-$jar_dir_name"

    echo "delete $service_name"

    systemctl stop "$service_name" 2>/dev/null
    systemctl disable "$service_name" 2>/dev/null
    rm -f "/etc/systemd/system/${service_name}.service"
    systemctl daemon-reload

    echo "unreg success!"
}

# [start] service
jar_service_start() {
    local jar_dir="$1"
    local jar_dir_name="$(basename "$jar_dir")"
    local service_name="jar-service-$jar_dir_name"

    echo "start $service_name"
    systemctl start "$service_name"
}

# [stop] service
jar_service_stop() {
    local jar_dir="$1"
    local jar_dir_name="$(basename "$jar_dir")"
    local service_name="jar-service-$jar_dir_name"

    echo "stop $service_name"
    systemctl stop "$service_name"
}

# [reboot] service
jar_service_reboot() {
    jar_service_stop "$1"
    jar_service_start "$1"
}

# [get_java] get java command
get_java() {
    if [ -n "$JAVA_HOME" ]; then
        echo "$JAVA_HOME/bin/java"
    else
        echo "java"
    fi
}

# [get_jar_cmd] get jar command
get_jar_cmd() {
    if [ -n "$JAVA_HOME" ]; then
        echo "$JAVA_HOME/bin/jar"
    else
        echo "jar"
    fi
}

# [get_jar_main_class] get Main-Class from META-INF/MANIFEST.MF
get_jar_main_class() {
    local jar_dir="$1"
    local manifest_path="$jar_dir/META-INF/MANIFEST.MF"

    if [ ! -f "$manifest_path" ]; then
        echo "$manifest_path Not Found Main-Class"
        return 1
    fi

    local main_class
    main_class=$(grep "Main-Class:" "$manifest_path" | sed 's/.*Main-Class: *//' | tr -d '\r')

    if [ -z "$main_class" ]; then
        echo "$manifest_path Not Found Main-Class"
        return 1
    fi

    echo "$main_class"
}

# [echo_usage]
echo_usage() {
    echo "jar-service 0.1"
    echo "Usage:"
    echo "    jar-service install  xxx.jar"
    echo "    jar-service remove  xxx.jar"
    echo "    jar-service regist jar_dir"
    echo "    jar-service unreg  jar_dir"
    echo "    jar-service start  jar_dir"
    echo "    jar-service stop   jar_dir"
    echo "    jar-service reboot jar_dir"
}
