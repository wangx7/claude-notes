# Claude Notes 项目 Code Wiki

## 目录
- [项目概述](#项目概述)
- [整体架构](#整体架构)
- [主要模块职责](#主要模块职责)
- [关键脚本与函数说明](#关键脚本与函数说明)
- [依赖关系](#依赖关系)
- [项目运行与安装方式](#项目运行与安装方式)

---

## 项目概述

### 项目简介
**Claude Notes** 是一个 Claude 使用经验笔记集合，包含两个核心部分：
1. **Git Hooks 自动化代码审查** - 使用 Claude 在 Git 提交/推送时自动审查代码
2. **AI 辅助编程讲义** - 涵盖前端主流技术栈与后端 Java 全家桶的教学笔记

### 项目类型
- 教学笔记与工具集合
- 无独立应用程序，主要为文档和脚本

---

## 整体架构

### 目录结构
```
claude-notes/
├── README.md                          # 项目主文档
├── CODE_WIKI.md                       # 本文档
├── ai讲义/                            # AI 辅助编程讲义模块
│   ├── README.md                      # 讲义模块文档
│   ├── git-guide.md                   # Git 指南
│   ├── javascript-guide.md            # JavaScript 指南
│   ├── typescript-guide.md            # TypeScript 指南
│   ├── react-guide.md                 # React 指南
│   ├── vue2-guide.md                  # Vue 2 指南
│   ├── vue3-guide.md                  # Vue 3 指南
│   ├── java-guide.md                  # Java 全家桶指南
│   ├── design-guide.md                # 设计指南
│   └── 中级会计讲义/                  # 中级会计备考资料
│       ├── 00_中级会计备考指南.md
│       ├── 01_会计实务_上.md
│       ├── 02_会计实务_中.md
│       ├── 03_会计实务_下.md
│       ├── 04_财务管理.md
│       ├── 05_经济法.md
│       ├── 06_公式速查手册.md
│       └── 07_模拟试卷.md
└── git-hooks/                         # Git Hooks 自动化代码审查模块
    ├── README.md                      # Git Hooks 模块文档
    ├── install.sh                     # 单仓库安装脚本
    └── install-global.sh              # 全局安装脚本
```

### 架构特点
- **模块化设计**：两个独立模块，可单独使用
- **轻量级**：无复杂依赖，主要为 Shell 脚本和 Markdown 文档
- **可扩展性**：易于添加新的笔记或 Hook 功能

---

## 主要模块职责

### 1. git-hooks 模块

#### 核心职责
提供 Git 提交、推送、拉取时的自动化代码审查功能，通过 Claude AI 进行代码质量检查。

#### 工作流程
```
git add .
   ↓
git commit        → prepare-commit-msg Hook (审查代码 + 生成 commit message)
   ↓
git push          → pre-push Hook (审查代码，严重问题阻止推送)
   ↓
git pull/merge    → post-merge Hook (异步总结引入的改动)
```

#### Hook 类型与功能

| Hook 名称 | 触发时机 | 功能描述 | 是否阻断 |
|-----------|----------|----------|----------|
| pre-commit | commit 前 | 检查是否有暂存内容 | 是 |
| prepare-commit-msg | commit message 生成前 | 审查暂存区代码 + 自动生成 commit message | 否 |
| commit-msg | commit message 校验时 | 校验 message 是否符合 Conventional Commits 规范 | 是 |
| pre-push | push 前 | 审查待推送代码，严重问题阻止推送 | 是 |
| post-merge | pull/merge 后 | 异步审查引入的改动 | 否 |

### 2. ai讲义 模块

#### 核心职责
提供 AI 辅助编程教学讲义，涵盖前端主流技术栈与后端 Java 全家桶。

#### 讲义内容

| 讲义名称 | 文件路径 | 内容概述 |
|----------|----------|----------|
| Git 指南 | [git-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/git-guide.md) | Git 版本控制基础与常用操作 |
| JavaScript 指南 | [javascript-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/javascript-guide.md) | JavaScript 核心机制精讲——类型系统、作用域与闭包、原型链、异步编程、ES6+、模块、内存管理、性能优化、Chrome DevTools |
| TypeScript 指南 | [typescript-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/typescript-guide.md) | TypeScript 类型系统与实践 |
| React 指南 | [react-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/react-guide.md) | React 框架开发指南 |
| Vue2 指南 | [vue2-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/vue2-guide.md) | Vue 2 框架开发指南 |
| Vue3 指南 | [vue3-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/vue3-guide.md) | Vue 3 框架开发指南 |
| Java 全家桶指南 | [java-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/java-guide.md) | Java 后端全家桶——从语言基础到微服务部署 |
| 设计指南 | [design-guide.md](file:///Users/wangx/学习/github/claude-notes/ai讲义/design-guide.md) | 设计基础、UI 设计、交互设计、设计流程、设计系统、工具推荐等 |
| 中级会计讲义 | [中级会计讲义/](file:///Users/wangx/学习/github/claude-notes/ai讲义/中级会计讲义/) | 中级会计备考资料（备考指南、会计实务、财务管理、经济法等） |

---

## 关键脚本与函数说明

### 1. install.sh - 单仓库安装脚本

**文件路径**: [git-hooks/install.sh](file:///Users/wangx/学习/github/claude-notes/git-hooks/install.sh)

**功能**: 将 Claude Git Hooks 安装到当前 Git 仓库的 `.git/hooks` 目录

**关键流程**:
1. 检查是否在 Git 仓库内
2. 检查 Claude CLI 是否已安装
3. 创建 5 个 Hook 脚本
4. 设置执行权限

**生成的 Hook 脚本**:
- `pre-commit` - 检查暂存区是否有内容
- `prepare-commit-msg` - 审查代码 + 生成 commit message
- `commit-msg` - 校验 commit message 格式
- `pre-push` - push 前审查代码
- `post-merge` - pull/merge 后异步审查

### 2. install-global.sh - 全局安装脚本

**文件路径**: [git-hooks/install-global.sh](file:///Users/wangx/学习/github/claude-notes/git-hooks/install-global.sh)

**功能**: 将 Claude Git Hooks 全局安装到 `~/.git-hooks` 目录，并配置 Git 全局 hooksPath

**关键流程**:
1. 创建 `~/.git-hooks` 目录
2. 检查 Claude CLI 是否已安装
3. 创建 5 个 Hook 脚本
4. 设置执行权限
5. 配置 `git config --global core.hooksPath`

### 3. prepare-commit-msg Hook 核心逻辑

**功能**: 在 commit 时自动审查代码并生成 commit message

**关键代码片段**:
```bash
# 调用 Claude 审查代码
RESULT=$(claude -p "你是代码审查助手..." --output-format text 2>&1) || true

# 保存审查结果
TMPFILE="/tmp/claude-review-commit-$(date +%Y%m%d%H%M%S)-$$.md"
printf "🤖 Claude 审查结果（commit）\n\n%s\n" "$RESULT" > "$TMPFILE"
command -v code >/dev/null 2>&1 && code -r "$TMPFILE" 2>/dev/null || true

# 提取 commit message
MSG=$(echo "$RESULT" | grep -m1 -E '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)' || true)
[[ -n "$MSG" && "$MSG" != "null" ]] && echo "$MSG" > "$COMMIT_MSG_FILE"
```

**输出格式要求**:
- 第一行：【PASS】或【BLOCK】
- 第二行：commit message（符合 Conventional Commits 规范）
- 第三行起：审查详情

### 4. pre-push Hook 核心逻辑

**功能**: 在 push 前审查代码，严重问题阻止推送

**关键代码片段**:
```bash
while read -r LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA; do
    # 确定 diff 命令
    if [[ "$REMOTE_SHA" == "$ZERO" ]]; then
        DIFF_CMD="git log --patch -1 --diff-filter=d"
    else
        DIFF_CMD="git log --patch $REMOTE_SHA..$LOCAL_SHA --diff-filter=d"
    fi

    # 调用 Claude 审查
    RESULT=$(claude -p "你是代码安全审查助手..." --output-format text 2>&1) || true

    # 检查是否 BLOCK
    if echo "$RESULT" | head -5 | grep -q "【BLOCK】"; then
        echo "❌ 推送被阻止，请检查审查结果"
        exit 1
    fi
done
```

### 5. commit-msg Hook 核心逻辑

**功能**: 校验 commit message 是否符合 Conventional Commits 规范

**校验正则**:
```bash
if ! echo "$MSG" | grep -qE '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf|revert)(\(.+\))?!?: .+'; then
    echo "❌ 不符合 Conventional Commits 规范"
    exit 1
fi
```

**规范示例**:
- `feat: 新增登录功能`
- `fix(auth): 修复超时问题`
- `docs: 更新 README`

### 6. post-merge Hook 核心逻辑

**功能**: 在 pull/merge 后异步审查引入的改动

**特点**: 后台运行，不阻断操作

**关键代码片段**:
```bash
(
    RESULT=$(claude -p "你是代码审查助手..." --output-format text 2>&1) || true
    COMMIT_ID=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    TMPFILE="/tmp/claude-review-merge-${COMMIT_ID}-$$.md"
    printf "🤖 Claude 审查结果（pull/merge）\n提交: %s\n\n%s\n" "$COMMIT_ID" "$RESULT" > "$TMPFILE"
    command -v code >/dev/null 2>&1 && code -r "$TMPFILE" 2>/dev/null || true
) >/dev/null 2>&1 &
disown 2>/dev/null || true
```

---

## 依赖关系

### 外部依赖

| 依赖项 | 用途 | 安装方式 | 必需性 |
|--------|------|----------|--------|
| Claude CLI | AI 代码审查与 commit message 生成 | [官方文档](https://docs.anthropic.com/en/docs/claude-cli) | 必需 |
| Git | 版本控制与 Hook 触发 | 系统包管理器 | 必需 |
| VS Code (可选) | 自动打开审查结果 | 官方下载 | 可选 |

### 内部模块关系

```
claude-notes (根目录)
├── git-hooks (独立模块)
│   ├── install.sh
│   └── install-global.sh
└── ai讲义 (独立模块)
    ├── 各技术栈指南
    └── 中级会计讲义
```

两个模块相互独立，可单独使用。

---

## 项目运行与安装方式

### Git Hooks 安装

#### 前提条件
已安装 [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli)

#### 方式一：全局安装（推荐）
所有 Git 仓库自动生效：

```bash
bash /path/to/git-hooks/install-global.sh
```

**安装位置**: `~/.git-hooks`

**Git 配置**: 自动设置 `git config --global core.hooksPath`

#### 方式二：单仓库安装
仅当前仓库生效（在仓库目录内执行）：

```bash
bash /path/to/git-hooks/install.sh
```

**安装位置**: `.git/hooks`

### 使用方式

#### 正常使用
```bash
git add .
git commit        # Claude 审查代码 + 自动生成 commit message
git push          # Claude 审查代码，严重问题阻止推送
git pull          # Claude 异步总结引入的改动
git merge branch  # Claude 异步总结合并的改动
```

#### 跳过审查
```bash
git commit --no-verify    # 跳过 commit 相关 hooks
git push --no-verify      # 跳过 push 审查
```

### 卸载

#### 全局卸载
```bash
git config --global --unset core.hooksPath && rm -rf ~/.git-hooks
```

#### 单仓库卸载
```bash
rm -f .git/hooks/{pre-commit,prepare-commit-msg,commit-msg,pre-push,post-merge}
```

### 审查结果查看

审查结果自动保存到 `/tmp/claude-review-*.md`，安装了 VS Code 会自动打开。

---

## 附录

### Conventional Commits 规范

类型前缀：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档变更
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关
- `ci`: CI/CD 相关
- `build`: 构建系统相关
- `perf`: 性能优化
- `revert`: 回滚

### 相关文档
- [项目主 README](file:///Users/wangx/学习/github/claude-notes/README.md)
- [Git Hooks README](file:///Users/wangx/学习/github/claude-notes/git-hooks/README.md)
- [AI 讲义 README](file:///Users/wangx/学习/github/claude-notes/ai讲义/README.md)
