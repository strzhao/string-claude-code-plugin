#!/bin/bash

# dev-loop 初始化 / 子命令路由脚本
# 用法:
#   /dev-loop <目标描述>                   初始化新的 dev-loop
#   /dev-loop approve [反馈]               批准当前审批门
#   /dev-loop revise <反馈>                要求修改当前阶段产出
#   /dev-loop status                       查看当前状态
#   /dev-loop cancel                       取消并清理
#   /dev-loop --help                       显示帮助

set -euo pipefail

STATE_FILE=".claude/dev-loop.local.md"

# ── 辅助函数 ──────────────────────────────────────────────

parse_frontmatter() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo ""
        return
    fi
    sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE"
}

get_field() {
    local field="$1"
    local fm
    fm=$(parse_frontmatter)
    echo "$fm" | grep "^${field}:" | sed "s/${field}: *//" | sed 's/^"\(.*\)"$/\1/'
}

set_field() {
    local field="$1"
    local value="$2"
    local temp="${STATE_FILE}.tmp.$$"
    sed "s/^${field}: .*/${field}: ${value}/" "$STATE_FILE" > "$temp"
    mv "$temp" "$STATE_FILE"
}

append_changelog() {
    local entry="$1"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    # 在 ## 变更日志 后追加
    local temp="${STATE_FILE}.tmp.$$"
    awk -v entry="- [${timestamp}] ${entry}" '
        /^## 变更日志/ { print; getline; print entry; print; next }
        { print }
    ' "$STATE_FILE" > "$temp"
    mv "$temp" "$STATE_FILE"
}

now_iso() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

# ── 子命令路由 ──────────────────────────────────────────────

FIRST_ARG="${1:-}"

case "$FIRST_ARG" in
    -h|--help)
        cat << 'HELP_EOF'
dev-loop — AI 驱动的 DevOps 闭环

用法:
  /dev-loop <目标描述> [选项]           启动新的 dev-loop
  /dev-loop approve [反馈]              批准当前审批门
  /dev-loop revise <反馈>               要求修改
  /dev-loop status                      查看状态
  /dev-loop cancel                      取消并清理

选项:
  --max-iterations <n>    最大迭代次数 (默认: 30)
  --max-retries <n>       单阶段最大重试次数 (默认: 3)

示例:
  /dev-loop 实现用户头像上传功能，支持裁剪和压缩
  /dev-loop 给 API 添加分页功能 --max-iterations 50
  /dev-loop approve
  /dev-loop revise 需要支持 WebP 格式
HELP_EOF
        exit 0
        ;;

    approve)
        if [[ ! -f "$STATE_FILE" ]]; then
            echo "❌ 没有活跃的 dev-loop。使用 /dev-loop <目标> 启动新循环。" >&2
            exit 1
        fi
        GATE=$(get_field "gate")
        if [[ -z "$GATE" ]]; then
            echo "❌ 当前不在审批门，无需 approve。" >&2
            echo "   当前阶段: $(get_field 'phase')" >&2
            exit 1
        fi
        FEEDBACK="${2:-}"
        set_field "gate" '""'
        # 推进阶段（design 审批由 Plan Mode 处理，这里只处理 review-accept）
        case "$GATE" in
            review-accept)
                set_field "phase" '"merge"'
                append_changelog "用户批准验收，进入合并阶段${FEEDBACK:+。反馈: $FEEDBACK}"
                echo "✅ 验收已通过，将进入代码合并阶段。"
                ;;
            *)
                echo "⚠️  未知的审批门: $GATE" >&2
                exit 1
                ;;
        esac
        echo ""
        echo "循环将在下次自动继续。"
        exit 0
        ;;

    revise)
        if [[ ! -f "$STATE_FILE" ]]; then
            echo "❌ 没有活跃的 dev-loop。" >&2
            exit 1
        fi
        GATE=$(get_field "gate")
        if [[ -z "$GATE" ]]; then
            echo "❌ 当前不在审批门，无法 revise。" >&2
            exit 1
        fi
        shift  # 移除 "revise"
        FEEDBACK="$*"
        if [[ -z "$FEEDBACK" ]]; then
            echo "❌ 请提供修改反馈。用法: /dev-loop revise <反馈>" >&2
            exit 1
        fi
        set_field "gate" '""'
        set_field "retry_count" "0"
        # design 审批由 Plan Mode 处理，这里只处理 review-accept
        case "$GATE" in
            review-accept)
                set_field "phase" '"implement"'
                append_changelog "用户要求修改实现: $FEEDBACK"
                echo "🔄 收到修改反馈，将重新进入实现阶段。"
                ;;
        esac
        # 将反馈写入状态文件的用户反馈区
        TEMP_REV="${STATE_FILE}.tmp.$$"
        awk -v fb="**用户反馈 ($(date -u +%Y-%m-%dT%H:%M:%SZ))**: $FEEDBACK" '
            /^## 变更日志/ { print "## 用户反馈\n" fb "\n"; print; next }
            { print }
        ' "$STATE_FILE" > "$TEMP_REV"
        mv "$TEMP_REV" "$STATE_FILE"
        echo ""
        echo "循环将在下次自动继续。"
        exit 0
        ;;

    status)
        if [[ ! -f "$STATE_FILE" ]]; then
            echo "📋 没有活跃的 dev-loop。"
            exit 0
        fi
        PHASE=$(get_field "phase")
        GATE=$(get_field "gate")
        ITERATION=$(get_field "iteration")
        MAX_ITER=$(get_field "max_iterations")
        RETRY=$(get_field "retry_count")
        MAX_RETRY=$(get_field "max_retries")
        STARTED=$(get_field "started_at")

        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  dev-loop 状态"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "阶段:     $PHASE"
        echo "审批门:   ${GATE:-无}"
        echo "迭代:     $ITERATION / $MAX_ITER"
        echo "重试:     $RETRY / $MAX_RETRY"
        echo "开始时间: $STARTED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 0
        ;;

    cancel)
        if [[ ! -f "$STATE_FILE" ]]; then
            echo "📋 没有活跃的 dev-loop。"
            exit 0
        fi
        rm "$STATE_FILE"
        echo "🛑 dev-loop 已取消，状态文件已清理。"
        echo "   代码改动仍保留在工作目录中，可通过 git 查看。"
        exit 0
        ;;
esac

# ── 初始化新的 dev-loop ────────────────────────────────────

# 检查冲突
if [[ -f "$STATE_FILE" ]]; then
    echo "❌ 已有活跃的 dev-loop 在运行。" >&2
    echo "   使用 /dev-loop status 查看状态" >&2
    echo "   使用 /dev-loop cancel 取消后重新开始" >&2
    exit 1
fi

if [[ -f ".claude/ralph-loop.local.md" ]]; then
    echo "❌ 检测到 ralph-loop 正在运行，两者共用 Stop hook 机制，不能同时运行。" >&2
    echo "   请先取消 ralph-loop 后再启动 dev-loop。" >&2
    exit 1
fi

# 解析参数
PROMPT_PARTS=()
MAX_ITERATIONS=30
MAX_RETRIES=3

while [[ $# -gt 0 ]]; do
    case $1 in
        --max-iterations)
            if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "❌ --max-iterations 需要一个正整数参数" >&2
                exit 1
            fi
            MAX_ITERATIONS="$2"
            shift 2
            ;;
        --max-retries)
            if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "❌ --max-retries 需要一个正整数参数" >&2
                exit 1
            fi
            MAX_RETRIES="$2"
            shift 2
            ;;
        *)
            PROMPT_PARTS+=("$1")
            shift
            ;;
    esac
done

GOAL="${PROMPT_PARTS[*]}"

if [[ -z "$GOAL" ]]; then
    echo "❌ 请提供目标描述。" >&2
    echo "   用法: /dev-loop <目标描述>" >&2
    echo "   示例: /dev-loop 实现用户头像上传功能" >&2
    exit 1
fi

# 创建状态文件
mkdir -p .claude

cat > "$STATE_FILE" <<EOF
---
active: true
phase: "design"
gate: ""
iteration: 1
max_iterations: $MAX_ITERATIONS
max_retries: $MAX_RETRIES
retry_count: 0
session_id: ${CLAUDE_CODE_SESSION_ID:-}
started_at: "$(now_iso)"
---

## 目标
$GOAL

## 设计文档
(待 design 阶段填充)

## 实现计划
(待 design 阶段填充)

## QA 报告
(待 qa 阶段填充)

## 变更日志
- [$(now_iso)] dev-loop 初始化，目标: $GOAL
EOF

# 输出信息
cat <<EOF
🔄 dev-loop 已启动！

目标: $GOAL
最大迭代: $MAX_ITERATIONS
最大重试: $MAX_RETRIES

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  阶段流程: design → 审批 → implement → qa → 审批 → merge
  当前阶段: design（AI 正在分析目标并设计方案）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

命令:
  /dev-loop approve    批准当前审批门
  /dev-loop revise     要求修改
  /dev-loop status     查看状态
  /dev-loop cancel     取消循环

提示: 建议在 worktree 中运行以隔离代码改动
      claude -w dev-loop-xxx 然后 /dev-loop <目标>
EOF

echo ""
echo "开始设计阶段。请按照 dev-loop skill 的指引，读取 .claude/dev-loop.local.md 状态文件并执行 design 阶段。"
