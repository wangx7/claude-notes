set +H

# 全局 hooks 目录
HOOKS_DIR="$HOME/.git-hooks"

echo "=== Git Hooks 全局安装 ==="
echo ""
echo "将安装到: $HOOKS_DIR"
echo ""

# 创建目录
mkdir -p "$HOOKS_DIR"

# pre-commit: 提交前审查代码
cat > "$HOOKS_DIR/pre-commit" << 'H1'
#!/bin/bash
ROOT=$(git rev-parse --show-toplevel)
DIFF_FILE=$(mktemp)
# 排除删除的文件，过滤二进制文件
git diff --cached --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
if [ ! -s "$DIFF_FILE" ]; then
    git diff HEAD --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
fi
if [ -s "$DIFF_FILE" ]; then
    PROMPT="审查即将提交的代码，总结改动、检查安全漏洞、给出优化建议，用中文简洁回答。如果有严重安全问题或严重bug，请在回复第一行写 【BLOCK】，否则第一行写 【PASS】。"
    echo "🤖 Claude 正在审查..."
    RESULT=$(claude -p "${PROMPT}。请读取文件 $DIFF_FILE（git diff 格式），按上述要求回答。" --output-format text 2>&1)
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    TMPFILE="/tmp/claude-review-${TIMESTAMP}.md"
    {
        echo "🤖 Claude 审查结果（pre-commit）"
        echo ""
        echo "$RESULT"
        echo ""
        echo "---"
        echo "临时文件，系统重启时自动清理；macOS/Linux 长时间（通常3天以上）未访问也可能被清理"
    } > "$TMPFILE"
    if command -v code >/dev/null 2>&1; then
        code -r "$TMPFILE" 2>/dev/null || true
    fi
    if echo "$RESULT" | head -n 10 | grep -q "【BLOCK】"; then
        echo ""
        echo "❌ 审查发现严重问题，提交已阻止"
        echo "💡 如需强制提交：git commit --no-verify"
        exit 1
    fi
    echo "✅ 审查通过"
fi
rm -f "$DIFF_FILE"
exit 0
H1

# prepare-commit-msg: 自动生成 commit message
cat > "$HOOKS_DIR/prepare-commit-msg" << 'H2'
#!/bin/bash
COMMIT_MSG_FILE=$1
SOURCE=$2
if [ "$SOURCE" = "message" ] || [ "$SOURCE" = "template" ] || [ "$SOURCE" = "squash" ]; then
    exit 0
fi
ROOT=$(git rev-parse --show-toplevel)
DIFF_FILE=$(mktemp)
# 排除删除的文件，过滤二进制文件
git diff --cached --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
if [ ! -s "$DIFF_FILE" ]; then
    git diff HEAD --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
fi
if [ -s "$DIFF_FILE" ]; then
    PROMPT="根据代码改动生成一条符合 Conventional Commits 规范的中文 commit message"
    RESULT=$(claude -p "${PROMPT}。请读取文件 $DIFF_FILE（git diff 格式），只返回一条符合 Conventional Commits 规范的中文 commit message，不要解释。格式示例：feat: 新增用户登录功能" --output-format text 2>&1)
    FIRST_LINE=$(echo "$RESULT" | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$FIRST_LINE" ] && [ "$FIRST_LINE" != "null" ]; then
        echo "$FIRST_LINE" > "$COMMIT_MSG_FILE"
    fi
fi
rm -f "$DIFF_FILE"
exit 0
H2

# commit-msg: 校验 commit message 格式
cat > "$HOOKS_DIR/commit-msg" << 'H3'
#!/bin/bash
MSG_FILE=$1
MSG=$(head -n 1 "$MSG_FILE")
if [ -z "$MSG" ] || [ "$MSG" = "null" ]; then
    echo "提交信息不能为空"
    exit 1
fi
if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)(\(.+\))?: .+'; then
    echo "提交信息不符合 Conventional Commits 规范"
    echo "当前: $MSG"
    echo "示例: feat: 新增登录功能"
    echo "💡 如需跳过校验：git commit --no-verify"
    exit 1
fi
exit 0
H3

# pre-push: 推送前审查代码
cat > "$HOOKS_DIR/pre-push" << 'H4'
#!/bin/bash
REMOTE=$1
URL=$2
while read LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA; do
    if [ "$LOCAL_SHA" = "0000000000000000000000000000000000000000" ]; then
        continue
    fi
    DIFF_FILE=$(mktemp)
    if [ "$REMOTE_SHA" = "0000000000000000000000000000000000000000" ]; then
        git log --patch "$LOCAL_SHA" -1 --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
    else
        git log --patch "$REMOTE_SHA..$LOCAL_SHA" --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
    fi
    if [ -s "$DIFF_FILE" ]; then
        ROOT=$(git rev-parse --show-toplevel)
        PROMPT="审查即将推送到远程的代码改动，检查是否有严重安全问题。如果有严重问题，第一行写【BLOCK】，否则写【PASS】。用中文简洁回答。"
        echo "🤖 Claude 正在审查即将推送的代码..."
        RESULT=$(claude -p "${PROMPT}。请读取文件 $DIFF_FILE（git diff 格式），按上述要求回答。" --output-format text 2>&1)
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        TMPFILE="/tmp/claude-review-push-${TIMESTAMP}.md"
        {
            echo "🤖 Claude 审查结果（pre-push）"
            echo ""
            echo "$RESULT"
            echo ""
            echo "---"
            echo "临时文件，系统重启时自动清理；macOS/Linux 长时间（通常3天以上）未访问也可能被清理"
        } > "$TMPFILE"
        if command -v code >/dev/null 2>&1; then
            code -r "$TMPFILE" 2>/dev/null || true
        fi
        if echo "$RESULT" | head -n 10 | grep -q "【BLOCK】"; then
            echo ""
            echo "❌ 推送审查未通过，push 已阻止"
            rm -f "$DIFF_FILE"
            exit 1
        fi
    fi
    rm -f "$DIFF_FILE"
done
exit 0
H4

# post-merge: 合并后总结改动（异步）
cat > "$HOOKS_DIR/post-merge" << 'H5'
#!/bin/bash
(
    ROOT=$(git rev-parse --show-toplevel)
    DIFF_FILE=$(mktemp)
    # 只获取文本文件的 diff，过滤二进制文件
    git diff ORIG_HEAD..HEAD --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
    if [ -s "$DIFF_FILE" ]; then
        PROMPT="总结合并引入的代码改动，检查冲突解决是否正确、有无安全隐患，用中文"
        RESULT=$(claude -p "${PROMPT}。请读取文件 $DIFF_FILE（git diff 格式），按上述要求回答。" --output-format text 2>&1)
        COMMIT_ID=$(git rev-parse --short HEAD)
        TMPFILE="/tmp/claude-review-${COMMIT_ID}.md"
        {
            echo "🤖 Claude 审查结果（post-merge）"
            echo "对应提交: ${COMMIT_ID}"
            echo ""
            echo "$RESULT"
            echo ""
            echo "---"
            echo "临时文件，系统重启时自动清理；macOS/Linux 长时间（通常3天以上）未访问也可能被清理"
        } > "$TMPFILE"
        if command -v code >/dev/null 2>&1; then
            code -r "$TMPFILE" 2>/dev/null || true
        fi
    fi
    rm -f "$DIFF_FILE"
) &
exit 0
H5

# post-checkout: 拉取后总结改动（异步）
cat > "$HOOKS_DIR/post-checkout" << 'H6'
#!/bin/bash
PREV_HEAD=$1
NEW_HEAD=$2
FLAG=$3
if git reflog -1 | grep -qE 'pull|merge'; then
    (
        ROOT=$(git rev-parse --show-toplevel)
        DIFF_FILE=$(mktemp)
        # 只获取文本文件的 diff，过滤二进制文件
        git diff "$PREV_HEAD..$NEW_HEAD" --diff-filter=d 2>/dev/null | grep -v "^Binary files " > "$DIFF_FILE"
        if [ -s "$DIFF_FILE" ]; then
            PROMPT="总结拉取的更新，检查是否有破坏性变更或安全问题，用中文"
            RESULT=$(claude -p "${PROMPT}。请读取文件 $DIFF_FILE（git diff 格式），按上述要求回答。" --output-format text 2>&1)
            COMMIT_ID=$(git rev-parse --short HEAD)
            TMPFILE="/tmp/claude-review-${COMMIT_ID}.md"
            {
                echo "🤖 Claude 审查结果（post-checkout / pull）"
                echo "对应提交: ${COMMIT_ID}"
                echo ""
                echo "$RESULT"
                echo ""
                echo "---"
                echo "临时文件，系统重启时自动清理；macOS/Linux 长时间（通常3天以上）未访问也可能被清理"
            } > "$TMPFILE"
            if command -v code >/dev/null 2>&1; then
                code -r "$TMPFILE" 2>/dev/null || true
            fi
        fi
        rm -f "$DIFF_FILE"
    ) &
fi
exit 0
H6

# 设置执行权限
chmod +x "$HOOKS_DIR"/*

# 配置 Git 使用全局 hooks 目录
git config --global core.hooksPath "$HOOKS_DIR"

echo ""
echo "✅ 全局安装完成"
echo ""
echo "Hooks 目录: $HOOKS_DIR"
echo "Git 配置: core.hooksPath = $HOOKS_DIR"
echo ""
echo "所有 Git 仓库将自动使用这些 hooks"
echo ""
echo "pre-commit：提交前同步审查，严重问题阻止提交"
echo "prepare-commit-msg：自动生成 Conventional Commits 格式 message"
echo "commit-msg：校验 message 格式"
echo "pre-push：推送前同步审查，严重问题阻止推送"
echo "post-merge：合并后异步总结"
echo "post-checkout：拉取后异步总结"
echo ""
echo "如需跳过所有钩子：git commit --no-verify 或 git push --no-verify"
