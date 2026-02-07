#!/bin/bash
# 跨平台系统通知脚本
# 使用自定义 MP3 文件
# 支持场景：stop (对话结束), permission (权限请求)

set -e

# 获取场景参数
SCENE="${1:-stop}"

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macOS" ;;
        Linux*)     echo "Linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "Windows" ;;
        *)          echo "Unknown" ;;
    esac
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 获取自定义 MP3 文件路径
get_custom_sound_file() {
    local custom_file

    # 根据场景选择不同的音效
    case "$SCENE" in
        permission)
            # 权限请求使用 confirm.mp3
            custom_file="$PLUGIN_ROOT/assets/sounds/confirm.mp3"
            ;;
        stop|*)
            # 默认/对话结束使用原来的音效
            custom_file="$PLUGIN_ROOT/assets/sounds/freesound_community-goodresult-82807.mp3"
            ;;
    esac

    if [ -f "$custom_file" ]; then
        echo "$custom_file"
        return 0
    else
        echo "警告：自定义音效文件不存在: $custom_file" >&2
        return 1
    fi
}

# 播放自定义 MP3 文件
play_custom_sound() {
    local sound_file="$1"

    if [ -z "$sound_file" ] || [ ! -f "$sound_file" ]; then
        echo "错误：音效文件不存在或未指定" >&2
        return 1
    fi

    echo "播放自定义音效: $(basename "$sound_file")" >&2

    local os=$(detect_os)
    case "$os" in
        macOS)
            if command -v afplay >/dev/null 2>&1; then
                afplay "$sound_file" &
                return 0
            else
                echo "错误：afplay 不可用" >&2
                return 1
            fi
            ;;
        Linux)
            # 尝试多种播放器
            if command -v mpv >/dev/null 2>&1; then
                mpv --no-video --really-quiet "$sound_file" &
                return 0
            elif command -v mplayer >/dev/null 2>&1; then
                mplayer -really-quiet "$sound_file" 2>/dev/null &
                return 0
            elif command -v paplay >/dev/null 2>&1; then
                paplay "$sound_file" &
                return 0
            elif command -v aplay >/dev/null 2>&1; then
                aplay "$sound_file" 2>/dev/null &
                return 0
            else
                echo "错误：未找到可用的音频播放器" >&2
                return 1
            fi
            ;;
        Windows)
            # Windows 使用 PowerShell 播放
            if command -v powershell >/dev/null 2>&1; then
                powershell -Command "\$player = New-Object System.Media.SoundPlayer; \$player.SoundLocation = '$sound_file'; \$player.Play()" &
                return 0
            else
                echo "错误：PowerShell 不可用" >&2
                return 1
            fi
            ;;
        *)
            echo "错误：不支持的操作系统" >&2
            return 1
            ;;
    esac
}

# 播放系统默认通知（降级方案）
play_system_notification() {
    local os=$(detect_os)

    case "$os" in
        macOS)
            # macOS 系统通知
            osascript -e 'display notification "任务已完成" with title "Claude Code" sound name "Glass"'
            ;;
        Linux)
            # Linux 系统通知（需要 notify-send）
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Claude Code" "任务已完成"
            fi
            # 终端响铃
            echo -e "\a"
            ;;
        Windows)
            # Windows 终端响铃
            echo -e "\a"
            ;;
        *)
            # 通用终端响铃
            echo -e "\a"
            ;;
    esac
}

# 主播放函数
play_notification() {
    echo "播放通知 [场景: $SCENE]..." >&2

    # 首先尝试播放自定义 MP3
    local custom_file=$(get_custom_sound_file)
    if [ -n "$custom_file" ] && play_custom_sound "$custom_file"; then
        echo "自定义音效播放成功: $(basename "$custom_file")" >&2
        return 0
    fi

    # 如果自定义音效失败，使用系统通知
    echo "使用系统通知作为降级方案" >&2
    play_system_notification
}

echo "播放系统通知..." >&2

# 直接调用播放函数（函数已在当前 shell 中定义）
play_notification

exit 0