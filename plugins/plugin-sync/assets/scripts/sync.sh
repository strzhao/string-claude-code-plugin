#!/bin/bash
# Claude Code 插件跨模型同步脚本
# 当检测到模型切换或新插件安装时，自动同步插件配置

set -e

# 配置
CLAUDE_ROOT="${HOME}/.claude"
SHARED_PLUGINS_DIR="${CLAUDE_ROOT}/.shared-plugins"
CONFIG_BACKUP_DIR="${CLAUDE_ROOT}/.plugin-config-backups"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 创建共享目录结构
init_shared_directory() {
    log_info "初始化共享插件目录..."

    mkdir -p "${SHARED_PLUGINS_DIR}"
    mkdir -p "${CONFIG_BACKUP_DIR}"

    # 创建子目录结构
    mkdir -p "${SHARED_PLUGINS_DIR}/cache"
    mkdir -p "${SHARED_PLUGINS_DIR}/marketplaces"
    mkdir -p "${SHARED_PLUGINS_DIR}/repos"

    log_success "共享目录已创建: ${SHARED_PLUGINS_DIR}"
}

# 同步 enabledPlugins 配置到共享目录
sync_enabled_plugins() {
    log_info "同步 enabledPlugins 配置..."

    local settings_file="${CLAUDE_ROOT}/settings.json"
    local shared_enabled_file="${SHARED_PLUGINS_DIR}/enabled_plugins_shared.json"

    if [ -f "${settings_file}" ]; then
        # 提取 enabledPlugins 部分
        local enabled_plugins=$(jq -c '.enabledPlugins // {}' "${settings_file}" 2>/dev/null || echo "{}")

        # 保存到共享文件
        echo "${enabled_plugins}" > "${shared_enabled_file}"
        log_success "enabledPlugins 配置已同步"
    else
        log_warn "settings.json 不存在，跳过 enabledPlugins 同步"
    fi
}

# 从共享目录合并 enabledPlugins 到当前配置
merge_enabled_plugins() {
    log_info "合并 enabledPlugins 配置..."

    local settings_file="${CLAUDE_ROOT}/settings.json"
    local shared_enabled_file="${SHARED_PLUGINS_DIR}/enabled_plugins_shared.json"

    if [ -f "${settings_file}" ] && [ -f "${shared_enabled_file}" ]; then
        # 备份原文件
        local backup_file="${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "${settings_file}" "${backup_file}" 2>/dev/null

        # 使用 jq 合并配置
        if jq --argjson enabled "$(cat "${shared_enabled_file}")" '.enabledPlugins = $enabled' "${settings_file}" > "${settings_file}.tmp" 2>/dev/null; then
            mv "${settings_file}.tmp" "${settings_file}"
            log_success "enabledPlugins 配置已合并"
        else
            log_error "合并 enabledPlugins 配置失败"
            # 恢复备份
            [ -f "${backup_file}" ] && mv "${backup_file}" "${settings_file}" 2>/dev/null
        fi
    elif [ ! -f "${settings_file}" ]; then
        log_warn "settings.json 不存在，跳过 enabledPlugins 合并"
    elif [ ! -f "${shared_enabled_file}" ]; then
        log_warn "共享 enabledPlugins 文件不存在，跳过合并"
    fi
}

# 备份当前配置
backup_current_config() {
    local model_name="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${CONFIG_BACKUP_DIR}/${model_name}_${timestamp}"

    if [ -d "${CLAUDE_ROOT}/plugins" ]; then
        cp -r "${CLAUDE_ROOT}/plugins" "${backup_path}"
        log_info "已备份当前配置到: ${backup_path}"
    fi
}

# 同步插件配置到共享目录
sync_to_shared() {
    log_info "正在同步插件到共享目录..."

    # 同步 cache 目录
    if [ -d "${CLAUDE_ROOT}/plugins/cache" ]; then
        rsync -av --update "${CLAUDE_ROOT}/plugins/cache/" "${SHARED_PLUGINS_DIR}/cache/" 2>/dev/null || \
        cp -r "${CLAUDE_ROOT}/plugins/cache/"* "${SHARED_PLUGINS_DIR}/cache/" 2>/dev/null || true
    fi

    # 同步 marketplace 目录
    if [ -d "${CLAUDE_ROOT}/plugins/marketplaces" ]; then
        rsync -av --update "${CLAUDE_ROOT}/plugins/marketplaces/" "${SHARED_PLUGINS_DIR}/marketplaces/" 2>/dev/null || \
        cp -r "${CLAUDE_ROOT}/plugins/marketplaces/"* "${SHARED_PLUGINS_DIR}/marketplaces/" 2>/dev/null || true
    fi

    # 同步 repos 目录
    if [ -d "${CLAUDE_ROOT}/plugins/repos" ]; then
        rsync -av --update "${CLAUDE_ROOT}/plugins/repos/" "${SHARED_PLUGINS_DIR}/repos/" 2>/dev/null || \
        cp -r "${CLAUDE_ROOT}/plugins/repos/"* "${SHARED_PLUGINS_DIR}/repos/" 2>/dev/null || true
    fi

    # 同步配置文件
    for file in installed_plugins.json known_marketplaces.json install-counts-cache.json config.json; do
        if [ -f "${CLAUDE_ROOT}/plugins/${file}" ]; then
            cp "${CLAUDE_ROOT}/plugins/${file}" "${SHARED_PLUGINS_DIR}/${file}" 2>/dev/null || true
        fi
    done

    # 同步 enabledPlugins 配置
    sync_enabled_plugins

    log_success "同步完成"
}

# 从共享目录同步到当前模型
sync_from_shared() {
    log_info "从共享目录恢复插件配置..."

    # 确保 plugins 目录存在
    mkdir -p "${CLAUDE_ROOT}/plugins"

    # 同步 cache 目录
    if [ -d "${SHARED_PLUGINS_DIR}/cache" ]; then
        mkdir -p "${CLAUDE_ROOT}/plugins/cache"
        rsync -av --update "${SHARED_PLUGINS_DIR}/cache/" "${CLAUDE_ROOT}/plugins/cache/" 2>/dev/null || \
        cp -r "${SHARED_PLUGINS_DIR}/cache/"* "${CLAUDE_ROOT}/plugins/cache/" 2>/dev/null || true
    fi

    # 同步 marketplace 目录
    if [ -d "${SHARED_PLUGINS_DIR}/marketplaces" ]; then
        mkdir -p "${CLAUDE_ROOT}/plugins/marketplaces"
        rsync -av --update "${SHARED_PLUGINS_DIR}/marketplaces/" "${CLAUDE_ROOT}/plugins/marketplaces/" 2>/dev/null || \
        cp -r "${SHARED_PLUGINS_DIR}/marketplaces/"* "${CLAUDE_ROOT}/plugins/marketplaces/" 2>/dev/null || true
    fi

    # 同步 repos 目录
    if [ -d "${SHARED_PLUGINS_DIR}/repos" ]; then
        mkdir -p "${CLAUDE_ROOT}/plugins/repos"
        rsync -av --update "${SHARED_PLUGINS_DIR}/repos/" "${CLAUDE_ROOT}/plugins/repos/" 2>/dev/null || \
        cp -r "${SHARED_PLUGINS_DIR}/repos/"* "${CLAUDE_ROOT}/plugins/repos/" 2>/dev/null || true
    fi

    # 同步配置文件
    for file in installed_plugins.json known_marketplaces.json install-counts-cache.json config.json; do
        if [ -f "${SHARED_PLUGINS_DIR}/${file}" ]; then
            cp "${SHARED_PLUGINS_DIR}/${file}" "${CLAUDE_ROOT}/plugins/${file}" 2>/dev/null || true
        fi
    done

    # 合并 enabledPlugins 配置
    merge_enabled_plugins

    log_success "恢复完成"
}

# 设置软链接（激进的共享方案）
setup_symlinks() {
    log_info "设置共享目录软链接..."

    # 备份原目录
    if [ -d "${CLAUDE_ROOT}/plugins" ] && [ ! -L "${CLAUDE_ROOT}/plugins" ]; then
        local backup_name="plugins.backup.$(date +%Y%m%d_%H%M%S)"
        mv "${CLAUDE_ROOT}/plugins" "${CLAUDE_ROOT}/${backup_name}"
        log_info "原 plugins 目录已备份为: ${backup_name}"
    fi

    # 如果存在旧的软链接，先删除
    if [ -L "${CLAUDE_ROOT}/plugins" ]; then
        rm "${CLAUDE_ROOT}/plugins"
    fi

    # 创建软链接
    ln -s "${SHARED_PLUGINS_DIR}" "${CLAUDE_ROOT}/plugins"
    log_success "软链接已创建: plugins -> ${SHARED_PLUGINS_DIR}"
}

# 移除软链接，恢复原状
remove_symlinks() {
    log_info "移除软链接..."

    if [ -L "${CLAUDE_ROOT}/plugins" ]; then
        rm "${CLAUDE_ROOT}/plugins"
        log_success "软链接已移除"
    else
        log_warn "没有找到软链接"
    fi
}

# 显示状态
show_status() {
    echo "================================"
    echo "  Plugin Sync 状态"
    echo "================================"
    echo ""
    echo "Claude Code 根目录: ${CLAUDE_ROOT}"
    echo "共享插件目录: ${SHARED_PLUGINS_DIR}"
    echo ""

    if [ -L "${CLAUDE_ROOT}/plugins" ]; then
        local target=$(readlink "${CLAUDE_ROOT}/plugins")
        echo -e "plugins 目录状态: ${GREEN}软链接${NC}"
        echo "  指向: ${target}"
        if [ "${target}" = "${SHARED_PLUGINS_DIR}" ]; then
            echo -e "  状态: ${GREEN}已正确配置${NC}"
        else
            echo -e "  状态: ${YELLOW}指向其他位置${NC}"
        fi
    elif [ -d "${CLAUDE_ROOT}/plugins" ]; then
        echo -e "plugins 目录状态: ${YELLOW}普通目录${NC}"
    else
        echo -e "plugins 目录状态: ${RED}不存在${NC}"
    fi
    echo ""

    if [ -d "${SHARED_PLUGINS_DIR}" ]; then
        echo -e "共享目录状态: ${GREEN}已创建${NC}"
        local cache_count=$(find "${SHARED_PLUGINS_DIR}/cache" -type d -name "*.claude-plugin" 2>/dev/null | wc -l)
        echo "  缓存插件数量: ${cache_count}"
    else
        echo -e "共享目录状态: ${RED}未创建${NC}"
    fi
    echo ""
}

# 主函数
main() {
    case "${1:-}" in
        init)
            init_shared_directory
            sync_to_shared
            setup_symlinks
            log_success "初始化完成！所有模型现在共享插件目录。"
            ;;
        sync-to)
            sync_to_shared
            ;;
        sync-from)
            sync_from_shared
            ;;
        setup-links)
            setup_symlinks
            ;;
        remove-links)
            remove_symlinks
            ;;
        status)
            show_status
            ;;
        auto)
            # 自动检测并同步
            if [ -d "${SHARED_PLUGINS_DIR}" ]; then
                # 共享目录已存在，从共享目录恢复
                sync_from_shared
            else
                # 首次运行，初始化
                init_shared_directory
                sync_to_shared
                setup_symlinks
            fi
            ;;
        *)
            echo "Claude Code 插件跨模型同步工具"
            echo ""
            echo "用法: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  init          初始化共享目录并设置软链接（首次使用）"
            echo "  sync-to       同步当前配置到共享目录"
            echo "  sync-from     从共享目录恢复配置到当前模型"
            echo "  setup-links   设置软链接"
            echo "  remove-links  移除软链接"
            echo "  status        显示当前状态"
            echo "  auto          自动检测并同步（Hook 调用）"
            echo ""
            ;;
    esac
}

main "$@"
