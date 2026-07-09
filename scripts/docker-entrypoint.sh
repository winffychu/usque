#!/bin/bash
# 不修改 usque 源码。首次无 config 则自动注册，然后 exec usque。
set -euo pipefail

register_if_needed() {
    [ -f "$USQUE_CONFIG_PATH" ] && return 0
    echo "[*] 自动注册中..."
    local cmd=("$USQUE_BINARY" register --config "$USQUE_CONFIG_PATH"
        --locale "${USQUE_LOCALE:-en_US}" --model "${USQUE_MODEL:-PC}"
        --name "${USQUE_DEVICE_NAME:-$(hostname)}")
    [ "${USQUE_ACCEPT_TOS:-true}" = "true" ] && cmd+=(--accept-tos)
    [ -n "${USQUE_JWT:-}" ] && cmd+=(--jwt "$USQUE_JWT")
    "${cmd[@]}" || { echo "[E] 注册失败"; exit 1; }
    [ -f "$USQUE_CONFIG_PATH" ] || { echo "[E] 未生成配置文件"; exit 1; }
    echo "[✓] 注册完成"
}

main() {
    case "${1:-}" in
        help|--help|-h)
            echo "用法: entrypoint.sh <command> [args]"
            echo "命令: socks|http|tunnel|l4-http|l4-socks|portfw|register"
            echo "环境变量: USQUE_CONFIG_PATH USQUE_BINARY USQUE_LOCALE USQUE_MODEL USQUE_DEVICE_NAME USQUE_ACCEPT_TOS USQUE_JWT"
            exit 0 ;;
        register)  shift; exec "$USQUE_BINARY" register "$@" ;;
        version|--version|-v) exec "$USQUE_BINARY" version ;;
    esac
    [ -x "$USQUE_BINARY" ] || { echo "[E] 找不到 $USQUE_BINARY"; exit 1; }
    register_if_needed
    exec "$USQUE_BINARY" --config "$USQUE_CONFIG_PATH" "${@:-socks}"
}

main "$@"