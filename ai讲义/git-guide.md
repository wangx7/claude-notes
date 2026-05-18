# Git 精讲

> 场景驱动，原理打底。看完能应对日常开发 99% 的 Git 操作，遇到问题知道怎么查、怎么救。

---

## 一、Git 的心智模型

### 快照，不是差异

```
SVN（差异）：记录每个文件每次改了什么
  v1: 文件A          v2: 文件A +3行 -1行    v3: 文件A +2行

Git（快照）：每次提交拍一张整个项目的"照片"
  v1: [A₁, B₁, C₁]  v2: [A₂, B₁, C₂]      v3: [A₂, B₂, C₂]
  没变的文件（B₁→B₁）不重复存储，只存指针
```

### 三个区域

```
工作区（Working Directory）  ──git add──▶  暂存区（Staging Area）  ──git commit──▶  本地仓库（Repository）
     你正在编辑的文件              准备提交的文件                    永久保存的快照
                                                                        │
                                                                   git push
                                                                        ▼
                                                                  远程仓库（GitHub/GitLab）
```

> **关键理解**：`git add` 不是"跟踪文件"，而是把**这一刻的文件快照**放入暂存区。add 之后再改文件，改动不会自动进暂存区，需要再 add 一次。

### Git 对象模型（理解原理的关键）

```
Git 仓库（.git/objects/）里只有三种对象：

blob   → 文件内容（不含文件名）
tree   → 目录结构（记录文件名和对应的 blob）
commit → 一次提交（指向一个 tree + 作者 + 时间 + 提交信息 + 父 commit）

一次提交长这样：
  commit abc1234
    ├── tree: 根目录快照
    │     ├── blob: src/login.vue 的内容
    │     ├── blob: src/api.js 的内容
    │     └── tree: components/
    │           └── blob: Header.vue 的内容
    ├── parent: 上一次提交的 hash
    ├── author: 张三 <zhangsan@example.com>
    └── message: "feat: 添加登录功能"

分支 = 一个指向 commit 的指针
HEAD = 指向当前分支的指针
tag  = 一个不动的指向 commit 的指针
```

> **所以 Git 的分支切换极快**——不是复制文件，只是把 HEAD 指针移到另一个 commit。

---

## 二、环境配置

### 全局配置（装完 Git 第一件事）

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
git config --global core.editor "code --wait"       # 用 VSCode 当编辑器
git config --global init.defaultBranch main          # 默认分支用 main
git config --global pull.rebase false                # pull 时用 merge（不 rebase）

# 查看所有配置
git config --list
```

### SSH 密钥（免密推送）

```bash
ssh-keygen -t ed25519 -C "你的邮箱"    # 生成密钥
cat ~/.ssh/id_ed25519.pub              # 复制公钥
# 粘贴到 GitHub → Settings → SSH and GPG keys → New SSH key

# 测试
ssh -T git@github.com                 # 成功会显示 Hi xxx!
```

### 常用别名（可选，提高效率）

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm "commit -m"
git config --global alias.lg "log --oneline --graph --all -20"

# 之后 git st = git status, git lg = 漂亮的分支图
```

### .gitignore 模板

```bash
# Node.js 项目
node_modules/
dist/
.env
.env.local
*.log

# IDE
.idea/
.vscode/
*.swp

# macOS
.DS_Store

# Java 项目
target/
*.class
*.jar
```

---

## 三、日常开发流程

### 场景：从零开始一个项目

```bash
# 方式 1：克隆已有项目
git clone git@github.com:user/repo.git
cd repo

# 方式 2：本地初始化
mkdir my-project && cd my-project
git init
git remote add origin git@github.com:user/repo.git
```

### 场景：接了个需求，完整流程

```bash
# 1. 拉最新代码
git pull origin main

# 2. 建功能分支（永远不要在 main 上直接写代码）
git checkout -b feature/user-login

# 3. 写代码...写完看看改了啥
git status                              # 哪些文件变了
git diff                                # 具体改了什么（工作区 vs 暂存区）
git diff --staged                       # 已 add 的改动（暂存区 vs 上次提交）

# 4. 分次提交（每个功能点一次提交，别攒一大堆）
git add src/views/Login.vue src/api/auth.js
git commit -m "feat: 添加登录页面和接口"

git add src/router/index.js
git commit -m "feat: 添加登录路由"

# 5. 推送到远程
git push -u origin feature/user-login
# -u 设置上游跟踪，之后直接 git push 就行

# 6. 在 GitHub/GitLab 上创建 Pull Request / Merge Request
# 7. 同事 Code Review → 合并 → 删除分支
```

---

## 四、分支管理

### 分支的本质

```
分支就是一个指向 commit 的指针（40 字节的文件）

main ──▶ commit C
                  ↑
feature ──▶ commit D（基于 C 创建的）

切换分支 = 移动 HEAD 指针 + 更新工作区文件
创建分支 = 创建一个新指针，指向当前 commit
删除分支 = 删除那个指针（commit 本身不会被删）
```

### 基本操作

```bash
git branch                      # 查看本地分支
git branch -a                   # 查看所有分支（含远程）
git branch feature/login        # 创建分支（不切换）
git checkout -b feature/login   # 创建并切换（常用）
git switch -c feature/login     # 同上（Git 2.23+ 推荐）

git branch -d feature/login     # 删除分支（已合并才能删）
git branch -D feature/login     # 强制删除（没合并也删）
git push origin --delete feature/login   # 删远程分支
```

### 场景：写到一半被叫去修 bug

```bash
# 方法 1：stash（存档当前改动）
git stash                        # 存档（工作区+暂存区的改动全存起来）
git stash -m "写到一半的登录功能"   # 带备注
git checkout hotfix/bug-123      # 切去修 bug
# ...修完 bug 提交推送...
git checkout feature/login       # 切回来
git stash pop                    # 恢复改动（取出并删除存档）

# stash 管理
git stash list                   # 查看所有存档
git stash pop                    # 恢复最近的存档
git stash apply stash@{1}        # 恢复指定存档（不删除）
git stash drop stash@{0}         # 删除指定存档

# 方法 2：worktree（同时开两个工作目录）
git worktree add ../hotfix hotfix/bug-123
# 在 ../hotfix 目录修 bug，互不影响
git worktree remove ../hotfix    # 修完删掉
```

---

## 五、撤销与回退

> 这是最容易搞混的部分。记住：**restore 管文件，reset 管提交，revert 生成新提交来撤销**。

### restore——撤销文件改动

```bash
# 场景：文件改乱了，想恢复到上次提交的样子
git restore src/login.vue       # 丢弃工作区改动（不可恢复！）

# 场景：git add 了不想提交的文件
git restore --staged src/test.js  # 从暂存区撤出（文件内容不变）

# 场景：恢复到某个特定提交的版本
git restore --source=abc1234 src/login.vue  # 从指定 commit 恢复文件
```

### reset——回退提交

```bash
# 三种模式的区别：
git reset --soft HEAD~1    # 撤回提交，改动留在暂存区（最安全）
git reset --mixed HEAD~1   # 撤回提交，改动留在工作区（默认模式）
git reset --hard HEAD~1    # 撤回提交，改动全丢（危险！）

# HEAD~1 = 上一个提交，HEAD~3 = 前三个提交
# 也可以用 commit hash：git reset --soft abc1234
```

```
reset 三种模式的效果：

                    暂存区    工作区
--soft HEAD~1        ✅ 保留    ✅ 保留    ← 最安全，重新 commit 就行
--mixed HEAD~1       ❌ 清空    ✅ 保留    ← 默认，需要重新 add + commit
--hard HEAD~1        ❌ 清空    ❌ 清空    ← 最危险，代码直接没了
```

### revert——生成新提交来撤销

```bash
# 场景：已经 push 到远程的提交需要撤销（不能用 reset）
git revert abc1234      # 生成一个新提交，内容是 abc1234 的反向操作
# 历史不变，只是多了一个"撤销"的提交
```

> **何时用哪个**：没 push → reset，已 push → revert。

### amend——修正最近一次提交

```bash
# 场景：提交信息写错了
git commit --amend -m "正确的提交信息"

# 场景：漏了文件
git add 漏掉的文件.js
git commit --amend --no-edit     # 追加到上次提交，不改信息
```

---

## 六、合并与变基

### merge——合并分支

```bash
git checkout main
git merge feature/login
# 如果没冲突：自动合并，生成一个 merge commit
# 如果有冲突：手动解决后 git add + git commit
```

### 冲突解决

```bash
# 合并时出现冲突，文件里会出现标记：
<<<<<<< HEAD
你的代码
=======
别人的代码
>>>>>>> feature/login

# 解决步骤：
# 1. 手动编辑文件，选择保留哪些代码（删掉 <<<< ==== >>>> 标记）
# 2. git add 冲突文件
# 3. git commit（会自动生成合并提交信息）

# 放弃合并（冲突太多不想合了）
git merge --abort
```

### rebase——变基

```bash
# rebase = 把你的提交"挪到"目标分支的最新后面
git checkout feature/login
git rebase main

# 效果：
# 合并前：  main: A-B-C    feature: A-B-D-E
# rebase 后：main: A-B-C    feature: A-B-C-D'-E'（D'E' 是新的 commit）
# 然后切到 main 快进合并：
git checkout main
git merge feature/login    # 快进合并，不产生 merge commit
```

### 交互式 rebase——整理提交历史

```bash
git rebase -i HEAD~3    # 整理最近 3 个提交

# 打开编辑器，可以：
# pick   → 保留提交
# squash → 合并到上一个提交（提交太碎可以合并）
# reword → 修改提交信息
# drop   → 删除提交
# 调整顺序 → 重新排列提交
```

### merge vs rebase vs squash

| | merge | rebase | squash merge |
|---|---|---|---|
| 历史 | 保留所有分叉和合并 | 线性历史 | 一个功能一个提交 |
| merge commit | 有 | 无 | 有（但只有一个提交） |
| 已 push 能用吗 | ✅ | ❌ 会改写历史 | ✅ |
| 适用场景 | 团队主分支合并 | 个人分支整理 | PR 合并到 main |

> **铁律：已经 push 到远程的提交不要 rebase**。会导致别人的代码和你的冲突。

---

## 七、远程协作

### fetch vs pull

```bash
git fetch origin          # 只下载远程更新，不动你的工作区（安全）
git pull origin main      # 下载 + 合并 = fetch + merge（方便但可能冲突）

# 推荐的安全流程：
git fetch origin
git log origin/main       # 先看看远程有啥新提交
git merge origin/main     # 确认没问题再合并
```

### PR / MR 流程（团队协作标准流程）

```
1. 从 main 创建功能分支：git checkout -b feature/xxx
2. 开发 + 提交 + push 到远程
3. 在 GitHub/GitLab 上创建 Pull Request（PR）/ Merge Request（MR）
4. 指定同事做 Code Review
5. 同事提意见 → 你在分支上改 → 推送 → PR 自动更新
6. Review 通过 → 合并到 main（通常用 Squash Merge）
7. 删除功能分支

# 如果 PR 期间 main 有新提交，需要同步：
git checkout feature/xxx
git pull origin main         # 合并 main 的最新代码到你的分支
# 解决冲突（如果有）→ 推送
git push
```

### 清理

```bash
git remote prune origin         # 清理本地已失效的远程分支引用
git branch --merged main | grep -v main | xargs git branch -d  # 删除已合并的本地分支
```

---

## 八、查看与检索

### log——查看提交历史

```bash
git log --oneline -10                    # 最近 10 条，简洁
git log --oneline --graph --all -20      # 分支图（最好设为别名 git lg）
git log --author="张三"                   # 只看某人的提交
git log --since="2024-01-01" --until="2024-03-01"  # 按日期范围
git log -- src/login.vue                 # 只看某文件的提交历史
git log -p src/login.vue                 # 看某文件每次提交的具体改动
```

### diff——查看差异

```bash
git diff                     # 工作区 vs 暂存区（还没 add 的改动）
git diff --staged            # 暂存区 vs 上次提交（已 add 待 commit 的改动）
git diff main feature/login  # 两个分支的差异
git diff abc1234 def5678     # 两个 commit 的差异
git diff HEAD~3              # 最近 3 个提交的累计改动
```

### blame——查看每行代码是谁写的

```bash
git blame src/login.vue          # 每行显示：commit hash + 作者 + 时间
git blame -L 10,20 src/login.vue # 只看第 10-20 行
```

### show——查看某次提交的详细信息

```bash
git show abc1234             # 看这个 commit 改了什么
git show abc1234:src/app.js  # 看这个 commit 时某个文件的完整内容
```

### bisect——二分查找引入 bug 的提交

```bash
# 场景：某个功能之前是好的，现在坏了，不知道哪次提交弄坏的
git bisect start
git bisect bad              # 标记当前是坏的
git bisect good abc1234     # 标记某个旧 commit 是好的
# Git 自动切到中间的 commit，你测试一下
git bisect good             # 这个是好的 → Git 继续缩小范围
git bisect bad              # 这个是坏的 → Git 继续缩小范围
# 最终 Git 告诉你是哪个 commit 引入的 bug
git bisect reset            # 结束
```

---

## 九、高级操作

### cherry-pick——摘取指定提交

```bash
# 场景：只想把某个 commit 从别的分支"摘"过来，不合并整个分支
git cherry-pick abc1234     # 把 abc1234 这个 commit 应用到当前分支
git cherry-pick abc1234 def5678  # 摘多个

# 场景：线上紧急修复，同时要应用到 dev 分支
# 在 hotfix 分支修好 → 合并到 main → cherry-pick 到 dev
```

### tag——打标签（版本号）

```bash
git tag v1.0.0                          # 轻量标签
git tag -a v1.0.0 -m "第一个正式版本"     # 附注标签（推荐）
git tag                                  # 查看所有标签
git push origin v1.0.0                   # 推送标签到远程
git push origin --tags                   # 推送所有标签

# 从标签创建分支（修复旧版本 bug）
git checkout -b hotfix/v1.0.1 v1.0.0
```

### submodule——子模块

```bash
# 场景：项目依赖另一个 Git 仓库（如公共组件库）
git submodule add git@github.com:user/common-lib.git libs/common
git submodule update --init --recursive  # 克隆后初始化子模块

# 更新子模块
cd libs/common
git pull origin main
cd ../..
git add libs/common
git commit -m "chore: 更新公共组件库"
```

### reflog——终极后悔药

```bash
# 场景：git reset --hard 后代码丢了
git reflog                   # 查看所有操作记录（包括已"删除"的 commit）
# abc1234 HEAD@{2}: commit: feat: 登录功能
git reset --hard abc1234     # 回到那个 commit，代码就回来了

# reflog 保留 90 天内的所有操作，几乎什么都能恢复
```

### .gitignore 忘了忽略

```bash
# 文件已经被跟踪了，加 .gitignore 不会自动取消跟踪
git rm --cached node_modules/ -r    # 从仓库删除但保留本地文件
echo "node_modules/" >> .gitignore
git add .gitignore
git commit -m "chore: 忽略 node_modules"
```

---

## 十、分支策略

### Git Flow（传统，适合大项目）

```
main ──────────────────────────── 只有稳定版本
  │                    ↑
  └─ develop ──────────┤── 日常开发
       │          ↑    │
       └─ feature/xxx ─┘   功能分支
       └─ hotfix/xxx ──→ main + develop   紧急修复
```

### GitHub Flow（简单，适合持续部署）

```
main ──────────────── 永远可部署
  │          ↑
  └─ feature/xxx ─┘   所有功能都从 main 开分支，通过 PR 合回
```

### Trunk-Based（极简，适合小团队）

```
main ──────────── 所有人直接提交到 main（或很短命的分支）
```

> **推荐**：大多数团队用 **GitHub Flow** 就够了——main 保持可发布，功能分支 + PR 合并。

---

## 十一、提交规范与 Hooks

### Conventional Commits（提交信息规范）

```
<type>(<scope>): <description>

类型（type）：
feat     新功能         feat: 添加用户登录功能
fix      修 bug         fix: 修复登录页密码显示问题
docs     文档           docs: 更新 API 文档
style    样式/格式      style: 调整按钮间距
refactor 重构           refactor: 重构登录逻辑
perf     性能优化       perf: 优化首页加载速度
test     测试           test: 添加登录单元测试
chore    杂务           chore: 升级依赖版本
ci       CI/CD          ci: 添加自动部署脚本
```

### Git Hooks + husky（自动检查）

```bash
# 安装 husky（在项目中）
npm install -D husky lint-staged
npx husky init

# pre-commit 钩子：提交前自动跑 lint
# .husky/pre-commit
npx lint-staged

# package.json 中配置 lint-staged
"lint-staged": {
  "*.{js,ts,vue}": ["eslint --fix", "prettier --write"],
  "*.{css,scss}": ["prettier --write"]
}

# 提交时自动格式化代码，不规范的代码提交不上去
```

---

## 十二、常见问题速查

| 问题 | 命令 |
|---|---|
| 文件改乱了，恢复 | `git restore 文件名` |
| add 了不想提交的文件 | `git restore --staged 文件名` |
| 提交信息写错了 | `git commit --amend -m "新信息"` |
| 提交到了错误的分支 | `git reset --soft HEAD~1` → stash → 切分支 → stash pop → commit |
| reset --hard 后悔了 | `git reflog` → `git reset --hard 目标hash` |
| 合并冲突了 | 手动编辑文件 → `git add` → `git commit` |
| 不想合并了 | `git merge --abort` |
| 远程分支本地没显示 | `git fetch origin` |
| 本地有过时的远程分支 | `git remote prune origin` |
| 已 push 的提交要撤销 | `git revert 目标hash` |
| 只想要某个提交 | `git cherry-pick 目标hash` |
| 忘了 .gitignore | `git rm --cached 文件` + 加 .gitignore |
| 查找是哪个提交引入的 bug | `git bisect` |

---

> **核心记住**：多开分支、勤提交、push 前 pull 一下、已 push 的不要 rebase。掌握这几条原则，基本不会出大问题。
