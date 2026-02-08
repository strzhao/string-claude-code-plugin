#!/bin/bash
# Claude Code 插件同步系统一键初始化脚本
# 运行此脚本设置跨模型插件共享

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="${SCRIPT_DIR}/assets/scripts/sync.sh"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Claude Code 插件同步系统初始化${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# 检查 sync.sh 是否存在
if [ ! -f "${SYNC_SCRIPT}" ]; then
    echo "错误: 找不到同步脚本 ${SYNC_SCRIPT}"
    exit 1
fi

# 添加执行权限
chmod +x "${SYNC_SCRIPT}"

echo -e "${GREEN}步骤 1/3:${NC} 检查当前状态"
"${SYNC_SCRIPT}" status
echo ""

echo -e "${GREEN}步骤 2/3:${NC} 初始化共享目录"
"${SYNC_SCRIPT}" init
echo ""

echo -e "${GREEN}步骤 3/3:${NC} 验证配置"
"${SYNC_SCRIPT}" status
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  初始化完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "插件现在会在所有模型间共享。"
echo ""
echo "常用命令:"
echo "  ${YELLOW}./setup.sh${NC}           重新初始化"
echo "  ${YELLOW}sync.sh status${NC}       查看状态"
echo "  ${YELLOW}sync.sh sync-to${NC}      手动同步到共享目录"
echo "  ${YELLOW}sync.sh sync-from${NC}    手动从共享目录恢复"
echo ""
