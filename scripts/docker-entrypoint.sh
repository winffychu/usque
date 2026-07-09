#!/bin/sh
# 不修改 /app/usque 源码。首次无 config 则自动注册，然后 exec /app/usque。
set -eu

register_if_needed() {
    [ -f "$USQUE_CONFIG_PATH" ] && return 0
    echo "[*] 自动注册中..."
    config_dir=$(dirname "$USQUE_CONFIG_PATH")
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir" 2>/dev/null || true
    fi
    cmd="/app/usque register --config $USQUE_CONFIG_PATH"
    cmd="$cmd --locale ${USQUE_LOCALE:-en_US} --model ${USQUE_MODEL:-PC} --name ${USQUE_DEVICE_NAME:-$(hostname)}"
    [ "${USQUE_ACCEPT_TOS:-true}" = "true" ] && cmd="$cmd --accept-tos"
    [ -n "${USQUE_JWT:-}" ] && cmd="$cmd --jwt $USQUE_JWT"
    eval "$cmd" || { echo "[E] 注册失败"; exit 1; }
    [ -f "$USQUE_CONFIG_PATH" ] || { echo "[E] 未生成配置文件"; exit 1; }
    echo "[✓] 注册完成"
}

main() {
    case "${1:-}" in
        help|--help|-h)
            echo "用法: entrypoint.sh <command> [args]"
            echo "命令: socks|http|tunnel|l4-http|l4-socks|portfw|register"
            exit 0 ;;
        register)  shift; exec "/app/usque" register "$@" ;;
        version|--version|-v) exec "/app/usque" version ;;
    esac
    [ -x "/app/usque" ] || { echo "[E] 找不到 /app/usque"; exit 1; }
    register_if_needed
    exec "/app/usque" --config "$USQUE_CONFIG_PATH" "${@:-socks}"
}

main "$@"
