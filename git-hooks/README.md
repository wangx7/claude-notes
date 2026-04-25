# Git Hooks 自动化代码审查

使用 Claude 在 Git 提交、推送、合并时自动审查代码，发现安全问题、生成 commit message、总结改动。

## 功能

| Hook | 功能 | 阻断性 |
|------|------|--------|
| `pre-commit` | 提交前审查代码，检查安全漏洞和 bug | 是（可跳过） |
| `prepare-commit-msg` | 自动生成 Conventional Commits 格式的 commit message | 否 |
| `commit-msg` | 校验 commit message 格式 | 是（可跳过） |
| `pre-push` | 推送前审查代码，检查安全问题 | 是（可跳过） |
| `post-merge` | 合并后总结改动（异步） | 否 |
| `post-checkout` | 拉取后总结改动（异步） | 否 |

## 安装

在 Git 仓库根目录执行：

```bash
# 方式一：直接执行脚本
bash /path/to/install.sh

# 方式二：复制脚本到仓库后执行
cp /path/to/install.sh .
bash install.sh
```

安装后会：
- 备份已有的 hooks（添加 `.bak.timestamp` 后缀）
- 创建 `.claude-git` 配置文件
- 安装 6 个 hooks 到 `.git/hooks/`

## 使用

安装后正常使用 Git 即可：

```bash
git add .
git commit    # 自动审查代码、生成 commit message
git push      # 推送前审查代码
git pull      # 拉取后总结改动
```

审查结果会自动在 VS Code 中打开（如果安装了 VS Code）。

## 跳过审查

```bash
git commit --no-verify    # 跳过提交相关 hooks
git push --no-verify      # 跳过推送审查
```

## 配置

安装后仓库根目录会生成 `.claude-git` 配置文件，可自定义审查提示词：

```bash
STAGED_PROMPT="审查即将提交的代码，总结改动、检查安全漏洞、给出优化建议，用中文简洁回答。如果有严重安全问题或严重bug，请在回复第一行写 【BLOCK】，否则第一行写 【PASS】。"
MERGE_PROMPT="总结合并引入的代码改动，检查冲突解决是否正确、有无安全隐患，用中文"
PULL_PROMPT="总结拉取的更新，检查是否有破坏性变更或安全问题，用中文"
COMMIT_PROMPT="根据代码改动生成一条符合 Conventional Commits 规范的中文 commit message"
PUSH_PROMPT="审查即将推送到远程的代码改动，检查是否有严重安全问题。如果有严重问题，第一行写【BLOCK】，否则写【PASS】。用中文简洁回答。"
```

修改后无需重新安装 hooks。

## 卸载

```bash
rm -f .git/hooks/pre-commit .git/hooks/prepare-commit-msg .git/hooks/commit-msg .git/hooks/pre-push .git/hooks/post-merge .git/hooks/post-checkout .claude-git
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `install.sh` | 安装脚本，包含所有 hooks 代码 |
| `README.md` | 使用说明文档 |