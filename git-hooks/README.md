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

## 特性

- **只审查文本文件**：自动跳过图片等二进制文件
- **内置 prompt**：无需额外配置文件
- **VS Code 集成**：审查结果自动在 VS Code 中打开

## 安装方式

### 方式一：单仓库安装（推荐用于测试）

在 Git 仓库根目录执行：

```bash
bash /path/to/install.sh
```

安装后会直接覆盖已有的 hooks 并安装 6 个 hooks 到 `.git/hooks/`。

### 方式二：全局安装（推荐长期使用）

全局安装后，**所有 Git 仓库**都会自动使用这些 hooks：

```bash
bash /path/to/install-global.sh
```

安装位置：`~/.git-hooks/`

原理：设置 Git 全局配置 `core.hooksPath`，所有仓库共享同一套 hooks。

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

## 卸载

### 单仓库卸载

```bash
rm -f .git/hooks/pre-commit .git/hooks/prepare-commit-msg .git/hooks/commit-msg .git/hooks/pre-push .git/hooks/post-merge .git/hooks/post-checkout
```

### 全局卸载

```bash
# 恢复 Git 默认行为（每个仓库使用自己的 .git/hooks/）
git config --global --unset core.hooksPath

# 删除全局 hooks 目录
rm -rf ~/.git-hooks
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `install.sh` | 单仓库安装脚本 |
| `install-global.sh` | 全局安装脚本 |
| `README.md` | 使用说明文档 |
