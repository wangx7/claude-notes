# React 精讲（Vue 开发者版）

> 你已经会 Vue 3 的 Composition API，这份文档用 Vue 做锚点，帮你最快理解 React。每个概念都对照 Vue 写法，看完能独立开发 React 项目，也能理解 React 的核心原理。

---

## 一、Vue vs React：思维转换

### 核心差异一览

| | Vue | React |
|---|---|---|
| 模板 | `<template>` HTML 模板 | **JSX**（JS 里写 HTML） |
| 响应式 | 自动追踪依赖（Proxy） | **不可变数据**（setState 整体替换） |
| 更新粒度 | 组件级精准更新（自动） | 组件树重新渲染（需手动优化） |
| 组件写法 | SFC（.vue 文件） | **函数**（普通 JS/TS 函数） |
| 状态 | `ref()` / `reactive()` | `useState()` |
| 副作用 | `watch` / `watchEffect` / `onMounted` | **useEffect（统一入口）** |
| 复用 | composable（useXxx） | 自定义 Hook（useXxx） |
| 路由 | Vue Router | React Router |
| 状态管理 | Pinia | Zustand / Redux |
| 指令 | v-if / v-for / v-model / v-show | **没有指令，全用 JS 表达式** |

### 核心差异：响应式 vs 不可变

```js
// Vue：直接修改，自动更新视图
const count = ref(0)
count.value++              // ✅ 直接改，视图自动更新

const user = reactive({ name: '张三', age: 25 })
user.name = '李四'          // ✅ 直接改属性

// React：不能直接改，必须用 setState 整体替换
const [count, setCount] = useState(0)
count++                    // ❌ 直接改无效！视图不会更新
setCount(count + 1)        // ✅ 必须调用 setter

const [user, setUser] = useState({ name: '张三', age: 25 })
user.name = '李四'          // ❌ 直接改无效！
setUser({ ...user, name: '李四' })  // ✅ 创建新对象替换
```

> **这是 Vue 转 React 最大的认知差异**：Vue 是"我改了数据，框架自动知道要更新"。React 是"我必须告诉框架数据变了，框架才更新"。

### 核心差异：模板 vs JSX

```html
<!-- Vue：HTML 模板 + 指令 -->
<template>
  <div v-if="show" class="box">
    <ul>
      <li v-for="item in list" :key="item.id">{{ item.name }}</li>
    </ul>
    <button @click="handleClick">点击</button>
  </div>
</template>
```

```jsx
// React：JSX（在 JS 里写 HTML）
function App() {
  return (
    show && (                          // v-if → JS 的 &&
      <div className="box">           {/* class → className */}
        <ul>
          {list.map(item => (          // v-for → JS 的 .map()
            <li key={item.id}>{item.name}</li>
          ))}
        </ul>
        <button onClick={handleClick}>点击</button>  {/* @click → onClick */}
      </div>
    )
  )
}
```

> **JSX 不是模板，是 JS 表达式**。没有特殊语法（v-if/v-for/v-model），全部用原生 JS 实现。

---

## 二、环境搭建

### 创建项目

```bash
# 用 Vite 创建（和 Vue 一样用 Vite）
npm create vite@latest my-react-app -- --template react-ts
cd my-react-app
npm install
npm run dev
```

### 项目结构

```
my-react-app/
├── index.html
├── package.json
├── vite.config.ts
├── tsconfig.json
├── src/
│   ├── main.tsx            # 入口文件（Vue 的 main.ts）
│   ├── App.tsx             # 根组件（Vue 的 App.vue）
│   ├── components/         # 组件
│   ├── hooks/              # 自定义 Hook（Vue 的 composables/）
│   ├── pages/              # 页面
│   ├── router/             # 路由
│   ├── store/              # 状态管理
│   └── assets/             # 静态资源
```

### 入口文件对比

```tsx
// React: src/main.tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
```

```ts
// Vue: src/main.ts（对照）
import { createApp } from 'vue'
import App from './App.vue'
createApp(App).mount('#app')
```

### JSX 基础语法

```tsx
function App() {
  const name = '张三'
  const isVip = true

  return (
    <div>
      {/* 插值：Vue 用 {{ }}，React 用 { } */}
      <h1>你好，{name}</h1>

      {/* 表达式都可以放在 { } 里 */}
      <p>状态：{isVip ? 'VIP' : '普通用户'}</p>
      <p>2 + 3 = {2 + 3}</p>
    </div>
  )
}
```

---

## 三、组件基础

### 函数组件

```tsx
// Vue 的 SFC：一个 .vue 文件 = 一个组件
// React：一个函数 = 一个组件

// React 组件就是一个返回 JSX 的函数
function Welcome() {
  return <h1>你好，世界</h1>
}

// 箭头函数写法（更常用）
const Welcome = () => {
  return <h1>你好，世界</h1>
}

// 使用
<Welcome />
```

### Props

```tsx
// Vue
// defineProps<{ name: string; age?: number }>()
// <Welcome name="张三" :age="25" />

// React：props 就是函数参数
interface WelcomeProps {
  name: string
  age?: number
}

const Welcome = ({ name, age = 18 }: WelcomeProps) => {
  return <h1>你好，{name}，{age}岁</h1>
}

// 使用（和 Vue 一样）
<Welcome name="张三" age={25} />
```

> **React 的 props 也是单向数据流**，子组件不能修改 props，和 Vue 一样。

### Children（插槽）

```tsx
// Vue 的默认插槽 <slot />
// React 用 children prop

const Card = ({ title, children }: { title: string; children: React.ReactNode }) => {
  return (
    <div className="card">
      <h2>{title}</h2>
      <div className="card-body">{children}</div>  {/* 相当于 <slot /> */}
    </div>
  )
}

// 使用
<Card title="用户信息">
  <p>姓名：张三</p>
  <p>年龄：25</p>
</Card>

// Vue 等价：
// <Card title="用户信息">
//   <p>姓名：张三</p>
//   <p>年龄：25</p>
// </Card>
```

### 具名插槽的替代

```tsx
// Vue 的具名插槽：<template #header>
// React 没有插槽，用 props 传 JSX

const Layout = ({ header, footer, children }: {
  header: React.ReactNode
  footer: React.ReactNode
  children: React.ReactNode
}) => {
  return (
    <div>
      <header>{header}</header>
      <main>{children}</main>
      <footer>{footer}</footer>
    </div>
  )
}

// 使用
<Layout
  header={<h1>页头</h1>}
  footer={<p>页脚</p>}
>
  <p>主内容</p>
</Layout>
```

---

## 四、JSX 语法详解

> React 没有 v-if、v-for、v-show、v-model，全部用 JS 表达式实现。

### 条件渲染（替代 v-if / v-show）

```tsx
function App() {
  const [isLogin, setIsLogin] = useState(false)
  const [role, setRole] = useState('user')

  return (
    <div>
      {/* v-if → && 短路 */}
      {isLogin && <p>欢迎回来</p>}

      {/* v-if / v-else → 三元表达式 */}
      {isLogin ? <UserPanel /> : <LoginForm />}

      {/* 多条件 → 提取变量或函数 */}
      {role === 'admin' && <AdminPanel />}
      {role === 'user' && <UserPanel />}
      {role === 'guest' && <GuestPanel />}

      {/* v-show → style 控制（DOM 不移除，只隐藏） */}
      <div style={{ display: isLogin ? 'block' : 'none' }}>
        只有登录才显示
      </div>
    </div>
  )
}
```

### 列表渲染（替代 v-for）

```tsx
function UserList() {
  const users = [
    { id: 1, name: '张三' },
    { id: 2, name: '李四' },
    { id: 3, name: '王五' },
  ]

  return (
    <ul>
      {/* v-for → .map()，key 写在 JSX 元素上 */}
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  )
}

// Vue 等价：
// <li v-for="user in users" :key="user.id">{{ user.name }}</li>
```

### 事件绑定（替代 @click）

```tsx
function App() {
  // 无参数
  const handleClick = () => { console.log('点击了') }

  // 有参数
  const handleDelete = (id: number) => { console.log('删除', id) }

  // 事件对象
  const handleInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    console.log(e.target.value)
  }

  return (
    <div>
      {/* @click → onClick */}
      <button onClick={handleClick}>点击</button>

      {/* 传参数：用箭头函数包一层 */}
      <button onClick={() => handleDelete(1)}>删除</button>

      {/* @input → onChange（React 的 onChange = Vue 的 @input，实时触发） */}
      <input onChange={handleInput} />
    </div>
  )
}
```

### 双向绑定（替代 v-model）

```tsx
// Vue：<input v-model="name" />  一行搞定
// React：没有 v-model，手动绑定 value + onChange（受控组件）

function App() {
  const [name, setName] = useState('')

  return (
    <div>
      <input
        value={name}                                   // 绑定值
        onChange={e => setName(e.target.value)}          // 监听变化
      />
      <p>输入了：{name}</p>
    </div>
  )
}
// 等价于 Vue 的 <input v-model="name" />
// React 更啰嗦，但更可控（可以在 onChange 里做格式化、校验等）
```

### 样式

```tsx
// 1. className（不能用 class，因为 class 是 JS 关键字）
<div className="container active">...</div>

// 2. 行内样式（对象，驼峰命名）
<div style={{ fontSize: '16px', backgroundColor: '#f0f0f0' }}>...</div>
// Vue: :style="{ fontSize: '16px', backgroundColor: '#f0f0f0' }"
// 完全一样，只是 Vue 用 :style，React 用 style={}

// 3. CSS Modules（推荐）
import styles from './App.module.css'
<div className={styles.container}>...</div>

// 4. 动态 className
<div className={`card ${isActive ? 'active' : ''}`}>...</div>
// Vue: :class="{ active: isActive }"
```

---

## 五、渲染流程与虚拟 DOM

> 了解 React 的渲染流程，才能知道为什么组件会重新渲染，以及怎么优化。

### 核心流程：JSX → Fiber → DOM

```
1. 触发更新（初次渲染或 setState）
2. Render 阶段（纯计算，可中断）：
   - 执行函数组件，返回新的 JSX
   - JSX 被编译成 React.createElement() 调用
   - 生成 Virtual DOM 树
   - 对比新旧 VDOM（Diff 算法）
   - 打上增删改的标记，生成 Fiber 树
3. Commit 阶段（不可中断）：
   - 把 Fiber 树上的标记一次性应用到真实 DOM 上
   - 触发 useEffect 等生命周期
```

### 对比 Vue

| 环节 | Vue | React |
|---|---|---|
| **VDOM 生成** | 模板编译时标记静态节点（PatchFlags），运行时跳过静态内容 | 每次渲染都执行整个函数组件，生成完整的 VDOM（无静态标记） |
| **重新渲染触发** | 依赖收集，精准知道哪个组件需要更新 | 默认从触发更新的组件开始，**向下递归渲染所有子组件**（除非手动优化） |
| **可中断渲染** | 同步渲染（DOM 树不大时没问题） | **Fiber 架构**：把渲染任务拆成小片，优先处理高优先级任务（如用户输入），避免页面卡顿 |

> **关键点**：React 的默认行为是"父组件更新，所有子组件都会重新执行"。这是 React 性能优化的核心痛点。

---

## 六、状态管理：useState

> React 中最常用的 Hook，对应 Vue 的 `ref()`。

### 基本用法

```tsx
function Counter() {
  // const [状态变量, 修改状态的函数] = useState(初始值)
  const [count, setCount] = useState(0)

  return (
    <button onClick={() => setCount(count + 1)}>
      {count}
    </button>
  )
}
```

### 不可变更新原则（非常重要！）

```tsx
// ❌ 错误示范（类似 Vue 的写法，但在 React 里无效）
const [user, setUser] = useState({ name: '张三', age: 25 })
const updateAge = () => {
  user.age = 26
  setUser(user) // 没用！React 对比的是对象的引用地址，地址没变，不触发渲染
}

// ✅ 正确示范（创建新对象替换旧对象）
const updateAgeRight = () => {
  setUser({ ...user, age: 26 })
}

// 数组也是一样
const [list, setList] = useState(['A', 'B'])

// ❌ 错误：直接修改原数组
list.push('C')
setList(list)

// ✅ 正确：创建新数组
setList([...list, 'C'])       // push
setList(list.filter(i => i !== 'A'))  // delete
setList(list.map(i => i === 'A' ? 'a' : i)) // update
```

> **提示**：如果觉得不可变更新太麻烦，可以用 `Immer` 库，它允许你用直接修改数据的方式写不可变更新（类似 Vue）。

### 函数式更新（解决闭包陷阱）

```tsx
const [count, setCount] = useState(0)

const handleClick = () => {
  // 如果连续调三次：
  setCount(count + 1)
  setCount(count + 1)
  setCount(count + 1)
  // 结果 count 只是 1！因为每次执行时，闭包里的 count 都是 0
}

const handleClickRight = () => {
  // 用函数式更新，参数是前一个状态的值
  setCount(prev => prev + 1)
  setCount(prev => prev + 1)
  setCount(prev => prev + 1)
  // 结果是 3
}
```

---

## 七、useState 原理

> 面试高频：为什么 Hooks 必须在顶层调用，不能放在 if 里？

### Hooks 内部是用链表存的

```tsx
function App() {
  const [name, setName] = useState('张三') // 节点 1
  const [age, setAge] = useState(25)     // 节点 2
  const [isVip, setIsVip] = useState(false) // 节点 3
}
```

React 内部并不按名字记录这些状态，而是记录一个**链表**：
`{ value: '张三', next: -> { value: 25, next: -> { value: false } } }`

每次组件重新渲染时，React 会**按顺序**从链表中读取状态。

### 如果放在 if 里：

```tsx
function App() {
  const [name, setName] = useState('张三') // 节点 1

  if (name === '张三') {
    const [age, setAge] = useState(25)     // 节点 2
  }

  const [isVip, setIsVip] = useState(false) // 节点 3
}
```

1. 第一次渲染（name 是张三）：存了 3 个节点（name, age, isVip）
2. 触发 setName('李四')，组件重新执行
3. 第二次渲染：
   - 第一步取 name：'李四'（正常）
   - if 条件不成立，跳过 age
   - 下一步取 isVip 时，React 还是按之前的链表去取，拿到了节点 2（age 的 25）
   - **全乱套了！**

> **铁律**：Hooks 必须在组件的最外层调用，不能在条件语句、循环或嵌套函数中调用。可以用 `eslint-plugin-react-hooks` 帮你检查。

---

## 八、useEffect——副作用与生命周期

> Vue 有 onMounted、onUpdated、onUnmounted、watch、watchEffect 五个钩子。React 用 **一个 useEffect** 覆盖所有场景。

### 基本结构

```tsx
useEffect(() => {
  // 副作用逻辑（组件挂载或依赖变化后执行）

  return () => {
    // 清理函数（组件卸载或下次 Effect 执行前调用）
  }
}, [依赖数组])
```

### 对照 Vue 的各个钩子

```tsx
// Vue: onMounted（组件挂载后执行一次）
onMounted(() => { fetchData() })

// React: 依赖数组为空数组，只在挂载时执行一次
useEffect(() => {
  fetchData()
}, [])   // ← 空数组

// ─────────────────────────────────

// Vue: onUnmounted（组件卸载时清理）
onUnmounted(() => { clearInterval(timer) })

// React: 返回清理函数
useEffect(() => {
  const timer = setInterval(() => console.log('tick'), 1000)
  return () => clearInterval(timer)  // ← 清理函数
}, [])

// ─────────────────────────────────

// Vue: watch(source, callback)（依赖变化时执行）
watch(userId, (newVal) => { fetchUser(newVal) })

// React: 依赖数组里放要监听的变量
useEffect(() => {
  fetchUser(userId)
}, [userId])   // ← userId 变化时重新执行

// ─────────────────────────────────

// Vue: watchEffect（自动追踪依赖）
watchEffect(() => { console.log(a.value, b.value) })

// React: 不写依赖数组（每次渲染后都执行，不推荐）
useEffect(() => { console.log(a, b) })
// 一般还是明确写依赖数组
```

### 常见场景

```tsx
function UserDetail({ userId }: { userId: number }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // 场景 1：请求数据（userId 变化时重新请求）
  useEffect(() => {
    setLoading(true)
    fetchUser(userId).then(data => {
      setUser(data)
      setLoading(false)
    })
  }, [userId])   // userId 变 → 重新请求

  // 场景 2：事件监听（挂载时添加，卸载时移除）
  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth)
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  // 场景 3：设置 document.title
  useEffect(() => {
    document.title = user ? user.name : '加载中...'
  }, [user])

  if (loading) return <p>加载中...</p>
  return <div>{user?.name}</div>
}
```

### 依赖数组的三种形式

```tsx
useEffect(() => { ... })            // 没有依赖数组：每次渲染后都执行（很少用）
useEffect(() => { ... }, [])        // 空数组：只在挂载时执行一次
useEffect(() => { ... }, [a, b])    // 有值：a 或 b 变化时执行
```

> **依赖数组漏写变量是常见 bug**：Effect 里用到了哪些 state/props，就要把它们写进依赖数组。用 `eslint-plugin-react-hooks` 的 `exhaustive-deps` 规则可以自动检测。

### 异步请求的竞态问题

```tsx
// 问题：快速切换 userId（如翻页），旧请求的结果可能比新请求晚回来
useEffect(() => {
  let cancelled = false

  fetchUser(userId).then(data => {
    if (!cancelled) setUser(data)  // 如果已取消，不更新状态
  })

  return () => { cancelled = true }  // 清理：标记为已取消
}, [userId])
```

---

## 九、Hooks 全家桶

### useMemo——缓存计算结果（对应 Vue 的 computed）

```tsx
// Vue: const total = computed(() => list.value.reduce((a, b) => a + b.price, 0))

// React:
const total = useMemo(() => {
  return list.reduce((acc, item) => acc + item.price, 0)
}, [list])  // list 变才重新计算

// 什么时候用 useMemo？
// 1. 计算量大（如大列表过滤排序）
// 2. 返回值要作为其他 Hook 的依赖
// 不要过度使用——简单字符串拼接不需要
```

### useCallback——缓存函数引用

```tsx
// 问题：每次组件重新渲染，函数都会重新创建（引用地址变了）
// 若把函数作为 props 传给子组件，子组件会不必要地重新渲染

const handleClick = useCallback(() => {
  doSomething(id)
}, [id])   // 只有 id 变才重新创建函数

// ⚠️ useCallback 需配合 React.memo 才有效（见性能优化章节）
```

### useRef——引用 DOM 或存可变值

```tsx
function App() {
  // 用途 1：访问 DOM（类似 Vue 的 template ref）
  const inputRef = useRef<HTMLInputElement>(null)
  const focus = () => inputRef.current?.focus()

  // 用途 2：存储不触发渲染的值
  // 修改 ref.current 不会触发重新渲染（区别于 useState）
  const timerRef = useRef<number>(0)
  const start = () => { timerRef.current = window.setInterval(() => {}, 1000) }
  const stop = () => clearInterval(timerRef.current)

  // 用途 3：保存上一次的值（类似 Vue watch 的 oldValue）
  const prevCountRef = useRef(count)
  useEffect(() => { prevCountRef.current = count })
  const prevCount = prevCountRef.current  // 上一次渲染时的 count

  return <input ref={inputRef} />
}
```

> **useState vs useRef**：两者都能存值。`useState` 变化触发重新渲染；`useRef` 变化不触发。定时器 ID、WebSocket 实例等"不影响 UI 的值"用 useRef。

### useContext——跨组件传值（对应 Vue 的 provide/inject）

```tsx
// 1. 创建 Context（通常放在单独文件）
interface ThemeContextType {
  theme: 'light' | 'dark'
  setTheme: (t: 'light' | 'dark') => void
}
const ThemeContext = createContext<ThemeContextType | null>(null)

// 2. 父组件提供值（对应 Vue 的 provide()）
function App() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light')
  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      <Layout />
    </ThemeContext.Provider>
  )
}

// 3. 封装成自定义 Hook（推荐）
function useTheme() {
  const ctx = useContext(ThemeContext)
  if (!ctx) throw new Error('useTheme 必须在 ThemeContext.Provider 内使用')
  return ctx
}

// 4. 任意子组件消费（对应 Vue 的 inject()）
function Button() {
  const { theme, setTheme } = useTheme()
  return (
    <button
      className={theme}
      onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
    >
      切换主题
    </button>
  )
}
```

---

## 十、Fiber 架构与 Diff 算法

> React 16 用 Fiber 重写了核心引擎。理解 Fiber 才能真正理解 React 的调度机制和并发模式。

### 为什么要有 Fiber

```
React 15 之前：Stack Reconciler（同步递归）
  渲染一棵大的组件树时，JS 会一直占用主线程
  用户交互（点击/输入）无法响应，页面卡顿

React 16+ Fiber 架构：
  把渲染任务拆成一个个"工作单元"（Fiber 节点）
  每处理完一个工作单元，就检查有没有更高优先级的任务
  有 → 暂停当前工作，先处理高优先级任务（如用户输入）
  没有 → 继续处理下一个工作单元
```

### Fiber 节点的数据结构

```
每个组件对应一个 Fiber 节点，包含：
{
  type: 'div' | App | 函数组件,  // 组件类型
  key: 'list-item-1',             // diff 用的 key
  stateNode: DOM节点 | 组件实例,  // 对应的真实节点

  // 链表结构（不用递归树，而是链表，方便暂停和恢复）
  return: 父 Fiber,
  child: 第一个子 Fiber,
  sibling: 下一个兄弟 Fiber,

  // 状态（hooks 就挂在这里！）
  memoizedState: Hook链表,

  // 更新标记
  flags: Placement | Update | Deletion,
}
```

> **Fiber 链表 vs 普通树的区别**：普通树用递归遍历，一旦开始就停不下来。Fiber 链表可以保存"当前处理到哪个节点"，随时暂停恢复。

### Diff 算法

```tsx
// React Diff 的三个原则（和 Vue 类似）：
// 1. 不同类型的元素产生不同的树（直接删除重建，不 diff）
// 2. 同一层级的元素通过 key 来匹配
// 3. 只对同层元素做 diff，不跨层比较

// key 的作用：
// 没有 key：React 按位置匹配，顺序变了就全量重建
const list = items.map(item => <Item>{item.name}</Item>)  // ❌ 没 key

// 有 key：React 按 key 匹配，能复用移动的元素
const list = items.map(item => <Item key={item.id}>{item.name}</Item>)  // ✅

// ❌ 不要用 index 做 key（列表有增删时 index 变，等于没有 key）
const list = items.map((item, i) => <Item key={i}>{item.name}</Item>)  // ❌
```

### React Diff vs Vue Diff

| | React Diff | Vue 3 Diff |
|---|---|---|
| 算法 | 单端从左向右扫描 | 双端 + 最长递增子序列（LIS） |
| 移动节点优化 | 较少 | 更好（LIS 算法减少 DOM 移动） |
| 静态节点跳过 | 无（每次都 diff） | 有（编译时标记，运行时跳过） |
| 整体性能 | 相对较低（靠 key 和 memo 弥补） | 更高（编译期优化） |

---

## 十一、组件通信

> React 没有 Vue 的 emits，子组件通过回调函数向父组件传值。

### Props 向下 + 回调向上（最基础）

```tsx
// 父组件
function Parent() {
  const [count, setCount] = useState(0)

  // 传回调函数给子组件（替代 Vue 的 emits）
  const handleChange = (newCount: number) => {
    setCount(newCount)
  }

  return <Child count={count} onChange={handleChange} />
}

// 子组件
function Child({ count, onChange }: { count: number; onChange: (n: number) => void }) {
  return (
    <button onClick={() => onChange(count + 1)}>
      {count}
    </button>
  )
}
// Vue 等价：子组件 emit('change', count + 1)，父组件 @change="handleChange"
```

### 状态提升

```tsx
// 两个兄弟组件需要共享状态 → 把 state 提升到共同父组件

// ❌ 两个组件各自有 state，无法同步
function SearchInput() { const [q, setQ] = useState('') }
function SearchResult() { /* 怎么拿到 q？ */ }

// ✅ 状态提升到父组件
function Page() {
  const [query, setQuery] = useState('')
  return (
    <>
      <SearchInput query={query} onSearch={setQuery} />
      <SearchResult query={query} />
    </>
  )
}
```

### Context（跨层传值）

见第九章 useContext，适合主题、语言、用户信息等全局数据。

### useReducer——复杂状态管理

```tsx
// 当 state 逻辑复杂（多个子状态、状态之间有关联），用 useReducer 代替 useState
// 类似 Pinia 的 actions，把状态更新逻辑集中管理

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'reset'; payload: number }

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'increment': return state + 1
    case 'decrement': return state - 1
    case 'reset': return action.payload
    default: return state
  }
}

function Counter() {
  const [count, dispatch] = useReducer(reducer, 0)
  return (
    <div>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <span>{count}</span>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'reset', payload: 0 })}>重置</button>
    </div>
  )
}
```

---

## 十二、自定义 Hook

> 自定义 Hook = Vue 的 Composable。把可复用的逻辑抽出来，名字必须以 `use` 开头。

### 基本示例

```tsx
// 封装请求逻辑（类似 Vue 的 useFetch composable）
function useUser(userId: number) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    setLoading(true)
    setError(null)
    fetchUser(userId)
      .then(setUser)
      .catch(setError)
      .finally(() => setLoading(false))
  }, [userId])

  return { user, loading, error }
}

// 使用
function UserCard({ userId }: { userId: number }) {
  const { user, loading, error } = useUser(userId)
  if (loading) return <p>加载中...</p>
  if (error) return <p>出错了</p>
  return <p>{user?.name}</p>
}
```

### 常用自定义 Hook

```tsx
// useLocalStorage：持久化到 localStorage
function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    const stored = localStorage.getItem(key)
    return stored ? JSON.parse(stored) : initialValue
  })

  const set = (newValue: T) => {
    setValue(newValue)
    localStorage.setItem(key, JSON.stringify(newValue))
  }

  return [value, set] as const
}

// useDebounce：防抖（搜索框常用）
function useDebounce<T>(value: T, delay = 300): T {
  const [debouncedValue, setDebouncedValue] = useState(value)
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(timer)
  }, [value, delay])
  return debouncedValue
}

// 使用
function SearchBox() {
  const [query, setQuery] = useState('')
  const debouncedQuery = useDebounce(query, 500)  // 输入停 500ms 后才触发搜索

  useEffect(() => {
    if (debouncedQuery) fetchResults(debouncedQuery)
  }, [debouncedQuery])

  return <input value={query} onChange={e => setQuery(e.target.value)} />
}
```

---

## 十三、React Router

> 对应 Vue Router。核心概念完全一致，只是 API 不同。

### 安装与配置

```bash
npm install react-router-dom
```

```tsx
// src/main.tsx
import { BrowserRouter } from 'react-router-dom'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <BrowserRouter>
    <App />
  </BrowserRouter>
)
```

### 路由配置

```tsx
// src/App.tsx
import { Routes, Route, Navigate } from 'react-router-dom'

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/users" element={<UserListPage />} />
      <Route path="/users/:id" element={<UserDetailPage />} />
      <Route path="/login" element={<LoginPage />} />
      {/* 重定向 */}
      <Route path="/home" element={<Navigate to="/" replace />} />
      {/* 404 */}
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

// Vue Router 等价：
// { path: '/users/:id', component: UserDetailPage }
```

### 嵌套路由（对应 Vue Router 的 children）

```tsx
function App() {
  return (
    <Routes>
      <Route path="/dashboard" element={<DashboardLayout />}>
        {/* 子路由，渲染在 <Outlet /> 位置 */}
        <Route index element={<DashboardHome />} />       {/* /dashboard */}
        <Route path="users" element={<UserList />} />     {/* /dashboard/users */}
        <Route path="settings" element={<Settings />} />  {/* /dashboard/settings */}
      </Route>
    </Routes>
  )
}

// DashboardLayout 里用 <Outlet /> 渲染子路由（对应 Vue 的 <RouterView />）
function DashboardLayout() {
  return (
    <div>
      <Sidebar />
      <main><Outlet /></main>   {/* 子路由渲染在这里 */}
    </div>
  )
}
```

### 路由 Hooks

```tsx
function UserDetail() {
  // 获取路由参数（对应 Vue 的 useRoute().params）
  const { id } = useParams<{ id: string }>()

  // 获取查询参数（对应 Vue 的 useRoute().query）
  const [searchParams, setSearchParams] = useSearchParams()
  const page = searchParams.get('page') ?? '1'

  // 编程式导航（对应 Vue 的 useRouter().push()）
  const navigate = useNavigate()
  const goBack = () => navigate(-1)
  const goHome = () => navigate('/')
  const goUser = (id: number) => navigate(`/users/${id}`)

  // 获取当前路由信息（对应 Vue 的 useRoute()）
  const location = useLocation()
  console.log(location.pathname)   // '/users/123'
}
```

### 路由守卫（对应 Vue Router 的 beforeEach）

```tsx
// React Router 没有内置守卫，用组件包装实现
function AuthGuard({ children }: { children: React.ReactNode }) {
  const isLogin = useAuthStore(state => state.isLogin)
  const location = useLocation()

  if (!isLogin) {
    // 未登录跳转登录页，保存来源路由
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  return <>{children}</>
}

// 使用
<Route path="/dashboard" element={
  <AuthGuard>
    <DashboardLayout />
  </AuthGuard>
}>
```

---

## 十四、Zustand 状态管理

> 对应 Vue 的 Pinia。比 Redux 简单得多，API 和 Pinia 非常像。

### 安装

```bash
npm install zustand
```

### 基础用法（和 Pinia 对比）

```tsx
// Pinia store
export const useUserStore = defineStore('user', () => {
  const user = ref(null)
  const isLogin = computed(() => !!user.value)
  function login(userData) { user.value = userData }
  function logout() { user.value = null }
  return { user, isLogin, login, logout }
})

// Zustand store（几乎一模一样的思路）
import { create } from 'zustand'

interface UserStore {
  user: User | null
  isLogin: () => boolean
  login: (user: User) => void
  logout: () => void
}

export const useUserStore = create<UserStore>((set, get) => ({
  user: null,
  isLogin: () => !!get().user,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
}))

// 使用（和 Pinia 一样，直接在组件里调用）
function Header() {
  const { user, isLogin, logout } = useUserStore()
  return (
    <header>
      {isLogin() ? (
        <>
          <span>{user?.name}</span>
          <button onClick={logout}>退出</button>
        </>
      ) : (
        <a href="/login">登录</a>
      )}
    </header>
  )
}
```

### 按需订阅（性能优化）

```tsx
// 只订阅需要的部分，避免不必要的重新渲染
const user = useUserStore(state => state.user)        // 只要 user
const logout = useUserStore(state => state.logout)    // 只要 logout 函数

// 订阅多个（浅比较）
const { user, isLogin } = useUserStore(
  state => ({ user: state.user, isLogin: state.isLogin }),
  shallow  // 用浅比较，避免每次都返回新对象
)
```

### 持久化到 localStorage

```tsx
import { persist } from 'zustand/middleware'

export const useUserStore = create<UserStore>()(
  persist(
    (set) => ({
      user: null,
      login: (user) => set({ user }),
      logout: () => set({ user: null }),
    }),
    { name: 'user-store' }  // localStorage 的 key
  )
)
// 刷新页面后状态自动恢复，和 Pinia 的 persist 插件一样
```

---

## 十五、批量更新与并发模式

### 批量更新（React 18 新特性）

```tsx
// React 17 及之前：只在 React 事件处理器里自动批量更新
// 在 setTimeout、Promise、原生事件里不批量
setTimeout(() => {
  setCount(c => c + 1)  // 触发一次渲染
  setName('李四')        // 再触发一次渲染（React 17 是两次渲染！）
}, 1000)

// React 18：任何地方都自动批量更新（只触发一次渲染）
// 不需要手动处理，升级到 React 18 就自动生效

// 如果某个更新不想批量（很少用）：
import { flushSync } from 'react-dom'
flushSync(() => setCount(c => c + 1))  // 立即触发渲染
flushSync(() => setName('李四'))       // 立即触发渲染（两次）
```

### 并发模式（React 18）

```tsx
// useTransition：把低优先级更新标记为"可中断"
// 场景：搜索时，输入框响应是高优先级，搜索结果更新是低优先级

function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const [isPending, startTransition] = useTransition()

  const handleSearch = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setQuery(value)  // 高优先级：输入框立即更新

    startTransition(() => {
      // 低优先级：如果有更紧急的任务（如用户继续输入），这里可以被中断
      setResults(searchItems(value))
    })
  }

  return (
    <div>
      <input value={query} onChange={handleSearch} />
      {isPending && <p>搜索中...</p>}
      <ResultList results={results} />
    </div>
  )
}

// useDeferredValue：类似 useTransition，但用于延迟派生值
function SearchPage() {
  const [query, setQuery] = useState('')
  const deferredQuery = useDeferredValue(query)  // 延迟更新（低优先级）

  return (
    <div>
      <input value={query} onChange={e => setQuery(e.target.value)} />
      {/* deferredQuery 变化较慢，不会阻塞输入框 */}
      <ExpensiveResultList query={deferredQuery} />
    </div>
  )
}
```

> **和 Vue 的对比**：Vue 3 的响应式系统可以精确追踪依赖，自动做到按需更新。React 的并发模式是另一种思路——通过优先级调度，让紧急任务（用户交互）优先响应。

---

## 十六、性能优化

> React 默认"父组件更新，所有子组件重新渲染"，性能优化就是减少不必要的渲染。

### React.memo——阻止子组件不必要渲染

```tsx
// 问题：父组件更新 → 子组件重新渲染（即使 props 没变）
function Parent() {
  const [count, setCount] = useState(0)
  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      <Child name="张三" />  {/* count 变 → Child 也重新渲染，没必要 */}
    </div>
  )
}

// 解决：用 React.memo 包裹子组件，props 没变就不重新渲染
const Child = React.memo(({ name }: { name: string }) => {
  console.log('Child 渲染')
  return <p>{name}</p>
})
// 类似 Vue 中组件天然的按需更新（Vue 通过依赖追踪自动实现，React 需要手动 memo）
```

### useMemo + useCallback 配合 memo

```tsx
// React.memo 默认用浅比较，如果 props 是对象/函数，每次都是新引用 → memo 失效
const Parent = () => {
  const [count, setCount] = useState(0)

  // ❌ 每次渲染 style 都是新对象，Child 的 memo 失效
  const style = { color: 'red' }
  const handleClick = () => doSomething()

  // ✅ 用 useMemo/useCallback 稳定引用
  const style = useMemo(() => ({ color: 'red' }), [])
  const handleClick = useCallback(() => doSomething(), [])

  return <Child style={style} onClick={handleClick} />
}

const Child = React.memo(({ style, onClick }) => { ... })
```

### 懒加载（对应 Vue 的异步组件）

```tsx
// Vue：() => import('./HeavyComponent.vue')
// React：React.lazy

const HeavyPage = lazy(() => import('./pages/HeavyPage'))

function App() {
  return (
    <Suspense fallback={<p>加载中...</p>}>
      <Routes>
        <Route path="/heavy" element={<HeavyPage />} />
      </Routes>
    </Suspense>
  )
}
// 访问 /heavy 路由时才下载对应 JS 包，减少首屏体积
```

### 虚拟列表（长列表性能）

```tsx
// 场景：渲染 10000 条数据
// 问题：全部渲染到 DOM 很卡，用虚拟列表只渲染可见区域

// 安装：npm install react-window
import { FixedSizeList } from 'react-window'

function VirtualList({ items }: { items: string[] }) {
  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>{items[index]}</div>
  )

  return (
    <FixedSizeList
      height={600}       // 容器高度
      width="100%"
      itemCount={items.length}
      itemSize={50}      // 每行高度
    >
      {Row}
    </FixedSizeList>
  )
}
```

---

## 十七、TypeScript 集成、常见坑与面试题

### TS 常用类型写法

```tsx
// 组件 Props 类型
interface ButtonProps {
  label: string
  onClick: () => void
  variant?: 'primary' | 'secondary'
  children?: React.ReactNode
  style?: React.CSSProperties
}

// 事件类型
const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {}
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {}
const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {}

// useState 有初始值时会自动推断类型
const [count, setCount] = useState(0)          // number
const [name, setName] = useState('')           // string

// 初始值为 null 时需要手动标注
const [user, setUser] = useState<User | null>(null)
const [list, setList] = useState<User[]>([])

// useRef 类型
const ref = useRef<HTMLInputElement>(null)     // DOM ref，初始 null
const valueRef = useRef<number>(0)             // 存值，有初始值
```

### 常见坑

```tsx
// 坑 1：闭包陷阱（最常见）
const [count, setCount] = useState(0)
useEffect(() => {
  const timer = setInterval(() => {
    console.log(count)  // 永远是 0！闭包捕获了初始值
    setCount(count + 1) // 一直是 0 + 1 = 1
  }, 1000)
  return () => clearInterval(timer)
}, [])  // 空数组依赖 → 只执行一次 → count 永远是初始值

// 解决：用函数式更新 或 把 count 加入依赖数组
setCount(prev => prev + 1)  // ✅ 始终用最新值

// 坑 2：useEffect 中请求不取消（竞态问题，见第八章）

// 坑 3：在 JSX 中直接改 state（不可变原则，见第六章）

// 坑 4：忘了给列表加 key，或用 index 做 key

// 坑 5：React.memo 失效（props 中有对象/函数，没用 useMemo/useCallback）
```

### 面试高频题

**Q：React 为什么不能直接修改 state？**
A：React 通过 Object.is 比较新旧 state 来决定是否重新渲染。直接修改不改变引用地址，React 认为没有变化，不会触发渲染。必须用 setState 传入新的引用。

**Q：Hooks 为什么不能在条件语句中调用？**
A：Hooks 内部通过链表按顺序存储状态。每次渲染都必须按相同顺序调用 Hooks，保证链表的对应关系不乱。放在条件语句里会导致顺序变化，链表错位。

**Q：useEffect 的依赖数组有什么用？**
A：控制 Effect 的执行时机。空数组 → 只在挂载时执行一次；有值 → 依赖变化时重新执行；不传 → 每次渲染后执行。

**Q：useMemo 和 useCallback 的区别？**
A：useMemo 缓存的是计算结果（值），useCallback 缓存的是函数引用。`useCallback(fn, deps)` 等价于 `useMemo(() => fn, deps)`。

**Q：React.memo、useMemo、useCallback 分别解决什么问题？**
A：React.memo 阻止子组件因父组件更新而不必要地重新渲染；useMemo 避免每次渲染都重复进行昂贵的计算；useCallback 稳定函数引用，配合 React.memo 使用。

**Q：React 18 的并发模式解决了什么问题？**
A：解决了大量状态更新时 UI 卡顿的问题。通过 Fiber 架构将渲染任务拆分为可中断的小单元，优先处理高优先级任务（用户输入），低优先级更新（如搜索结果）可以被中断。

---

> **Vue 转 React 最需要转变的三个思维**：
> 1. **不可变数据**——不直接改 state，永远用 setState 产生新值
> 2. **手动优化**——Vue 自动追踪依赖，React 需要用 memo/useMemo/useCallback 手动告诉框架"不用重新渲染"
> 3. **一切皆 JS**——没有指令（v-if/v-for/v-model），全用 JS 表达式和原生事件实现
