#!/bin/bash
# 声音测试脚本 - 帮助诊断声音问题

set -e

echo "🔊 声音问题诊断工具"
echo "==================="
echo

# 检测操作系统
OS="$(uname -s)"
echo "操作系统: $OS"
echo

if [ "$OS" = "Darwin" ]; then
    echo "=== macOS 声音测试 ==="
    echo

    # 检查 afplay
    if command -v afplay >/dev/null 2>&1; then
        echo "✅ afplay 可用: $(which afplay)"
    else
        echo "❌ afplay 不可用"
    fi

    echo
    echo "1. 测试系统音效文件..."
    SOUND_FILES=(
        "/System/Library/Sounds/Glass.aiff"
        "/System/Library/Sounds/Ping.aiff"
        "/System/Library/Sounds/Pop.aiff"
        "/System/Library/Sounds/Basso.aiff"
        "/System/Library/Sounds/Tink.aiff"
        "/System/Library/Sounds/Purr.aiff"
    )

    for sound_file in "${SOUND_FILES[@]}"; do
        if [ -f "$sound_file" ]; then
            echo "   ✅ $(basename "$sound_file") 存在"
        else
            echo "   ❌ $(basename "$sound_file") 不存在"
        fi
    done

    echo
    echo "2. 测试系统通知音效..."
    echo "   即将测试不同音效，请听是否有声音："
    SOUND_NAMES=("Glass" "Default" "Ping" "Pop" "Basso" "Tink" "Purr")

    for i in "${!SOUND_NAMES[@]}"; do
        sound_name="${SOUND_NAMES[$i]}"
        echo "   [$((i+1))] 测试音效: $sound_name"
        osascript -e "display notification \"测试音效: $sound_name\" with title \"声音测试\" sound name \"$sound_name\"" &
        sleep 1  # 给时间听到声音
    done

    echo
    echo "3. 测试直接播放音效文件..."
    if command -v afplay >/dev/null 2>&1; then
        TEST_SOUND="/System/Library/Sounds/Glass.aiff"
        if [ -f "$TEST_SOUND" ]; then
            echo "   播放 Glass.aiff (3秒后开始)..."
            sleep 3
            afplay "$TEST_SOUND"
            echo "   ✅ 直接播放完成"
        else
            echo "   ❌ 音效文件不存在: $TEST_SOUND"
        fi
    else
        echo "   ❌ afplay 不可用，跳过直接播放测试"
    fi

    echo
    echo "4. 检查系统声音设置..."
    echo "   当前音量设置:"
    osascript -e "get volume settings"
    echo
    echo "   输出格式: 输出音量 | 输入音量 | 提示音音量 | 是否静音"
    echo

    echo "5. 终端响铃测试..."
    echo -e "   终端响铃测试: \a"
    echo "   应该听到 '哔' 声"

elif [ "$OS" = "Linux" ]; then
    echo "=== Linux 声音测试 ==="
    echo
    echo "1. 测试终端响铃..."
    echo -e "   终端响铃: \a"
    echo
    echo "2. 测试桌面通知..."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "声音测试" "Linux 通知测试"
        echo "✅ 桌面通知已发送"
    else
        echo "⚠ notify-send 不可用，安装: sudo apt-get install libnotify-bin"
    fi

elif [[ "$OS" =~ "MINGW" || "$OS" =~ "CYGWIN" || "$OS" =~ "MSYS" ]]; then
    echo "=== Windows 声音测试 ==="
    echo
    echo "1. 测试终端响铃..."
    echo -e "   终端响铃: \a"
    echo "   应该听到 '哔' 声"

else
    echo "=== 未知操作系统 ==="
    echo
    echo "1. 测试终端响铃..."
    echo -e "   终端响铃: \a"
fi

echo
echo "=== 测试结果分析 ==="
echo
echo "如果听不到系统通知声音，可能原因："
echo "1. 系统声音被静音或音量太低"
echo "2. 通知声音被单独禁用"
echo "3. 系统音效文件缺失或损坏"
echo
echo "macOS 建议："
echo "1. 检查系统设置 > 声音 > 提示音音量"
echo "2. 检查系统设置 > 通知 > 确保允许播放声音"
echo "3. 尝试在脚本中使用不同的音效名称"
echo
echo "增强方案："
echo "1. 已修改插件脚本，会尝试多种音效"
echo "2. 同时使用直接播放和系统通知"
echo "3. 确保终端响铃作为最后手段"

echo
echo "🔧 要启用更可靠的声音，建议："
echo "1. 确保系统声音设置正确"
echo "2. 在系统设置中测试通知声音"
echo "3. 如果仍然无效，可以考虑使用自定义音频文件"