set +H 2>/dev/null  # 兼容终端直接粘贴运行（必须第一行，`!` 会触发 zsh 历史展开）

HOOKS_DIR="$HOME/.git-hooks"

echo "=== Claude Git Hooks 全局安装 ==="
echo "安装目录: $HOOKS_DIR"
echo ""

# 检查依赖
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️  未检测到 claude CLI，安装后 hooks 将无法工作"
    echo "   安装: https://docs.anthropic.com/en/docs/claude-cli"
    echo ""
fi

mkdir -p "$HOOKS_DIR"

# ==================== pre-commit ====================
# 轻量检查：暂存区是否有内容
cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/usr/bin/env bash
if git diff --cached --quiet; then
    echo "没有暂存的改动，请先 git add"
    exit 1
fi
HOOK

# ==================== prepare-commit-msg ====================
# 【核心】commit 时：审查代码 + 生成 message
cat > "$HOOKS_DIR/prepare-commit-msg" << 'HOOK'
#!/usr/bin/env bash
COMMIT_MSG_FILE=$1
SOURCE=${2:-}

# 用户已提供 message（-m / -F / template / squash），跳过
[[ -n "$SOURCE" ]] && exit 0

echo "🤖 Claude 正在审查代码并生成 commit message..."

RESULT=$(claude -p "你是代码审查助手。执行 git diff --cached --diff-filter=d 查看暂存区改动。

任务：
1. 审查代码：检查安全漏洞、逻辑错误、代码质量
2. 生成 commit message：符合 Conventional Commits 规范的中文描述

严格按以下格式输出（不要加多余标记）：
第一行：【PASS】或【BLOCK】（仅严重安全/逻辑问题才 BLOCK）
第二行：commit message（如 feat: 新增用户认证模块）
第三行起：审查详情

用中文回答。只看暂存区，不看工作区。" --output-format text 2>&1) || true

# 保存审查结果
TMPFILE="/tmp/claude-review-commit-$(date +%Y%m%d%H%M%S)-$$.md"
printf "🤖 Claude 审查结果（commit）\n\n%s\n" "$RESULT" > "$TMPFILE"
command -v code >/dev/null 2>&1 && code -r "$TMPFILE" 2>/dev/null || true

# 提取 commit message：优先匹配 Conventional Commits 格式，fallback 取第二行
MSG=$(echo "$RESULT" | grep -m1 -E '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)' || true)
if [[ -z "$MSG" ]]; then
    MSG=$(echo "$RESULT" | sed -n '2p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi
[[ -n "$MSG" && "$MSG" != "null" ]] && echo "$MSG" > "$COMMIT_MSG_FILE"

# BLOCK 提示（不阻断，用户可在编辑器中决定）
if echo "$RESULT" | head -5 | grep -q "【BLOCK】"; then
    echo ""
    echo "⚠️  发现严重问题，请检查审查结果后决定是否继续"
fi
HOOK

# ==================== commit-msg ====================
# 轻量校验：message 格式
cat > "$HOOKS_DIR/commit-msg" << 'HOOK'
#!/usr/bin/env bash
MSG=$(head -1 "$1")
[[ -z "$MSG" ]] && echo "commit message 不能为空" && exit 1
if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)(\(.+\))?!?: .+'; then
    echo "❌ 不符合 Conventional Commits 规范"
    echo "   当前: $MSG"
    echo "   示例: feat: 新增登录功能 / fix(auth): 修复超时"
    echo "   跳过: git commit --no-verify"
    exit 1
fi
HOOK

# ==================== pre-push ====================
# 【核心】push 时：审查代码（阻断）
cat > "$HOOKS_DIR/pre-push" << 'HOOK'
#!/usr/bin/env bash
ZERO="0000000000000000000000000000000000000000"
while read -r LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA; do
    [[ "$LOCAL_SHA" == "$ZERO" ]] && continue
    echo "🤖 Claude 正在审查即将推送的代码..."

    if [[ "$REMOTE_SHA" == "$ZERO" ]]; then
        DIFF_CMD="git log --patch -1 --diff-filter=d"
    else
        DIFF_CMD="git log --patch $REMOTE_SHA..$LOCAL_SHA --diff-filter=d"
    fi

    RESULT=$(claude -p "你是代码安全审查助手。执行 $DIFF_CMD 查看待推送的改动。
重点检查：严重安全漏洞、敏感信息泄露（密钥/密码/token）、危险操作。
第一行写【PASS】或【BLOCK】，后续简述原因。用中文回答。" --output-format text 2>&1) || true

    TMPFILE="/tmp/claude-review-push-$(date +%Y%m%d%H%M%S)-$$.md"
    printf "🤖 Claude 审查结果（push）\n\n%s\n" "$RESULT" > "$TMPFILE"
    command -v code >/dev/null 2>&1 && code -r "$TMPFILE" 2>/dev/null || true

    if echo "$RESULT" | head -5 | grep -q "【BLOCK】"; then
        echo ""
        echo "❌ 推送被阻止，请检查审查结果"
        echo "   强制推送: git push --no-verify"
        exit 1
    fi
done
HOOK

# ==================== post-merge ====================
# 【核心】pull / merge 后：审查代码（异步不阻断）
cat > "$HOOKS_DIR/post-merge" << 'HOOK'
#!/usr/bin/env bash
(
    RESULT=$(claude -p "你是代码审查助手。执行 git diff ORIG_HEAD..HEAD --diff-filter=d 查看本次 pull/merge 引入的改动。
总结关键变更，检查是否有安全隐患或破坏性变更。用中文简洁回答。" --output-format text 2>&1) || true

    COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    TMPFILE="/tmp/claude-review-merge-${COMMIT_ID}-$$.md"
    printf "🤖 Claude 审查结果（pull/merge）\n提交: %s\n\n%s\n" "$COMMIT_ID" "$RESULT" > "$TMPFILE"
    command -v code >/dev/null 2>&1 && code -r "$TMPFILE" 2>/dev/null || true
) >/dev/null 2>&1 &
disown 2>/dev/null || true
HOOK

# 设置权限 & 配置 Git
chmod +x "$HOOKS_DIR"/*
git config --global core.hooksPath "$HOOKS_DIR"

echo ""
echo "✅ 安装完成"
echo ""
echo "  commit  → 审查代码 + 生成 commit message"
echo "  push    → 审查代码（严重问题阻止推送）"
echo "  pull    → 审查引入的改动（异步）"
echo "  merge   → 审查合并的改动（异步）"
echo ""
echo "跳过: git commit/push --no-verify"
echo "卸载: git config --global --unset core.hooksPath && rm -rf $HOOKS_DIR"