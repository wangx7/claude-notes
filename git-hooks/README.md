# Claude Git Hooks — AI 代码审查

Git 提交、推送、拉取时自动调用 Claude 审查代码。

## 工作流程

```
git add .
git commit        # → Claude 审查代码 + 自动生成 commit message
git push          # → Claude 审查代码，严重问题阻止推送
git pull          # → Claude 异步总结引入的改动
git merge branch  # → Claude 异步总结合并的改动
```

## 功能说明

| 操作 | 触发的 Hook | 行为 |
|------|------------|------|
| `git commit` | `prepare-commit-msg` | 审查暂存区代码 + 生成 message |
| `git push` | `pre-push` | 审查待推送代码，**严重问题阻止推送** |
| `git pull` | `post-merge` | 异步审查引入的改动（不阻断） |
| `git merge` | `post-merge` | 异步审查合并的改动（不阻断） |

辅助 hooks：
- `pre-commit` — 检查是否有暂存内容
- `commit-msg` — 校验 message 是否符合 [Conventional Commits](https://www.conventionalcommits.org/) 规范

审查结果自动保存到 `/tmp/claude-review-*.md`，安装了 VS Code 会自动打开。

## 安装

**前提**：已安装 [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli)

### 全局安装（推荐）

所有 Git 仓库自动生效：

```bash
bash /path/to/install-global.sh
```

### 单仓库安装

仅当前仓库生效（在仓库目录内执行）：

```bash
bash /path/to/install.sh
```

## 跳过审查

```bash
git commit --no-verify    # 跳过 commit 相关 hooks
git push --no-verify      # 跳过 push 审查
```

## 卸载

```bash
# 全局卸载
git config --global --unset core.hooksPath && rm -rf ~/.git-hooks

# 单仓库卸载
rm -f .git/hooks/{pre-commit,prepare-commit-msg,commit-msg,pre-push,post-merge}
```

## 文件

| 文件 | 说明 |
|------|------|
| `install-global.sh` | 全局安装脚本 |
| `install.sh` | 单仓库安装脚本 |
| `README.md` | 本文档 |
