# Vue 2 深度精讲

> **阅读目标**：读完本文，你将获得与阅读 Vue 2 源码等价的理解深度，不再需要翻源码。
>
> **阅读建议**：第一章是全局地图，后续每一章都是地图上某个区域的放大。遇到不理解的地方，回来看第一章的全链路图。

---

## 一、全局视角：Vue 2 从你写下代码到页面显示，到底发生了什么

这一章是整篇文章的**骨架**。Vue 2 所有的 API、所有的原理，最终都挂在下面这条链路上。

### 1.1 全链路总览

```
你写的 .vue 文件
  │
  ▼ ① 构建时编译（vue-loader / vite-plugin-vue）
  │
  ├─ template  ──→  render 函数（JS 代码）
  ├─ script    ──→  组件选项对象（data/methods/computed...）
  └─ style     ──→  CSS 文件（scoped 会加属性选择器）
  │
  ▼ ② 运行时初始化（new Vue() 或组件实例化）
  │
  ├─ initLifecycle()     建立父子关系（$parent/$children）
  ├─ initEvents()        处理父组件传来的事件监听
  ├─ initRender()        挂载 $createElement、$slots
  │   ▼ 触发 beforeCreate
  ├─ initInjections()    解析 inject（从祖先找 provide）
  ├─ initState()         ★ 核心：响应式化 props → methods → data → computed → watch
  ├─ initProvide()       暴露 provide 给后代
  │   ▼ 触发 created
  │
  ▼ ③ 挂载（vm.$mount()）
  │
  ├─ 触发 beforeMount
  ├─ 创建渲染 Watcher ──→ 调用 render 函数
  │   │
  │   ▼ ④ render 函数执行
  │   │
  │   ├─ 读取 this.xxx ──→ 触发 getter ──→ 依赖收集（Dep.depend()）
  │   └─ 返回 VNode 树（虚拟 DOM）
  │
  ▼ ⑤ patch（首次渲染）
  │
  ├─ VNode → 创建真实 DOM 节点
  ├─ 插入到页面
  │   ▼ 触发 mounted
  │
  ▼ ⑥ 数据变更触发更新
  │
  ├─ this.xxx = newVal ──→ 触发 setter ──→ dep.notify()
  ├─ 渲染 Watcher 入队（queueWatcher，去重）
  ├─ nextTick 微任务中批量执行
  │   ▼ 触发 beforeUpdate
  ├─ 重新调用 render 函数 ──→ 新 VNode 树
  ├─ patch（新旧 VNode 对比，即 Diff）──→ 最小化 DOM 操作
  │   ▼ 触发 updated
  │
  ▼ ⑦ 销毁（vm.$destroy()）
  │
  ├─ 触发 beforeDestroy
  ├─ 移除所有 Watcher、解绑指令、移除事件
  └─ 触发 destroyed
```

### 1.2 六个核心模块

上面的链路拆成六大模块，也是本文后续章节的脉络：

| 模块 | 解决什么问题 | 对应源码目录 | 本文章节 |
|------|-------------|-------------|---------|
| **编译器**（Compiler） | 把 template 变成 render 函数 | `src/compiler/` | 第四章 |
| **响应式**（Reactivity） | 数据变了怎么知道、通知谁 | `src/core/observer/` | 第五章 |
| **渲染器**（Renderer） | render 函数怎么生成 VNode | `src/core/vdom/` | 第七章 |
| **Diff / Patch** | 新旧 VNode 怎么对比、怎么更新 DOM | `src/core/vdom/patch.js` | 第七章 |
| **组件系统** | 组件怎么创建、通信、销毁 | `src/core/instance/` | 第三、八、九、十章 |
| **插件系统** | Router / Vuex 怎么接入 Vue | `src/core/global-api/` | 第十四、十五章 |

### 1.3 源码目录结构

```
vue/src/
├── compiler/           # 模板编译器
│   ├── parser/         #   模板 → AST（解析）
│   ├── optimizer.js    #   标记静态节点（优化）
│   └── codegen/        #   AST → render 函数代码（生成）
│
├── core/               # 运行时核心
│   ├── instance/       #   Vue 实例：init、state、render、lifecycle、events
│   ├── observer/       #   响应式系统：Observer、Dep、Watcher
│   ├── vdom/           #   虚拟 DOM：VNode、patch、diff
│   ├── global-api/     #   全局 API：Vue.use、Vue.mixin、Vue.component
│   └── components/     #   内置组件：keep-alive
│
├── platforms/          # 平台相关
│   ├── web/            #   浏览器平台的入口、编译、运行时
│   └── weex/           #   Weex 平台（移动端）
│
└── shared/             # 工具函数
```

### 1.4 关键概念速查表

在进入具体章节前，先建立这些概念的初步印象：

| 概念 | 一句话解释 | 详见 |
|------|-----------|------|
| **Observer** | 递归遍历对象，用 `Object.defineProperty` 把每个属性变成 getter/setter | 第五章 |
| **Dep** | 依赖收集器，每个响应式属性有一个 Dep 实例，存储谁在用这个属性 | 第五章 |
| **Watcher** | 观察者，分三种：渲染 Watcher、计算 Watcher、用户 Watcher | 第五、六章 |
| **VNode** | 虚拟 DOM 节点，用 JS 对象描述一个 DOM 节点 | 第七章 |
| **patch** | 对比新旧 VNode，计算最小 DOM 操作并执行 | 第七章 |
| **render 函数** | 执行后返回 VNode 树，由模板编译生成或手写 | 第四章 |
| **nextTick** | 把回调推入微任务队列，等当前同步代码和 DOM 更新完再执行 | 第十六章 |

> 💡 **心智模型**：Vue 2 的一切都围绕一个循环——**render → VNode → patch → DOM → 用户交互 → 数据变更 → 触发 setter → notify Watcher → 重新 render**。理解了这个循环，所有 API 都是自然推导出来的。

---

## 二、环境搭建与项目结构

### 2.1 创建项目

```bash
# 安装 Vue CLI（全局只需一次）
npm install -g @vue/cli

# 创建 Vue 2 项目（选择 Vue 2 预设）
vue create my-project

# 启动开发服务器
cd my-project
npm run serve        # 默认 http://localhost:8080
```

### 2.2 项目目录解读

```
my-project/
├── public/
│   └── index.html          # 唯一的 HTML 文件，包含 <div id="app"></div>
│
├── src/
│   ├── main.js             # 入口文件：创建 Vue 实例，挂载到 #app
│   ├── App.vue             # 根组件
│   ├── assets/             # 静态资源（会被 webpack 处理）
│   ├── components/         # 组件目录
│   ├── views/              # 页面级组件（配合路由）
│   ├── router/             # 路由配置
│   └── store/              # Vuex 状态管理
│
├── package.json            # 依赖和脚本
├── vue.config.js           # Vue CLI 配置（webpack 的封装）
└── babel.config.js         # Babel 配置
```

### 2.3 入口文件 main.js 做了什么

```js
import Vue from 'vue'       // 引入 Vue 运行时版本（不含编译器）
import App from './App.vue' // 引入根组件（已被 vue-loader 编译成 JS）

Vue.config.productionTip = false

new Vue({
  render: h => h(App),      // h 就是 createElement，用 render 函数渲染根组件
}).$mount('#app')            // 挂载到 index.html 的 #app 元素
```

> 💡 **为什么用 `render: h => h(App)` 而不是 `template: '<App/>'`？**
>
> 因为 `vue-cli` 默认引入的是**运行时版本**（`vue.runtime.esm.js`），不含模板编译器，无法在浏览器里编译 template 字符串。`render` 函数是编译后的产物，运行时版可以直接执行，省掉 ~30KB 编译器体积。

### 2.4 版本对应关系（必记）

| 核心库 | Vue 2 对应版本 | Vue 3 对应版本 | 装错会怎样 |
|--------|---------------|---------------|-----------|
| Vue | `2.x` | `3.x` | — |
| Vue Router | `3.x` | `4.x` | API 不兼容，路由不工作 |
| Vuex | `3.x` | `4.x` | Store 无法注入 |
| Vue CLI | `4.x` / `5.x` | 可用但推荐 Vite | — |
| Element UI | `element-ui` | `element-plus` | 组件注册失败 |
| Vant | `vant@latest-v2` | `vant@latest` | 样式和 API 不一致 |

> ⚠️ **常见坑**：`npm install vue-router` 默认装的是最新版（4.x，对应 Vue 3），Vue 2 项目必须指定 `npm install vue-router@3`。

---

## 三、组件基础与选项式 API

Vue 2 的组件就是一个**选项对象**（Options Object），Vue 按约定好的字段名去读取你写的配置。

### 3.1 一个完整组件的解剖

```html
<template>
  <div class="user-card">
    <h2>{{ fullName }}</h2>
    <p>{{ age }} 岁</p>
    <button @click="increment">点击了 {{ count }} 次</button>
  </div>
</template>

<script>
export default {
  name: 'UserCard',            // 组件名（devtools 调试用，keep-alive 的 include 也靠它）

  props: {                     // 父组件传入的数据（只读）
    firstName: { type: String, required: true },
    lastName:  { type: String, default: '' },
  },

  data() {                     // 组件自己的状态（必须是函数）
    return {
      age: 25,
      count: 0,
    }
  },

  computed: {                  // 派生状态（有缓存）
    fullName() {
      return this.firstName + this.lastName
    },
  },

  watch: {                     // 副作用监听（无缓存，主动执行）
    count(newVal) {
      console.log('count 变成了', newVal)
    },
  },

  methods: {                   // 事件处理 / 业务逻辑
    increment() {
      this.count++
    },
  },

  // 生命周期钩子
  created()        { /* data/methods 已就绪，DOM 还没有 */ },
  mounted()        { /* DOM 已渲染完成 */ },
  beforeDestroy()  { /* 即将销毁，清理定时器/事件 */ },
}
</script>

<style scoped>
.user-card {
  border: 1px solid #ddd;
  padding: 16px;
  border-radius: 8px;
}
</style>
```

### 3.2 选项合并顺序

Vue 在实例化时，会按固定顺序处理选项。这个顺序决定了**谁能访问谁**：

```
initProps()      → props 先就绪
initMethods()    → methods 挂到 this 上（所以 methods 里可以用 this.propName）
initData()       → data 函数执行，返回对象被 observe()（所以 data 里可以用 this.propName）
initComputed()   → 创建 ComputedWatcher
initWatch()      → 创建 UserWatcher
```

> 💡 **推论**：data 函数里可以访问 props（`this.firstName`），因为 props 先初始化。但 data 里不能访问 computed，因为 computed 在 data 之后。

### 3.3 为什么 data 必须是函数——源码级解释

```js
// 源码位置：src/core/instance/state.js → initData()

function initData(vm) {
  let data = vm.$options.data

  // ★ 关键：如果 data 是函数，就调用它拿到返回值
  data = typeof data === 'function'
    ? data.call(vm, vm)  // 以组件实例为 this 调用
    : data || {}

  // 然后 observe(data)，把每个属性变成响应式
  observe(data)

  // 最后把 data 的每个 key 代理到 vm 上
  // 这样 this.count 等价于 this._data.count
  const keys = Object.keys(data)
  keys.forEach(key => {
    proxy(vm, '_data', key)
  })
}
```

**如果 data 是对象（不是函数）**：

```js
// ❌ 所有组件实例共享同一个对象引用
const shared = { count: 0 }

// ComponentA 的 this._data === shared
// ComponentB 的 this._data === shared
// A 改 count，B 的 count 也变了！

// ✅ 函数写法：每次实例化都调用函数，返回一个全新对象
data() {
  return { count: 0 }
}
// ComponentA 的 this._data = { count: 0 }  // 新对象
// ComponentB 的 this._data = { count: 0 }  // 另一个新对象
```

> ⚠️ **根实例（new Vue）可以用对象**，因为根实例只有一个，不存在共享问题。但组件必须用函数。

### 3.4 this 代理机制——为什么 this.count 能直接访问

```js
// 源码位置：src/core/instance/state.js → proxy()

// Vue 把 props、data、methods 都代理到了 vm（组件实例）上
// 这样你写 this.count 实际上访问的是 this._data.count
// 你写 this.increment 实际上访问的是 this.$options.methods.increment

function proxy(target, sourceKey, key) {
  Object.defineProperty(target, key, {
    get() { return target[sourceKey][key] },
    set(val) { target[sourceKey][key] = val },
  })
}

// props  → proxy(vm, '_props', key)
// data   → proxy(vm, '_data', key)
// methods → 直接 bind(vm) 后挂到 vm 上
```

> ⚠️ **命名冲突优先级**：props > methods > data。如果 props 和 data 有同名属性，props 胜出，data 的会被忽略并在控制台警告。

### 3.5 单文件组件（.vue）的编译——概览

浏览器不认识 `.vue` 文件。构建工具（webpack 的 vue-loader / Vite 的插件）在打包时把它拆成三部分分别处理：

```
UserCard.vue
  │
  ▼ vue-loader / @vitejs/plugin-vue
  │
  ├─ <template>  → @vue/compiler-sfc 解析 → 编译成 render 函数
  ├─ <script>    → 原样输出（Babel 转译）
  └─ <style>     → 提取为 CSS（scoped 时加属性选择器）
  │
  ▼ 组装成一个 JS 模块
  │
  export default {
    data() { ... },
    methods: { ... },
    render() {           // ← template 编译的产物
      with(this) {
        return _c('div', { staticClass: 'user-card' }, [
          _c('h2', [_v(_s(fullName))]),
          ...
        ])
      }
    },
    __scopeId: 'data-v-abc123',  // ← scoped 的标识
  }
```

**scoped 的原理**：

```css
/* 你写的 */
.user-card { border: 1px solid #ddd; }

/* 编译后 */
.user-card[data-v-abc123] { border: 1px solid #ddd; }
```

```html
<!-- 同时给模板里的每个元素加上这个属性 -->
<div class="user-card" data-v-abc123>
  <h2 data-v-abc123>张三</h2>
</div>
```

> 本质是**属性选择器 + 唯一属性**，实现 CSS 作用域隔离。不是 Shadow DOM。

### 3.6 完整版 vs 运行时版

| 版本 | 包名 | 包含编译器 | 体积 |
|------|------|-----------|------|
| 完整版 | `vue/dist/vue.js` | ✅ | ~334KB |
| 运行时版 | `vue/dist/vue.runtime.js` | ❌ | ~230KB |

```js
// 完整版：可以在浏览器里编译 template 字符串
new Vue({
  template: '<div>{{ msg }}</div>',  // ✅ 浏览器运行时编译
  data: { msg: 'hello' },
})

// 运行时版：只能执行已经编译好的 render 函数
new Vue({
  render(h) { return h('div', this.msg) },  // ✅ 直接执行
  data: { msg: 'hello' },
})
```

> 💡 **vue-cli / vite 项目用运行时版就够了**——`.vue` 文件的 template 在构建时已经编译成 render 函数，浏览器不需要再编译。

---

## 四、模板编译原理

模板编译是连接「你写的 template」和「运行时 render 函数」的桥梁。理解编译产物，才能理解运行时做了什么。

### 4.1 编译三阶段

```
模板字符串
  │
  ▼ ① Parse（解析）
  │
  AST（抽象语法树）
  │
  ▼ ② Optimize（优化）
  │
  标记了静态节点的 AST
  │
  ▼ ③ Generate（生成）
  │
  render 函数代码字符串
```

### 4.2 第一阶段：Parse——模板 → AST

```html
<div id="app">
  <p>{{ name }}</p>
  <span>静态文本</span>
</div>
```

解析后生成 AST（简化）：

```js
{
  tag: 'div',
  type: 1,                           // 1=元素节点
  attrsList: [{ name: 'id', value: 'app' }],
  children: [
    {
      tag: 'p',
      type: 1,
      children: [{
        type: 2,                     // 2=带表达式的文本
        expression: '_s(name)',      // _s = toString
        text: '{{ name }}',
      }],
    },
    {
      tag: 'span',
      type: 1,
      children: [{
        type: 3,                     // 3=纯文本
        text: '静态文本',
      }],
    },
  ],
}
```

> AST 节点类型：`1`=元素，`2`=带插值表达式的文本，`3`=纯文本。

### 4.3 第二阶段：Optimize——标记静态节点

```js
// 源码位置：src/compiler/optimizer.js

// 遍历 AST，给每个节点打上 static 和 staticRoot 标记
// 静态节点 = 不含任何动态绑定的节点

{
  tag: 'span',
  type: 1,
  static: true,          // ← 标记为静态
  staticRoot: false,
  children: [{
    type: 3,
    text: '静态文本',
    static: true,        // ← 纯文本也是静态
  }],
}
```

**标记静态节点的好处**：

1. **patch 时跳过**：静态节点新旧 VNode 相同，直接跳过对比
2. **提升到常量**：静态节点的 VNode 只创建一次，后续复用，不重复创建

### 4.4 第三阶段：Generate——AST → render 函数

```js
// 源码位置：src/compiler/codegen/index.js

// 最终生成的代码：
with(this) {
  return _c('div', { attrs: { id: "app" } }, [
    _c('p', [_v(_s(name))]),           // 动态节点
    _c('span', [_v("静态文本")]),       // 静态节点
  ])
}
```

**渲染函数里的缩写**：

| 缩写 | 全名 | 作用 |
|------|------|------|
| `_c` | `createElement` | 创建元素 VNode |
| `_v` | `createTextVNode` | 创建文本 VNode |
| `_s` | `toString` | 把值转成字符串显示 |
| `_e` | `createEmptyVNode` | 创建空 VNode（v-if 为 false 时） |
| `_l` | `renderList` | 渲染列表（v-for） |
| `_t` | `renderSlot` | 渲染插槽 |

**为什么用 `with(this)`？**

```js
// with(this) 让函数体内的变量查找先在 this 上找
// 这样模板里写 name，不需要写 this.name

with(this) {
  return _c('p', [_v(_s(name))])
  // name → 先在 this 上找 → this.name → 触发 getter → 依赖收集
}

// 等价于：
return _c('p', [_v(_s(this.name))])
```

> ⚠️ `with` 在严格模式下不可用，所以 Vue 2 的 render 函数不能在严格模式下运行。Vue 3 改用 Proxy，不再需要 `with`。

### 4.5 每个指令编译成了什么

#### v-if / v-else-if / v-else

```html
<p v-if="isVip">VIP</p>
<p v-else>普通用户</p>
```

```js
// 编译后：三元表达式
(isVip) ? _c('p', [_v("VIP")]) : _c('p', [_v("普通用户")])

// v-if 为 false → 这个节点在 VNode 树中根本不存在
// 切换时要销毁/创建 DOM 节点
```

#### v-show

```html
<p v-show="isVisible">内容</p>
```

```js
// 编译后：节点始终存在，通过指令控制 display
_c('p', {
  directives: [{ name: 'show', rawName: 'v-show', value: (isVisible) }],
}, [_v("内容")])

// 运行时 v-show 指令的 bind/update 钩子做的事：
el.style.display = value ? el.__vOriginalDisplay : 'none'
```

> 💡 **v-if vs v-show**：v-if 有更高的切换开销（销毁/创建），v-show 有更高的初始渲染开销（节点始终存在）。频繁切换用 v-show，条件很少改变用 v-if。

#### v-for

```html
<li v-for="(item, index) in list" :key="item.id">{{ item.name }}</li>
```

```js
// 编译后：调用 _l（renderList）
_l((list), function(item, index) {
  return _c('li', { key: item.id }, [_v(_s(item.name))])
})

// _l 的实现（简化）：
function renderList(val, render) {
  const ret = new Array(val.length)
  for (let i = 0; i < val.length; i++) {
    ret[i] = render(val[i], i)
  }
  return ret
}
```

#### v-model（表单双向绑定）

```html
<input v-model="username">
```

```js
// v-model 是语法糖，编译后等价于：
_c('input', {
  domProps: { value: (username) },          // :value="username"
  on: { input: function($event) {           // @input="username = $event.target.value"
    username = $event.target.value
  }},
})

// 所以 v-model 的本质 = value 绑定 + input 事件监听
```

**v-model 在不同表单元素上的行为**：

| 元素 | 绑定的属性 | 监听的事件 |
|------|-----------|-----------|
| `<input type="text">` | `value` | `input` |
| `<textarea>` | `value` | `input` |
| `<input type="checkbox">` | `checked` | `change` |
| `<input type="radio">` | `checked` | `change` |
| `<select>` | `value` | `change` |

#### v-on（事件绑定）

```html
<button @click="handleClick">按钮</button>
<button @click="count++">自增</button>
<button @click="handleClick($event, 'extra')">带参数</button>
```

```js
// 编译后：
// 方法名 → 直接引用
_c('button', { on: { click: handleClick } })

// 内联表达式 → 包装成函数
_c('button', { on: { click: function($event) { count++ } } })

// 带参数 → 包装成函数
_c('button', { on: { click: function($event) { handleClick($event, 'extra') } } })
```

**事件修饰符的编译**：

```html
<button @click.stop.prevent="handler">按钮</button>
```

```js
// 编译后：修饰符变成代码
_c('button', { on: { click: function($event) {
  $event.stopPropagation()    // .stop
  $event.preventDefault()     // .prevent
  return handler($event)
} } })

// .once → 事件名加 ~ 前缀：{ on: { '~click': handler } }
// .capture → 事件名加 ! 前缀：{ on: { '!click': handler } }
// .passive → 事件名加 & 前缀：{ on: { '&click': handler } }
```

### 4.6 v-if 和 v-for 的优先级问题

```html
<!-- ⚠️ 不要在同一个元素上同时使用 v-if 和 v-for -->
<li v-for="item in list" v-if="item.active">{{ item.name }}</li>
```

```js
// Vue 2 中 v-for 优先级高于 v-if
// 编译后：先遍历，再判断（即使只需要渲染少数几个）
_l((list), function(item) {
  return (item.active) ? _c('li', [_v(_s(item.name))]) : _e()
})

// 每次渲染都要遍历整个 list，性能差

// ✅ 正确做法：用 computed 先过滤
computed: {
  activeList() {
    return this.list.filter(item => item.active)
  }
}
// 然后 v-for="item in activeList"
```

> ⚠️ Vue 3 反转了优先级：v-if 优先于 v-for。这是 Vue 2 → 3 的**破坏性变更**之一。

---

## 五、响应式原理

> **核心问题**：你写 `this.msg = 'hello'`，页面就自动更新了——Vue 怎么知道数据变了？怎么知道该通知谁去更新？

### 5.1 三个角色——一句话记住整个系统

响应式系统就三个类，记住它们的关系就懂了：

```
数据对象 ──→ Observer（劫持数据）
                │
                ├─ 给每个属性装 getter/setter
                └─ 每个属性配一个 Dep（依赖收集箱）
                      │
                      ├─ getter 被读时 → 收集当前 Watcher
                      └─ setter 被写时 → 通知所有 Watcher 更新
                            │
                            └─ Watcher（观察者，分三种）
                                ├─ 渲染 Watcher → 重新执行 render，更新页面
                                ├─ 计算 Watcher → 重新计算 computed 的值
                                └─ 用户 Watcher → 执行你写的 watch 回调
```

> 💡 **一句话总结**：Observer 负责劫持，Dep 负责存谁在用，Watcher 负责干活。

### 5.2 Observer——把普通对象变成响应式

当你写了 `data() { return { msg: 'hello', user: { name: '张三' } } }` 后，Vue 在 `initData()` 里调用 `observe(data)`：

```js
// 源码简化版：src/core/observer/index.js

function observe(value) {
  if (typeof value !== 'object' || value === null) return  // 只处理对象和数组
  if (value.__ob__) return value.__ob__                    // 已经观察过的不重复处理
  return new Observer(value)
}

class Observer {
  constructor(value) {
    this.dep = new Dep()           // 对象/数组自身也有一个 Dep（用于 $set、数组变异）
    value.__ob__ = this            // 在对象上挂 __ob__，标记已观察

    if (Array.isArray(value)) {
      value.__proto__ = arrayMethods   // 数组：重写变异方法（5.7 节讲）
      this.observeArray(value)         // 递归观察每个元素
    } else {
      this.walk(value)                 // 对象：遍历每个 key，逐个劫持
    }
  }

  walk(obj) {
    Object.keys(obj).forEach(key => {
      defineReactive(obj, key, obj[key])   // ★ 核心函数，下面讲
    })
  }

  observeArray(arr) {
    arr.forEach(item => observe(item))
  }
}
```

> 💡 `observe()` 是递归的。`{ user: { name: '张三' } }` → 先劫持 `user` 属性，发现值是对象，再递归进去劫持 `name`。最终 data 树的每个属性都被 getter/setter 包裹。

### 5.3 defineReactive——整个响应式系统最核心的函数

```js
// 源码简化版：src/core/observer/index.js

function defineReactive(obj, key, val) {
  const dep = new Dep()            // ★ 每个属性有自己专属的 Dep（闭包保存）

  let childOb = observe(val)       // 递归：如果 val 是对象，继续观察

  Object.defineProperty(obj, key, {
    enumerable: true,
    configurable: true,

    get() {
      // ★ 依赖收集：有 Watcher 在读我，记下来
      if (Dep.target) {
        dep.depend()               // 把当前 Watcher 加入这个属性的 dep
        if (childOb) {
          childOb.dep.depend()     // 值是对象/数组时，对象自身的 dep 也收集
        }
      }
      return val
    },

    set(newVal) {
      if (newVal === val) return   // 值没变，啥也不做
      val = newVal
      childOb = observe(newVal)    // 新值如果是对象，也要观察
      dep.notify()                 // ★ 派发更新：通知所有订阅者
    },
  })
}
```

> 💡 **闭包的妙用**：`dep` 和 `val` 都活在 `defineReactive` 的闭包里。每次读写这个属性，都能访问到属于它的那个 `dep`。这就是为什么每个属性能独立收集依赖。

### 5.4 Dep——依赖收集箱

```js
// 源码简化版：src/core/observer/dep.js

let uid = 0

class Dep {
  static target = null             // 全局唯一：当前正在执行的 Watcher

  constructor() {
    this.id = uid++
    this.subs = []                 // 订阅者列表，存 Watcher 实例
  }

  addSub(watcher) {
    this.subs.push(watcher)
  }

  depend() {
    if (Dep.target) {
      Dep.target.addDep(this)      // 让 Watcher 记住这个 Dep（双向记录）
    }
  }

  notify() {
    this.subs.forEach(watcher => {
      watcher.update()             // 通知每个 Watcher 更新
    })
  }
}

// 用栈管理嵌套组件的 Watcher
const targetStack = []
function pushTarget(watcher) {
  targetStack.push(watcher)
  Dep.target = watcher
}
function popTarget() {
  targetStack.pop()
  Dep.target = targetStack[targetStack.length - 1]
}
```

> 💡 **为什么需要 targetStack？** 父组件渲染到子组件时，父的 Watcher 先入栈暂存，子的 Watcher 成为 `Dep.target`。子渲染完后 pop，恢复父的 Watcher。

### 5.5 Watcher——观察者

```js
// 源码简化版：src/core/observer/watcher.js

class Watcher {
  constructor(vm, expOrFn, cb, options) {
    this.vm = vm
    this.cb = cb                   // 回调（用户 Watcher 才有）
    this.deps = []                 // 这个 Watcher 订阅了哪些 Dep

    // expOrFn 是"取值函数"
    // 渲染 Watcher → updateComponent 函数
    // 计算 Watcher → computed 的 getter
    // 用户 Watcher → watch 的 key（如 'user.name'，会被解析成函数）
    if (typeof expOrFn === 'function') {
      this.getter = expOrFn
    } else {
      this.getter = parsePath(expOrFn)  // 'user.name' → function(obj) { return obj.user.name }
    }

    this.value = this.get()        // ★ 创建时立即执行一次，触发依赖收集
  }

  get() {
    pushTarget(this)               // 把自己设为 Dep.target
    let value
    try {
      value = this.getter.call(this.vm, this.vm)
      // 执行过程中每读一个响应式属性 → 触发 getter → dep.depend() → 收集到自己
    } finally {
      popTarget()                  // 恢复上一个 Watcher
    }
    return value
  }

  addDep(dep) {
    this.deps.push(dep)
    dep.addSub(this)               // 双向绑定：Dep 也记住 Watcher
  }

  update() {
    queueWatcher(this)             // 不立即执行，放入异步队列
  }

  run() {
    const newValue = this.get()    // 重新执行 getter
    if (newValue !== this.value) {
      const oldValue = this.value
      this.value = newValue
      this.cb.call(this.vm, newValue, oldValue)  // 用户 Watcher 的回调
    }
  }
}
```

### 5.6 完整流程串一遍

```js
// 你的组件
export default {
  data() { return { count: 0 } },
  template: '<p>{{ count }}</p>',
}
```

**初始化阶段**：

```
1. initData() → observe({ count: 0 })
2. defineReactive(data, 'count', 0)
   → 创建 dep（闭包里，属于 count）
   → 给 count 装上 getter/setter
```

**挂载阶段**：

```
3. 创建渲染 Watcher → new Watcher(vm, updateComponent)
4. 构造函数调 this.get()
5. pushTarget(渲染Watcher) → Dep.target = 渲染Watcher
6. 执行 render() → 读取 this.count → 触发 getter
7. getter 里 dep.depend() → 渲染Watcher 加入 dep.subs
8. render 返回 VNode → patch → DOM 显示 "0"
9. popTarget() → Dep.target = null
```

**更新阶段**：

```
10. this.count = 1 → 触发 setter
11. setter 里 dep.notify() → 遍历 subs
12. 渲染Watcher.update() → queueWatcher（入队，去重）
13. 同步代码跑完 → nextTick → 执行 Watcher.run()
14. run() → 重新 render() → 新 VNode → patch → DOM 显示 "1"
```

### 5.7 数组的特殊处理

`Object.defineProperty` 只能劫持**已有属性**的读写。数组可能有几百项，逐个用 defineProperty 劫持索引性能太差。Vue 2 的方案：**重写 7 个变异方法**。

```js
// 源码简化版：src/core/observer/array.js

const arrayProto = Array.prototype
const arrayMethods = Object.create(arrayProto)  // 继承原生数组方法

const methodsToPatch = ['push', 'pop', 'shift', 'unshift', 'splice', 'sort', 'reverse']

methodsToPatch.forEach(method => {
  const original = arrayProto[method]

  Object.defineProperty(arrayMethods, method, {
    value: function mutator(...args) {
      const result = original.apply(this, args)  // 先执行原始操作
      const ob = this.__ob__

      // 新插入的元素也要 observe
      let inserted
      switch (method) {
        case 'push':
        case 'unshift':
          inserted = args
          break
        case 'splice':
          inserted = args.slice(2)  // splice 第 3 个参数开始是新元素
          break
      }
      if (inserted) ob.observeArray(inserted)

      ob.dep.notify()              // ★ 手动通知更新
      return result
    },
  })
})
```

> 💡 所以 `this.list.push(item)` 能触发更新（变异方法被拦截了），但 `this.list[0] = newItem` 不能（没劫持索引）。

### 5.8 响应式的局限性与解决方案

| 你的操作 | 能检测到吗 | 为什么 | 解决方案 |
|---------|-----------|--------|---------|
| `this.obj.existingKey = newVal` | ✅ | 已有属性有 getter/setter | — |
| `this.obj.newKey = val` | ❌ | 新属性没被 defineReactive | `this.$set(obj, 'newKey', val)` |
| `delete this.obj.key` | ❌ | delete 不触发 setter | `this.$delete(obj, 'key')` |
| `this.arr[index] = val` | ❌ | 没劫持数组索引 | `this.$set(arr, index, val)` 或 `splice` |
| `this.arr.length = 0` | ❌ | length 无法被劫持 | `this.arr.splice(0)` |
| `this.arr.push(val)` | ✅ | 变异方法被重写了 | — |

**Vue.set 源码——为什么它能触发更新**：

```js
// 源码简化版：src/core/observer/index.js

function set(target, key, val) {
  // 数组：用 splice（变异方法会触发通知）
  if (Array.isArray(target)) {
    target.length = Math.max(target.length, key)
    target.splice(key, 1, val)
    return val
  }

  // 已有属性：直接赋值（已经有 getter/setter）
  if (key in target && !(key in Object.prototype)) {
    target[key] = val
    return val
  }

  // ★ 新属性：手动装上 getter/setter + 通知更新
  const ob = target.__ob__
  defineReactive(target, key, val)  // 给新属性装响应式
  ob.dep.notify()                   // 手动触发通知
  return val
}
```

### 5.9 异步批量更新

你连续执行 `this.a = 1; this.b = 2; this.c = 3`，页面只会重新渲染**一次**。为什么？

```js
// 源码简化版：src/core/observer/scheduler.js

const queue = []
let has = {}                        // 用 Watcher.id 去重
let waiting = false

function queueWatcher(watcher) {
  const id = watcher.id
  if (has[id] != null) return       // ★ 同一个 Watcher 只入队一次
  has[id] = true
  queue.push(watcher)

  if (!waiting) {
    waiting = true
    nextTick(flushSchedulerQueue)   // 推入微任务队列
  }
}

function flushSchedulerQueue() {
  queue.sort((a, b) => a.id - b.id) // 父组件先于子组件更新
  for (let i = 0; i < queue.length; i++) {
    queue[i].run()
  }
  queue.length = 0
  has = {}
  waiting = false
}
```

> 💡 三个 setter 都触发同一个渲染 Watcher 的 `update()`，但 `has[id]` 去重了，Watcher 只入队一次。等同步代码跑完，nextTick 里统一执行一次 `run()`。

### 5.10 常见疑问

**`Object.defineProperty` 和 `Proxy` 到底差在哪？**

这也是 Vue 2 → Vue 3 响应式系统升级的根本原因：

| 对比 | defineProperty（Vue 2） | Proxy（Vue 3） |
|------|------------------------|----------------|
| 劫持粒度 | 单个属性，需要递归遍历 | 整个对象，一次搞定 |
| 新增属性 | ❌ 检测不到 | ✅ 自动检测 |
| 删除属性 | ❌ 检测不到 | ✅ 自动检测 |
| 数组索引 | ❌ 需要 hack | ✅ 自动检测 |
| 性能 | 初始化时递归全部属性 | 懒劫持，访问时才处理 |
| 兼容性 | IE9+ | 不支持 IE |

> 💡 简单说：Vue 2 的 defineProperty 是「逐个属性装监控」，Vue 3 的 Proxy 是「在对象门口装一个总监控」。Proxy 更强大，但不支持 IE，所以 Vue 2 没法用。

**一个组件到底有几个 Watcher？**

至少 1 个（渲染 Watcher）。你写了几个 computed 就多几个计算 Watcher，写了几个 watch 就多几个用户 Watcher。比如一个组件有 3 个 computed + 2 个 watch，那就是 1 + 3 + 2 = 6 个 Watcher。

**依赖收集是什么时候发生的？**

在组件**渲染时**（执行 render 函数时）。render 函数里读了哪些响应式属性，那些属性的 Dep 就会收集渲染 Watcher。你在 data 里定义了但模板里没用到的属性，改了也不会触发重新渲染——因为它的 Dep 里没有渲染 Watcher。

---

## 六、计算属性与侦听器

### 6.1 computed——带缓存的派生数据

**用法**：

```js
export default {
  data() {
    return { firstName: '张', lastName: '三', items: [10, 20, 30] }
  },
  computed: {
    // 简写：只有 getter
    fullName() {
      console.log('computed 执行了')     // 观察：只在依赖变化时打印
      return this.firstName + this.lastName
    },
    // 完整写法：getter + setter
    fullName2: {
      get() { return this.firstName + this.lastName },
      set(val) {
        const [first, ...rest] = val
        this.firstName = first
        this.lastName = rest.join('')
      },
    },
    // 常见用法：过滤/汇总
    total() {
      return this.items.reduce((sum, v) => sum + v, 0)
    },
  },
}
```

**缓存原理——lazy Watcher + dirty 标记**：

```js
// 源码简化版：src/core/instance/state.js → initComputed()

function initComputed(vm, computed) {
  const watchers = vm._computedWatchers = {}

  for (const key in computed) {
    const getter = typeof computed[key] === 'function'
      ? computed[key]
      : computed[key].get

    // ★ 创建 lazy Watcher（不立即执行 getter）
    watchers[key] = new Watcher(vm, getter, noop, { lazy: true })

    // 把 computed 属性代理到 vm 上
    defineComputed(vm, key)
  }
}

function defineComputed(vm, key) {
  Object.defineProperty(vm, key, {
    get() {
      const watcher = vm._computedWatchers[key]
      if (watcher.dirty) {         // ★ 脏了才重新计算
        watcher.evaluate()         // 执行 getter，拿到新值，dirty = false
      }
      if (Dep.target) {
        watcher.depend()           // 让渲染 Watcher 也订阅 computed 的依赖
      }
      return watcher.value
    },
  })
}

// Watcher 中的关键逻辑
class Watcher {
  constructor(vm, expOrFn, cb, options) {
    this.lazy = !!options.lazy
    this.dirty = this.lazy         // lazy Watcher 初始 dirty = true
    this.value = this.lazy ? undefined : this.get()  // lazy 时不立即执行
  }

  evaluate() {
    this.value = this.get()        // 执行 getter，触发依赖收集
    this.dirty = false             // 标记为干净
  }

  update() {
    if (this.lazy) {
      this.dirty = true            // ★ 依赖变了，只标记脏，不立即重算
    } else {
      queueWatcher(this)
    }
  }
}
```

> 💡 **缓存的秘密**：computed Watcher 是 lazy 的。依赖没变 → dirty 为 false → 直接返回缓存值。依赖变了 → dirty 变 true → 下次读取时才重新计算。所以你在模板里多次使用 `{{ fullName }}`，getter 只执行一次。

### 6.2 watch——副作用侦听器

**三种写法**：

```js
export default {
  data() {
    return { keyword: '', user: { name: '张三', age: 25 } }
  },
  watch: {
    // 写法一：函数（最常用）
    keyword(newVal, oldVal) {
      this.search(newVal)           // 搜索请求等副作用
    },

    // 写法二：对象（需要 immediate 或 deep）
    keyword: {
      handler(newVal, oldVal) { this.search(newVal) },
      immediate: true,             // 组件创建时立即执行一次
      deep: false,
    },

    // 写法三：监听嵌套属性
    'user.name'(newVal) {
      console.log('名字变了', newVal)
    },

    // 写法四：deep 深度监听整个对象
    user: {
      handler(newVal) { console.log('user 的某个属性变了') },
      deep: true,                  // 递归监听 user 内部所有属性
    },
  },
}
```

**immediate 的实现**：

```js
// 源码简化版：src/core/instance/state.js → createWatcher()

// 其实很简单：创建完 Watcher 后，立即调一次 cb
if (options.immediate) {
  cb.call(vm, watcher.value)       // 用当前值立即执行一次回调
}
```

**deep 的实现**：

```js
// 源码简化版：src/core/observer/watcher.js → get()

get() {
  pushTarget(this)
  let value = this.getter.call(this.vm, this.vm)
  if (this.deep) {
    traverse(value)                // ★ 递归读取所有子属性，触发每个属性的 getter
  }
  popTarget()
  return value
}

// traverse 就是递归遍历对象的所有属性，读一遍
// 读的过程中每个属性的 getter 都会触发 → dep.depend() → 这个 Watcher 订阅了所有子属性
function traverse(val) {
  if (typeof val !== 'object' || val === null) return
  const keys = Object.keys(val)
  for (let i = 0; i < keys.length; i++) {
    traverse(val[keys[i]])         // 递归读取，触发依赖收集
  }
}
```

> ⚠️ **deep 的性能代价**：对象越大越深，traverse 遍历越多属性，收集的依赖越多。大对象用 deep 要谨慎，优先考虑监听具体路径（如 `'user.name'`）。

### 6.3 computed vs watch 对比

| 对比 | computed | watch |
|------|----------|-------|
| 本质 | 带缓存的 getter | 副作用回调 |
| 缓存 | ✅ 依赖不变不重算 | ❌ 每次变化都执行 |
| 返回值 | 必须 return | 不需要 return |
| 异步 | ❌ getter 里不能写异步 | ✅ 可以做异步请求 |
| Watcher 类型 | lazy Watcher | 用户 Watcher |
| 适用场景 | 从已有数据**派生**新数据 | 数据变化时执行**副作用** |

```js
// ✅ 用 computed：从 data 派生出新值
computed: {
  fullName() { return this.firstName + this.lastName }
}

// ✅ 用 watch：数据变了要做异步操作
watch: {
  keyword(val) {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.search(val), 300)  // 防抖搜索
  }
}

// ❌ 不要用 watch 模拟 computed
watch: {
  firstName(val) { this.fullName = val + this.lastName },  // 反模式
  lastName(val) { this.fullName = this.firstName + val },   // 反模式
}
```

### 6.4 常见疑问

**computed 的缓存到底怎么实现的？**

回顾上面 6.1 的源码：computed 用的是 lazy Watcher。当依赖的数据变化时，不会立即重新计算，只是把 `dirty` 标记为 `true`。下次有人读取这个 computed 属性时，发现 dirty 是 true，才执行 getter 拿到新值并把 dirty 设回 false。如果 dirty 是 false，直接返回上次的值——这就是缓存。

**computed 和 methods 有什么区别？**

模板里用 `{{ fullName }}` 和 `{{ getFullName() }}` 看起来效果一样，但区别是：computed 有缓存，依赖没变就不重新执行 getter；methods 每次渲染都会重新调用。如果计算逻辑比较重（比如遍历大数组），用 computed 能避免不必要的重复计算。

**watch 的 deep 为什么能监听到嵌套属性变化？**

原理很简单：在 Watcher 的 `get()` 执行完 getter 后，如果 deep 为 true，会调 `traverse()` 把对象的所有子属性都**读一遍**。读的过程中，每个子属性的 getter 都会触发 → dep.depend() → 这个 Watcher 就订阅了所有子属性的 Dep。之后任何一个子属性变化，都会通知这个 Watcher。代价就是：对象越大，遍历越多，性能开销越大。

---

## 七、虚拟 DOM 与 Diff 算法

### 7.1 VNode 是什么

VNode（Virtual Node）就是用 JS 对象来描述一个 DOM 节点。render 函数执行后返回的就是 VNode 树。

```js
// 一个真实 DOM 节点
// <div id="app" class="container"><p>hello</p></div>

// 对应的 VNode（简化）
{
  tag: 'div',
  data: { attrs: { id: 'app' }, staticClass: 'container' },
  children: [
    {
      tag: 'p',
      data: {},
      children: [
        { text: 'hello' }         // 文本 VNode
      ],
    }
  ],
}
```

```js
// 源码简化版：src/core/vdom/vnode.js

class VNode {
  constructor(tag, data, children, text, elm) {
    this.tag = tag                 // 标签名
    this.data = data               // 属性、事件、指令等
    this.children = children       // 子节点数组
    this.text = text               // 文本内容
    this.elm = elm                 // 对应的真实 DOM 节点（patch 后赋值）
    this.key = data?.key           // 用户指定的 key（Diff 用）
  }
}
```

### 7.2 为什么需要虚拟 DOM

**直接操作 DOM 的问题**：

```js
// 假设列表从 [A, B, C] 变成 [A, C]
// 方案 1：暴力替换 —— innerHTML = 新内容
//   → 销毁所有旧 DOM，重建所有新 DOM，性能差

// 方案 2：手动 diff —— 你自己计算差异，只删除 B
//   → 代码复杂，难维护

// 方案 3：虚拟 DOM —— 框架帮你 diff
//   → 对比新旧 VNode 树，算出"只需要删除 B"，执行最小化 DOM 操作
```

> 💡 虚拟 DOM 的价值不是"比原生 DOM 快"，而是在**保证还不错的性能**的同时，让你**不用手动操作 DOM**，用声明式的方式写 UI。

### 7.3 patch 算法——核心流程

patch 做的事：对比新旧 VNode，用最少的操作更新真实 DOM。

```js
// 源码简化版：src/core/vdom/patch.js

function patch(oldVnode, vnode) {
  // 情况 1：没有旧节点 → 首次渲染，直接创建 DOM
  if (!oldVnode) {
    createElm(vnode)
    return
  }

  // 情况 2：新旧节点是"同一个节点" → 深入对比子节点
  if (sameVnode(oldVnode, vnode)) {
    patchVnode(oldVnode, vnode)
  } else {
    // 情况 3：不是同一个节点 → 暴力替换
    createElm(vnode)
    oldVnode.elm.parentNode.replaceChild(vnode.elm, oldVnode.elm)
  }
}

// 判断是不是"同一个节点"（不是完全相同，是值得对比的同类节点）
function sameVnode(a, b) {
  return (
    a.key === b.key &&             // key 相同
    a.tag === b.tag &&             // 标签相同
    a.isComment === b.isComment && // 都是注释 or 都不是
    isDef(a.data) === isDef(b.data) // 都有 data or 都没有
  )
}
```

> 💡 **key 的作用在这里**：`sameVnode` 先比 key，再比 tag。如果你不写 key，key 都是 undefined，只要 tag 相同就认为是"同一个节点"，可能导致错误复用。

### 7.4 patchVnode——对比同一个节点的新旧版本

当 `sameVnode` 判定新旧节点是"同一个"后，进入 patchVnode 深入对比：

```js
// 源码简化版：src/core/vdom/patch.js

function patchVnode(oldVnode, vnode) {
  // 新旧是同一个对象，啥也不用做
  if (oldVnode === vnode) return

  const elm = vnode.elm = oldVnode.elm   // 复用旧的真实 DOM 节点

  const oldCh = oldVnode.children
  const newCh = vnode.children

  // 1. 新节点有文本 → 直接设置文本
  if (vnode.text) {
    if (oldVnode.text !== vnode.text) {
      elm.textContent = vnode.text
    }
    return
  }

  // 2. 新旧都有子节点 → 进入最复杂的 diff（updateChildren）
  if (oldCh && newCh) {
    updateChildren(elm, oldCh, newCh)    // ★ 核心中的核心
    return
  }

  // 3. 只有新节点有子节点 → 创建子节点并插入
  if (newCh) {
    newCh.forEach(child => createElm(child, elm))
    return
  }

  // 4. 只有旧节点有子节点 → 删除旧的子节点
  if (oldCh) {
    oldCh.forEach(child => elm.removeChild(child.elm))
  }
}
```

> 💡 **总结 patchVnode 的逻辑**：先看有没有文本变化，再看子节点的四种情况（都有 / 只有新 / 只有旧 / 都没有）。最复杂的情况是"新旧都有子节点"，这时候就进入 Diff 算法。

### 7.5 updateChildren——双端 Diff 算法

这是 Vue 2 Diff 的核心。思路是用**四个指针**从两端向中间靠拢，尽量复用已有的 DOM 节点。

```
旧子节点：  [A]  [B]  [C]  [D]
             ↑                ↑
          oldStart          oldEnd

新子节点：  [D]  [A]  [C]
             ↑         ↑
          newStart   newEnd
```

**每一轮做四次比较**：

```
比较 1：oldStart vs newStart  → 头头比
比较 2：oldEnd   vs newEnd    → 尾尾比
比较 3：oldStart vs newEnd    → 头尾比（旧头 vs 新尾）
比较 4：oldEnd   vs newStart  → 尾头比（旧尾 vs 新头）
```

哪次比中了（sameVnode 返回 true），就 patchVnode 然后移动指针。都没比中，就用 key 去旧节点里找。

```js
// 源码简化版（伪代码风格，突出逻辑）

function updateChildren(parentElm, oldCh, newCh) {
  let oldStart = 0, oldEnd = oldCh.length - 1
  let newStart = 0, newEnd = newCh.length - 1

  while (oldStart <= oldEnd && newStart <= newEnd) {

    if (sameVnode(oldCh[oldStart], newCh[newStart])) {
      // ① 头头相同 → 原地 patch，两个头指针右移
      patchVnode(oldCh[oldStart], newCh[newStart])
      oldStart++; newStart++

    } else if (sameVnode(oldCh[oldEnd], newCh[newEnd])) {
      // ② 尾尾相同 → 原地 patch，两个尾指针左移
      patchVnode(oldCh[oldEnd], newCh[newEnd])
      oldEnd--; newEnd--

    } else if (sameVnode(oldCh[oldStart], newCh[newEnd])) {
      // ③ 旧头 = 新尾 → patch 后把旧头的 DOM 移到最右边
      patchVnode(oldCh[oldStart], newCh[newEnd])
      parentElm.insertBefore(oldCh[oldStart].elm, oldCh[oldEnd].elm.nextSibling)
      oldStart++; newEnd--

    } else if (sameVnode(oldCh[oldEnd], newCh[newStart])) {
      // ④ 旧尾 = 新头 → patch 后把旧尾的 DOM 移到最左边
      patchVnode(oldCh[oldEnd], newCh[newStart])
      parentElm.insertBefore(oldCh[oldEnd].elm, oldCh[oldStart].elm)
      oldEnd--; newStart++

    } else {
      // ⑤ 四次都没比中 → 用 key 在旧节点里找
      // 找到了就移过来 patch，没找到就创建新 DOM
      const idxInOld = oldCh.findIndex(c => sameVnode(c, newCh[newStart]))
      if (idxInOld >= 0) {
        patchVnode(oldCh[idxInOld], newCh[newStart])
        parentElm.insertBefore(oldCh[idxInOld].elm, oldCh[oldStart].elm)
        oldCh[idxInOld] = undefined    // 标记已处理
      } else {
        createElm(newCh[newStart], parentElm, oldCh[oldStart].elm)
      }
      newStart++
    }
  }

  // 循环结束后的收尾
  if (oldStart > oldEnd) {
    // 旧的先遍历完 → 新的有多余节点，批量创建
    for (let i = newStart; i <= newEnd; i++) createElm(newCh[i], parentElm)
  } else if (newStart > newEnd) {
    // 新的先遍历完 → 旧的有多余节点，批量删除
    for (let i = oldStart; i <= oldEnd; i++) parentElm.removeChild(oldCh[i].elm)
  }
}
```

### 7.6 为什么一定要写 key——一个具体的反面例子

假设你有一个待办列表，每项有一个 checkbox：

```html
<li v-for="item in list">
  <input type="checkbox"> {{ item.name }}
</li>
```

初始状态：`list = [{name: 'A'}, {name: 'B'}, {name: 'C'}]`，你勾选了 B 的 checkbox。

现在你删除 B：`list = [{name: 'A'}, {name: 'C'}]`

**没有 key 的情况**：

```
旧 VNode：  li(A)  li(B)  li(C)
新 VNode：  li(A)  li(C)

Diff 过程：
① sameVnode(旧li, 新li) → key 都是 undefined，tag 都是 li → true
② 所以旧的第 1 个 li 和新的第 1 个 li 做 patchVnode → 文本 A→A，没变化 ✅
③ 旧的第 2 个 li 和新的第 2 个 li 做 patchVnode → 文本 B→C，更新文本
   但 checkbox 的勾选状态是 DOM 状态，不在 VNode 里 → 复用了旧的 DOM → 勾选还在！❌
④ 旧的第 3 个 li 没有对应 → 删除

结果：C 那一项显示着 B 的勾选状态！因为 DOM 节点被错误复用了。
```

**有 key 的情况**：

```html
<li v-for="item in list" :key="item.name">
```

```
旧 VNode：  li(key=A)  li(key=B)  li(key=C)
新 VNode：  li(key=A)  li(key=C)

Diff 过程：
① sameVnode 比 key：A===A ✅ → patch，没变化
② sameVnode 比 key：B!==C ❌ → 头头不匹配
③ 尾尾比：C===C ✅ → patch，没变化
④ 旧的 B 没有对应 → 删除 B 的 DOM

结果：正确！B 的 DOM 被删除，C 保留自己的状态。
```

> 💡 **key 的本质**：让 Diff 算法能精确识别"谁是谁"。没有 key 时只比 tag，很容易把不同数据的节点当成"同一个"来复用，导致状态错乱。**永远不要用 index 当 key**——因为删除/插入后 index 会变，又回到了"认错人"的问题。

### 7.7 常见疑问

**虚拟 DOM 一定比直接操作 DOM 快吗？**

不一定。如果你精确知道要改什么（比如只改一个文本），直接 `el.textContent = 'xxx'` 肯定比走一遍 Diff 快。虚拟 DOM 的价值是：在你**不手动管理 DOM** 的前提下，给出一个**还不错的性能**。它是开发效率和运行效率的平衡点。

**为什么不用 index 当 key？**

因为 index 和数据不是绑定关系。删除第 2 项后，原来 index=2 的变成了 index=1。Diff 会认为 key=1 的旧节点和 key=1 的新节点是"同一个"，实际上它们对应完全不同的数据。

**Vue 2 和 Vue 3 的 Diff 有什么区别？**

Vue 2 用双端 Diff（四指针）。Vue 3 在此基础上加了**最长递增子序列**算法，能更精确地判断哪些节点不需要移动，进一步减少 DOM 操作。

---

## 八、组件通信（6 种方式）

Vue 2 里组件之间传数据有 6 种常用方式。先看一张总览表，再逐个讲解：

| 方式 | 方向 | 适用场景 |
|------|------|---------|
| props / $emit | 父 → 子 / 子 → 父 | 最常用，父子直接通信 |
| EventBus | 任意组件 | 小项目跨组件通信 |
| provide / inject | 祖先 → 后代 | 跨多层传递，不需要逐层 props |
| $attrs / $listeners | 父 → 子（透传） | 封装高阶组件 |
| $parent / $children / $refs | 直接访问实例 | 应急方案，不推荐常用 |
| Vuex | 全局共享 | 中大型项目状态管理 |

### 8.1 props / $emit——最基础的父子通信

```html
<!-- 父组件 -->
<template>
  <Child :title="pageTitle" @update="handleUpdate" />
</template>

<script>
export default {
  data() { return { pageTitle: '首页' } },
  methods: {
    handleUpdate(newTitle) {
      this.pageTitle = newTitle     // 子组件通知父组件修改数据
    },
  },
}
</script>

<!-- 子组件 Child.vue -->
<template>
  <div>
    <h1>{{ title }}</h1>
    <button @click="$emit('update', '新标题')">修改标题</button>
  </div>
</template>

<script>
export default {
  props: {
    title: { type: String, required: true },
  },
}
</script>
```

**原理**：props 是单向数据流（父 → 子），子组件不能直接改 props。子组件通过 `$emit` 触发事件，父组件监听事件后修改自己的数据，新数据再通过 props 流回子组件。

> ⚠️ **不要在子组件里直接修改 props**。Vue 会在控制台警告。如果需要基于 prop 做修改，用 data 拷贝一份或用 computed 派生。

### 8.2 EventBus——跨组件通信

适合小项目中不相关的组件之间通信。本质就是一个空的 Vue 实例当事件中心。

```js
// event-bus.js
import Vue from 'vue'
export const bus = new Vue()

// 组件 A：发送事件
import { bus } from './event-bus'
bus.$emit('user-login', { name: '张三' })

// 组件 B：监听事件
import { bus } from './event-bus'
export default {
  created() {
    bus.$on('user-login', (user) => {
      console.log(user.name, '登录了')
    })
  },
  beforeDestroy() {
    bus.$off('user-login')          // ★ 必须手动解绑，否则内存泄漏
  },
}
```

> ⚠️ EventBus 的问题：事件多了难以追踪，容易忘记 `$off` 导致内存泄漏，大项目建议用 Vuex。

### 8.3 provide / inject——跨层级传递

祖先组件 `provide` 数据，任意后代组件 `inject` 接收。不需要一层层传 props。

```js
// 祖先组件
export default {
  provide() {
    return {
      theme: this.theme,           // 注意：这样传的是值，不是响应式的
    }
  },
  data() { return { theme: 'dark' } },
}

// 任意后代组件（不管隔了几层）
export default {
  inject: ['theme'],               // 直接用 this.theme 访问
  // 或者带默认值：
  inject: {
    theme: { default: 'light' },
  },
}
```

**原理**：provide 的数据存在组件实例的 `_provided` 上。inject 在 `initInjections()` 时沿着 `$parent` 链往上找，找到第一个有对应 key 的 `_provided` 就取值。

```js
// 源码简化版：src/core/instance/inject.js

function resolveInject(inject, vm) {
  const result = {}
  for (const key of Object.keys(inject)) {
    let source = vm
    while (source) {
      if (source._provided && key in source._provided) {
        result[key] = source._provided[key]
        break
      }
      source = source.$parent      // 没找到就继续往上找
    }
  }
  return result
}
```

> ⚠️ **provide 默认不是响应式的**。传普通值（如字符串），祖先改了后代不会更新。要响应式可以传一个对象（对象属性是响应式的），或者 provide 一个函数让后代调用获取最新值。

### 8.4 $attrs / $listeners——属性和事件的透传

当你封装一个组件，想把父组件传的属性和事件原封不动地传给内部的某个子组件时，用这两个：

```html
<!-- 父组件 -->
<MyInput placeholder="请输入" maxlength="20" @focus="onFocus" @blur="onBlur" />

<!-- MyInput.vue（中间层组件） -->
<template>
  <div class="my-input-wrapper">
    <label>标签</label>
    <!-- 把没有在 props 里声明的属性和事件，透传给 input -->
    <input v-bind="$attrs" v-on="$listeners">
  </div>
</template>

<script>
export default {
  inheritAttrs: false,             // 阻止属性自动加到根元素上
  // 不需要在 props 里声明 placeholder、maxlength
  // 它们会出现在 $attrs 里
}
</script>
```

- **`$attrs`**：父组件传的属性中，没有被子组件 props 声明的部分。上例中就是 `{ placeholder: '请输入', maxlength: '20' }`
- **`$listeners`**：父组件绑定的事件监听器。上例中就是 `{ focus: onFocus, blur: onBlur }`
- **`inheritAttrs: false`**：默认情况下，$attrs 里的属性会自动添加到组件根元素上。设为 false 后你可以自己控制加在哪个元素上

> 💡 这在封装第三方 UI 组件的二次包装时特别有用，不用在 props 里重复声明第三方组件的所有属性。

### 8.5 $parent / $children / $refs——直接访问实例

```js
// $refs：给组件/元素起名字，直接访问
// 模板里：<Child ref="childComp" />  <input ref="nameInput" />
this.$refs.childComp.someMethod()     // 调用子组件的方法
this.$refs.nameInput.focus()           // 操作原生 DOM

// $parent：访问父组件实例
this.$parent.someData                  // 读父组件的数据

// $children：访问子组件实例数组（顺序不保证）
this.$children[0].someMethod()
```

> ⚠️ `$parent` 和 `$children` 让组件之间产生了**强耦合**，父子组件不能独立复用。只在应急时使用。`$refs` 相对可控，但也不要滥用——能用 props/$emit 解决的就不要用 $refs。

### 8.6 Vuex——全局状态管理（第十五章详细讲）

这里先给出核心概念，详细用法在第十五章。

```js
// store/index.js
import Vuex from 'vuex'

export default new Vuex.Store({
  state: {
    count: 0,                       // 全局共享的数据
  },
  mutations: {
    increment(state) {              // 同步修改 state 的唯一途径
      state.count++
    },
  },
  actions: {
    asyncIncrement({ commit }) {    // 异步操作，最终调 mutation
      setTimeout(() => commit('increment'), 1000)
    },
  },
  getters: {
    doubleCount: state => state.count * 2,  // 类似 computed
  },
})

// 任意组件中使用
this.$store.state.count              // 读
this.$store.commit('increment')      // 同步改
this.$store.dispatch('asyncIncrement') // 异步改
this.$store.getters.doubleCount      // 派生数据
```

### 8.7 怎么选——一张决策图

```
需要通信的组件是什么关系？
│
├─ 父子关系 → props / $emit（首选）
│
├─ 隔了很多层 → provide / inject
│
├─ 兄弟组件 → 小项目用 EventBus，大项目用 Vuex
│
├─ 封装组件透传 → $attrs / $listeners
│
└─ 全局共享状态 → Vuex
```

---

## 九、插槽（默认 / 具名 / 作用域）

插槽让父组件可以往子组件的"指定位置"塞入自定义内容。可以理解为子组件留了几个"坑"，父组件来填。

### 9.1 默认插槽

```html
<!-- 子组件 Card.vue -->
<template>
  <div class="card">
    <slot>这是默认内容，父组件不传就显示这个</slot>
  </div>
</template>

<!-- 父组件使用 -->
<Card>
  <p>我是父组件塞进来的内容</p>
</Card>

<!-- 渲染结果 -->
<div class="card">
  <p>我是父组件塞进来的内容</p>
</div>
```

### 9.2 具名插槽

子组件留多个坑，通过 `name` 区分：

```html
<!-- 子组件 Layout.vue -->
<template>
  <div class="layout">
    <header><slot name="header"></slot></header>
    <main><slot></slot></main>             <!-- 没有 name 的是默认插槽 -->
    <footer><slot name="footer"></slot></footer>
  </div>
</template>

<!-- 父组件使用（Vue 2.6+ 语法） -->
<Layout>
  <template v-slot:header>
    <h1>页面标题</h1>
  </template>

  <p>这是正文，放入默认插槽</p>

  <template v-slot:footer>
    <p>底部信息</p>
  </template>
</Layout>
```

> 💡 `v-slot:header` 可以缩写为 `#header`。旧语法 `slot="header"` 在 Vue 2.6 后已废弃但仍可用。

### 9.3 作用域插槽——子组件给父组件"传数据"

普通插槽：父组件决定内容，但只能用父组件的数据。
作用域插槽：子组件把自己的数据**暴露给父组件**，父组件拿到数据后决定怎么渲染。

```html
<!-- 子组件 UserList.vue -->
<template>
  <ul>
    <li v-for="(user, index) in users" :key="user.id">
      <!-- 把 user 数据暴露给父组件 -->
      <slot :user="user" :index="index">
        {{ user.name }}              <!-- 默认渲染方式 -->
      </slot>
    </li>
  </ul>
</template>

<!-- 父组件使用：拿到子组件的数据，自定义渲染 -->
<UserList :users="userList">
  <template v-slot:default="{ user }">
    <span>{{ user.name }} - {{ user.age }}岁</span>
    <button @click="edit(user)">编辑</button>
  </template>
</UserList>
```

**编译后是什么样**：

```js
// 作用域插槽编译后，父组件传给子组件的是一个函数
// 子组件调用这个函数，把数据当参数传进去，拿到 VNode

// 父组件编译后：
{
  scopedSlots: {
    default: function(props) {       // props = { user, index }
      return _c('span', [_v(props.user.name + ' - ' + props.user.age + '岁')])
    }
  }
}

// 子组件渲染时：
// _t('default', fallback, { user: user, index: index })
// _t 就是 renderSlot，它会调用 scopedSlots.default({ user, index })
```

> 💡 **作用域插槽的本质**：父组件传了一个"渲染函数"给子组件，子组件在渲染时调用这个函数并传入自己的数据。这样父组件就能用子组件的数据来决定渲染什么。

### 9.4 插槽的编译原理

```html
<!-- 父组件 -->
<Child>
  <p>默认内容</p>
  <template #header><h1>标题</h1></template>
</Child>
```

```js
// 编译后：子组件实例的 $slots 对象
vm.$slots = {
  default: [VNode(<p>默认内容</p>)],
  header: [VNode(<h1>标题</h1>)],
}

// 子组件模板里的 <slot name="header"> 编译成：
_t('header')    // _t = renderSlot

// renderSlot 的简化实现：
function renderSlot(name, fallback, props) {
  const scopedSlot = this.$scopedSlots[name]
  if (scopedSlot) {
    return scopedSlot(props)         // 作用域插槽：调用函数
  }
  return this.$slots[name] || fallback  // 普通插槽：直接返回 VNode
}
```

---

## 十、生命周期

### 10.1 全部钩子一览

```
创建阶段
  │ beforeCreate    → data/methods 都还没初始化，this 上啥也没有
  │ created         → data/methods/computed/watch 都就绪，但 DOM 还没有
  │
挂载阶段
  │ beforeMount     → render 函数即将首次执行
  │ mounted         → DOM 已经渲染完成，可以操作 DOM 了
  │
更新阶段（数据变了才触发）
  │ beforeUpdate    → 数据变了，但 DOM 还没更新
  │ updated         → DOM 已经更新完成
  │
销毁阶段
  │ beforeDestroy   → 即将销毁，实例还完整可用
  │ destroyed       → 已销毁，所有绑定和 Watcher 已移除
```

### 10.2 每个钩子能做什么——实战指南

```js
export default {
  beforeCreate() {
    // 几乎不用。此时 data、methods 都还没初始化。
    // 唯一用途：某些插件（如 vue-router）在这里注入逻辑。
  },

  created() {
    // ★ 最常用的初始化钩子
    // 可以访问 data、methods、computed、watch
    // 适合：发起 API 请求、初始化数据
    this.fetchUserList()
    // 不能操作 DOM（还没渲染）
  },

  beforeMount() {
    // 很少用。render 函数即将执行。
  },

  mounted() {
    // ★ DOM 已渲染完成
    // 适合：操作 DOM、初始化第三方库（如 ECharts、地图）
    this.chart = echarts.init(this.$refs.chartContainer)
    // 适合：添加全局事件监听
    window.addEventListener('resize', this.handleResize)
  },

  beforeUpdate() {
    // 很少用。数据变了，DOM 还没更新。
    // 适合：在 DOM 更新前记录一些状态（如滚动位置）
  },

  updated() {
    // DOM 已更新完。注意：不要在这里修改 data，否则会死循环。
  },

  beforeDestroy() {
    // ★ 清理工作
    // 适合：清除定时器、移除全局事件、断开 WebSocket
    clearInterval(this.timer)
    window.removeEventListener('resize', this.handleResize)
    this.chart?.dispose()
  },

  destroyed() {
    // 组件已销毁。所有子组件也已销毁。
  },
}
```

### 10.3 父子组件的生命周期顺序

这个顺序很多人搞不清楚，记住这个规律：**父组件的某个阶段要等子组件的对应阶段完成后才算完成**。

**首次渲染**：

```
父 beforeCreate → 父 created → 父 beforeMount
  → 子 beforeCreate → 子 created → 子 beforeMount → 子 mounted
→ 父 mounted
```

> 理解：父组件在 beforeMount 后开始渲染，渲染到子组件时，子组件走完整个创建+挂载流程，然后父组件才算 mounted。

**更新**（父组件传的 prop 变了）：

```
父 beforeUpdate → 子 beforeUpdate → 子 updated → 父 updated
```

**销毁**：

```
父 beforeDestroy → 子 beforeDestroy → 子 destroyed → 父 destroyed
```

### 10.4 源码中生命周期钩子是怎么调用的

```js
// 源码简化版：src/core/instance/lifecycle.js

function callHook(vm, hook) {
  const handlers = vm.$options[hook]  // 获取钩子函数数组（可能有多个，mixin 合并的）
  if (handlers) {
    for (let i = 0; i < handlers.length; i++) {
      handlers[i].call(vm)            // 以组件实例为 this 调用
    }
  }
}

// 在各个阶段调用：
// initState 之前：callHook(vm, 'beforeCreate')
// initState 之后：callHook(vm, 'created')
// 首次 patch 之前：callHook(vm, 'beforeMount')
// 首次 patch 之后：callHook(vm, 'mounted')
// 重新 render 之前：callHook(vm, 'beforeUpdate')
// 重新 patch 之后：callHook(vm, 'updated')
// $destroy() 开始时：callHook(vm, 'beforeDestroy')
// $destroy() 结束后：callHook(vm, 'destroyed')
```

> 💡 注意 `handlers` 是数组——因为如果你用了 mixin，mixin 和组件自身的钩子会合并成数组。mixin 的钩子先执行，组件自身的后执行。

### 10.5 常见疑问

**created 和 mounted 发请求有什么区别？**

功能上没区别，都能发。但推荐在 **created** 里发——因为 created 更早执行，能更早拿到数据。如果在 mounted 里发，要等 DOM 渲染完才发请求，白白浪费了渲染那段时间。除非你的请求依赖 DOM（极少见），否则都放 created。

**为什么 updated 里不能修改 data？**

因为修改 data → 触发 setter → 通知 Watcher → 重新渲染 → 又触发 updated → 又修改 data → 死循环。

---

## 十一、自定义指令

指令就是对 DOM 元素的底层操作的封装。Vue 内置了 `v-if`、`v-show`、`v-model` 等，你也可以自定义。

### 11.1 基本语法

```js
// 全局注册
Vue.directive('focus', {
  inserted(el) {
    el.focus()                      // 元素插入 DOM 后自动聚焦
  },
})

// 组件内注册
export default {
  directives: {
    focus: {
      inserted(el) { el.focus() },
    },
  },
}

// 使用
// <input v-focus>
```

### 11.2 五个钩子函数

```js
Vue.directive('demo', {
  bind(el, binding, vnode) {
    // 指令第一次绑定到元素时调用（只调一次）
    // 此时元素还没插入 DOM
  },
  inserted(el, binding, vnode) {
    // 元素已插入父节点（DOM 已存在）
  },
  update(el, binding, vnode, oldVnode) {
    // VNode 更新时调用（可能值还没变）
  },
  componentUpdated(el, binding, vnode, oldVnode) {
    // VNode 和子组件的 VNode 都更新后调用
  },
  unbind(el, binding, vnode) {
    // 指令与元素解绑时调用（只调一次）
    // 适合清理工作
  },
})
```

**binding 对象包含什么**：

```js
// <div v-demo:arg.mod1.mod2="value">

binding = {
  name: 'demo',                     // 指令名
  value: value,                     // 绑定的值（当前值）
  oldValue: ...,                    // 上一次的值（update 和 componentUpdated 中有）
  expression: 'value',              // 绑定表达式的字符串
  arg: 'arg',                       // 参数（冒号后面的）
  modifiers: { mod1: true, mod2: true },  // 修饰符
}
```

### 11.3 实用案例

**权限指令——没权限就移除元素**：

```js
Vue.directive('permission', {
  inserted(el, binding) {
    const requiredRole = binding.value  // 比如 'admin'
    const userRole = store.state.user.role

    if (userRole !== requiredRole) {
      el.parentNode.removeChild(el)
    }
  },
})

// 使用：<button v-permission="'admin'">删除用户</button>
// 非 admin 用户看不到这个按钮
```

**防抖点击指令**：

```js
Vue.directive('debounce-click', {
  bind(el, binding) {
    let timer = null
    el.addEventListener('click', () => {
      clearTimeout(timer)
      timer = setTimeout(() => {
        binding.value()             // 执行绑定的方法
      }, binding.arg || 300)        // 参数指定延迟，默认 300ms
    })
  },
})

// 使用：<button v-debounce-click:500="submit">提交</button>
```

### 11.4 指令在 patch 中是怎么执行的

指令的钩子是在 patch 过程中被调用的。Vue 在 patch 的不同阶段会检查 VNode 上有没有指令，有就调用对应的钩子：

```
createElement → 调 bind
插入 DOM     → 调 inserted
VNode 更新   → 调 update → 调 componentUpdated
VNode 移除   → 调 unbind
```

> 💡 自定义指令的适用场景：**需要直接操作 DOM 的底层行为**。比如聚焦、拖拽、长按、懒加载、权限控制等。如果不涉及 DOM 操作，通常用 methods 或 computed 就行，不需要指令。

---

## 十二、Mixin 与复用模式

### 12.1 Mixin 是什么

Mixin 就是把多个组件共用的选项（data、methods、computed、生命周期等）提取到一个对象里，然后混入到组件中。

```js
// mixins/pagination.js —— 分页逻辑复用
export const paginationMixin = {
  data() {
    return { page: 1, pageSize: 10, total: 0 }
  },
  computed: {
    totalPages() {
      return Math.ceil(this.total / this.pageSize)
    },
  },
  methods: {
    nextPage() {
      if (this.page < this.totalPages) this.page++
    },
    prevPage() {
      if (this.page > 1) this.page--
    },
  },
}

// 组件中使用
import { paginationMixin } from '@/mixins/pagination'

export default {
  mixins: [paginationMixin],
  // 现在这个组件自动拥有了 page、pageSize、total、nextPage、prevPage 等
  created() {
    console.log(this.page)          // 1
  },
}
```

### 12.2 选项合并策略

当 mixin 和组件有同名选项时，怎么合并？

| 选项类型 | 合并策略 |
|---------|---------|
| data | 递归合并，**组件优先**（同名属性组件覆盖 mixin） |
| methods / computed / components | 合并，**组件优先**覆盖 |
| 生命周期钩子 | **都保留**，mixin 的先执行，组件的后执行 |
| watch | **都保留**，mixin 的先执行 |

```js
const mixin = {
  data() { return { name: 'mixin' } },
  created() { console.log('mixin created') },
}

export default {
  mixins: [mixin],
  data() { return { name: 'component' } },
  created() { console.log('component created') },
}

// this.name === 'component'        ← 组件覆盖 mixin
// 控制台输出：
// mixin created                    ← mixin 的钩子先执行
// component created                ← 组件的钩子后执行
```

### 12.3 全局 Mixin

```js
// 影响所有组件，慎用！
Vue.mixin({
  created() {
    console.log('每个组件创建时都会执行这里')
  },
})
```

> ⚠️ 全局 mixin 会影响**每一个组件**（包括第三方库的组件），除非你非常清楚自己在做什么，否则别用。

### 12.4 Mixin 的问题

1. **命名冲突**：多个 mixin 如果有同名的 data/methods，很难排查
2. **来源不清**：看组件代码时，不知道某个方法/数据是哪个 mixin 提供的
3. **隐式依赖**：mixin 可能依赖组件的某些 data/methods，但不会报错，只是运行时出 bug

```js
// 你看到组件里用了 this.handleSearch()，但组件代码里没有这个方法
// 它可能来自 mixins 数组里的某一个 mixin
// 如果 mixin 很多，排查很痛苦
```

### 12.5 替代方案——Renderless Component

Vue 2 最推荐的 mixin 替代方案是 **Renderless Component（无渲染组件）**：只处理逻辑，不渲染任何 DOM，通过作用域插槽把数据暴露给父组件自由渲染。

```html
<!-- MouseTracker.vue —— 只管逻辑，不管 UI -->
<template>
  <!-- 没有自己的 DOM，直接渲染插槽 -->
  <slot :x="x" :y="y" />
</template>

<script>
export default {
  name: 'MouseTracker',
  data() {
    return { x: 0, y: 0 }
  },
  mounted() {
    window.addEventListener('mousemove', this.update)
  },
  beforeDestroy() {
    window.removeEventListener('mousemove', this.update)  // 记得清理
  },
  methods: {
    update(e) {
      this.x = e.clientX
      this.y = e.clientY
    },
  },
}
</script>
```

```html
<!-- 父组件：拿到数据，完全自由决定怎么渲染 -->
<MouseTracker v-slot="{ x, y }">
  <p>鼠标位置：{{ x }}, {{ y }}</p>
</MouseTracker>

<!-- 同一个逻辑组件，换一套 UI -->
<MouseTracker v-slot="{ x, y }">
  <div class="cursor-dot" :style="{ left: x + 'px', top: y + 'px' }" />
</MouseTracker>
```

**对比 mixin 的优势**：

| 对比 | Mixin | Renderless Component |
|------|-------|---------------------|
| 数据来源 | 隐式混入，不清楚从哪来 | 明确：从 `v-slot` 解构拿到 |
| 命名冲突 | 容易冲突 | 不冲突（作用域隔离） |
| 逻辑复用 | 多组件共用同一份逻辑 ✅ | 同样可以 ✅ |
| UI 自定义 | 难以定制 | 完全由使用方控制 ✅ |

> 💡 Vue 3 引入了 Composition API，可以用 `useXxx()` 函数替代 mixin 和 renderless component，写法更简洁。Vue 2.7 也已经支持了 Composition API。

---

## 十三、过渡与动画

Vue 提供了 `<transition>` 组件来在元素进入/离开 DOM 时自动添加 CSS 过渡类名。

### 13.1 基本用法

```html
<template>
  <button @click="show = !show">切换</button>
  <transition name="fade">
    <p v-if="show">我会淡入淡出</p>
  </transition>
</template>

<style>
/* 进入过渡 */
.fade-enter-active { transition: opacity 0.3s; }
.fade-enter        { opacity: 0; }              /* 进入起始状态 */
.fade-enter-to     { opacity: 1; }              /* 进入结束状态（Vue 2.1.8+） */

/* 离开过渡 */
.fade-leave-active { transition: opacity 0.3s; }
.fade-leave        { opacity: 1; }              /* 离开起始状态 */
.fade-leave-to     { opacity: 0; }              /* 离开结束状态 */
</style>
```

### 13.2 六个 CSS 类名

`<transition name="xxx">` 会在不同阶段自动添加/移除这些类名：

```
进入过程：
  第 1 帧：添加 xxx-enter + xxx-enter-active
  第 2 帧：移除 xxx-enter，添加 xxx-enter-to
  过渡结束：移除 xxx-enter-active + xxx-enter-to

离开过程：
  第 1 帧：添加 xxx-leave + xxx-leave-active
  第 2 帧：移除 xxx-leave，添加 xxx-leave-to
  过渡结束：移除 xxx-leave-active + xxx-leave-to
```

### 13.3 JavaScript 钩子

当你需要用 JS 控制动画（比如用 GSAP 库）时：

```html
<transition
  @before-enter="beforeEnter"
  @enter="enter"
  @after-enter="afterEnter"
  @before-leave="beforeLeave"
  @leave="leave"
  @after-leave="afterLeave"
>
  <p v-if="show">内容</p>
</transition>
```

```js
methods: {
  enter(el, done) {
    // 用 GSAP 或其他动画库
    gsap.fromTo(el, { opacity: 0 }, { opacity: 1, onComplete: done })
  },
  leave(el, done) {
    gsap.to(el, { opacity: 0, onComplete: done })
  },
}
```

### 13.4 列表过渡——transition-group

```html
<transition-group name="list" tag="ul">
  <li v-for="item in items" :key="item.id">{{ item.text }}</li>
</transition-group>

<style>
.list-enter-active, .list-leave-active { transition: all 0.3s; }
.list-enter, .list-leave-to { opacity: 0; transform: translateX(30px); }
.list-move { transition: transform 0.3s; }     /* ★ 移动动画 */
</style>
```

> 💡 `transition-group` 和 `transition` 的区别：`transition` 只能包裹单个元素，`transition-group` 可以包裹列表。`transition-group` 会渲染一个真实的 DOM 元素（通过 `tag` 指定），并且支持 `.list-move` 类来实现排序动画。

---

## 十四、Vue Router 3

### 14.1 Vue.use()——插件安装原理

在配置路由之前，先看一眼 `Vue.use(VueRouter)` 到底做了什么，因为 Vuex 也是同样的套路。

```js
// 源码简化版：src/core/global-api/use.js

Vue.use = function(plugin) {
  const installedPlugins = this._installedPlugins || (this._installedPlugins = [])

  // ★ 防止重复安装
  if (installedPlugins.indexOf(plugin) > -1) return this

  const args = [this]   // 第一个参数固定是 Vue 构造函数

  // 调用插件的 install 方法
  if (typeof plugin.install === 'function') {
    plugin.install.apply(plugin, args)     // 优先用 install 方法
  } else if (typeof plugin === 'function') {
    plugin.apply(null, args)               // 插件本身是函数时直接调用
  }

  installedPlugins.push(plugin)
  return this
}
```

**VueRouter 的 install 做了什么**：

```js
// vue-router/src/install.js（简化）

VueRouter.install = function(Vue) {
  // 1. 全局混入：每个组件创建时注入 $router 和 $route
  Vue.mixin({
    beforeCreate() {
      if (this.$options.router) {
        // 根组件：把 router 挂到自己身上
        this._routerRoot = this
        this._router = this.$options.router
        this._router.init(this)
        // 让 _route 变成响应式（路由变化 → 视图更新的关键）
        Vue.util.defineReactive(this, '_route', this._router.history.current)
      } else {
        // 子组件：沿着父链找到根组件的 _routerRoot
        this._routerRoot = this.$parent && this.$parent._routerRoot
      }
    },
  })

  // 2. 在原型上挂 $router 和 $route，所有组件都能用 this.$router
  Object.defineProperty(Vue.prototype, '$router', {
    get() { return this._routerRoot._router },
  })
  Object.defineProperty(Vue.prototype, '$route', {
    get() { return this._routerRoot._route },
  })

  // 3. 全局注册 <router-view> 和 <router-link> 组件
  Vue.component('RouterView', RouterView)
  Vue.component('RouterLink', RouterLink)
}
```

> 💡 **核心规律**：所有 Vue 插件（Router、Vuex、Element UI 等）都遵循这个模式——实现一个 `install(Vue)` 方法，通过 `Vue.mixin`、`Vue.prototype` 或全局组件来扩展 Vue。`Vue.use()` 负责调用这个方法并防止重复安装。

### 14.2 基本配置

```js
// router/index.js
import Vue from 'vue'
import VueRouter from 'vue-router'

Vue.use(VueRouter)                   // 安装插件，注入 $router 和 $route

const routes = [
  { path: '/', component: () => import('@/views/Home.vue') },
  { path: '/about', component: () => import('@/views/About.vue') },
  { path: '/user/:id', component: () => import('@/views/User.vue') },  // 动态路由
  { path: '*', component: () => import('@/views/404.vue') },            // 兜底
]

export default new VueRouter({
  mode: 'history',                   // 'hash'（默认） 或 'history'
  routes,
})
```

### 14.2 路由跳转

```js
// 声明式（模板中）
<router-link to="/about">关于</router-link>
<router-link :to="{ name: 'user', params: { id: 123 } }">用户</router-link>

// 编程式（JS 中）
this.$router.push('/about')
this.$router.push({ name: 'user', params: { id: 123 } })
this.$router.replace('/about')      // 替换当前记录（不留历史）
this.$router.go(-1)                  // 后退
```

### 14.3 路由参数

```js
// 路由配置：{ path: '/user/:id', ... }
// URL：/user/123

// 在组件中获取参数
this.$route.params.id               // '123'
this.$route.query.tab               // URL: /user/123?tab=posts → 'posts'
this.$route.hash                    // URL: /user/123#info → '#info'

// 推荐用 props 解耦：
{ path: '/user/:id', component: User, props: true }
// 这样 :id 会作为 prop 传给组件，组件不再依赖 $route
```

### 14.4 导航守卫

```js
// 全局前置守卫——每次路由跳转都会执行
router.beforeEach((to, from, next) => {
  const isLoggedIn = store.state.token

  if (to.meta.requiresAuth && !isLoggedIn) {
    next('/login')                   // 未登录，跳到登录页
  } else {
    next()                           // 放行
  }
})

// 路由独享守卫
{
  path: '/admin',
  component: Admin,
  beforeEnter(to, from, next) {
    // 只有进入这个路由时才执行
    if (store.state.user.role !== 'admin') next('/')
    else next()
  },
}

// 组件内守卫
export default {
  beforeRouteEnter(to, from, next) {
    // 进入该组件的路由前（此时组件还没创建，没有 this）
    next(vm => { /* vm 是组件实例 */ })
  },
  beforeRouteUpdate(to, from, next) {
    // 路由参数变了但组件复用时（如 /user/1 → /user/2）
    this.fetchUser(to.params.id)
    next()
  },
  beforeRouteLeave(to, from, next) {
    // 离开该组件时（适合提示"有未保存的修改"）
    if (this.hasUnsavedChanges) {
      if (confirm('有未保存的修改，确定离开？')) next()
      else next(false)
    } else {
      next()
    }
  },
}
```

### 14.5 hash 模式 vs history 模式

| 对比 | hash | history |
|------|------|---------|
| URL 样子 | `example.com/#/about` | `example.com/about` |
| 原理 | 监听 `hashchange` 事件 | 用 `pushState` / `popstate` API |
| 需要服务器配置 | ❌ 不需要 | ✅ 需要（所有路径都返回 index.html） |
| SEO | 差（搜索引擎不读 # 后面的） | 好 |

### 14.6 路由懒加载

```js
// 不用懒加载：所有页面打包成一个大 JS 文件
import Home from '@/views/Home.vue'

// ✅ 懒加载：每个页面单独打包，访问时才加载
const Home = () => import('@/views/Home.vue')

// 带 webpack 魔法注释：指定 chunk 名
const Home = () => import(/* webpackChunkName: "home" */ '@/views/Home.vue')
```

> 💡 懒加载的原理是 webpack 的**代码分割**（Code Splitting）。`import()` 返回 Promise，webpack 会把它单独打包成一个 chunk，浏览器访问对应路由时才下载这个 chunk。

---

## 十五、Vuex 3

### 15.1 核心概念

Vuex 就是一个**全局的响应式数据仓库**。所有组件共享同一个 store。

```
组件 ──dispatch──→ Actions ──commit──→ Mutations ──→ State ──→ 组件
                  （异步）              （同步）        （响应式）
```

为什么要区分 Actions 和 Mutations？因为**Mutations 必须是同步的**，这样 devtools 才能追踪每一次状态变化。异步操作放在 Actions 里。

### 15.2 完整示例

```js
// store/index.js
import Vue from 'vue'
import Vuex from 'vuex'

Vue.use(Vuex)

export default new Vuex.Store({
  // 状态（响应式数据）
  state: {
    user: null,
    token: '',
    cart: [],
  },

  // 同步修改 state 的唯一途径
  mutations: {
    SET_USER(state, user) {
      state.user = user
    },
    SET_TOKEN(state, token) {
      state.token = token
    },
    ADD_TO_CART(state, item) {
      state.cart.push(item)
    },
  },

  // 异步操作（调 API 等），完成后 commit mutation
  actions: {
    async login({ commit }, { username, password }) {
      const res = await api.login(username, password)
      commit('SET_TOKEN', res.token)
      commit('SET_USER', res.user)
    },
    async fetchCart({ commit }) {
      const cart = await api.getCart()
      cart.forEach(item => commit('ADD_TO_CART', item))
    },
  },

  // 派生数据（类似 computed）
  getters: {
    isLoggedIn: state => !!state.token,
    cartTotal: state => state.cart.reduce((sum, item) => sum + item.price, 0),
    cartCount: state => state.cart.length,
  },
})
```

### 15.3 组件中使用

```js
import { mapState, mapGetters, mapMutations, mapActions } from 'vuex'

export default {
  computed: {
    // 方式 1：直接访问
    username() { return this.$store.state.user?.name },

    // 方式 2：mapState 辅助函数
    ...mapState(['user', 'token']),
    ...mapGetters(['isLoggedIn', 'cartTotal']),
  },

  methods: {
    ...mapMutations(['SET_USER']),
    ...mapActions(['login']),

    handleLogin() {
      this.login({ username: 'admin', password: '123' })
    },
  },
}
```

### 15.4 Module——大型项目拆分

```js
// store/modules/user.js
export default {
  namespaced: true,                  // ★ 开启命名空间
  state: () => ({ name: '', role: '' }),
  mutations: {
    SET_NAME(state, name) { state.name = name },
  },
  actions: {
    async fetchProfile({ commit }) {
      const user = await api.getProfile()
      commit('SET_NAME', user.name)
    },
  },
}

// store/index.js
import user from './modules/user'
import cart from './modules/cart'

export default new Vuex.Store({
  modules: { user, cart },
})

// 组件中使用（带命名空间）
this.$store.state.user.name                    // 读 state
this.$store.commit('user/SET_NAME', '张三')     // 调 mutation
this.$store.dispatch('user/fetchProfile')       // 调 action

// 或用辅助函数
...mapState('user', ['name', 'role'])
...mapActions('user', ['fetchProfile'])
```

### 15.5 Vuex 的响应式原理

```js
// Vuex 的 state 之所以是响应式的，是因为它内部创建了一个隐藏的 Vue 实例：

// 源码简化版：src/store.js
class Store {
  constructor(options) {
    // ★ 用一个 Vue 实例来保存 state，利用 Vue 的响应式系统
    this._vm = new Vue({
      data: { $$state: options.state },
    })
  }

  get state() {
    return this._vm._data.$$state   // 读 state 就是读这个 Vue 实例的 data
  }
}

// 所以 Vuex 的 state 自动就是响应式的——
// 组件渲染时读取 $store.state.xxx → 触发 getter → 收集依赖
// mutations 修改 state → 触发 setter → 通知组件更新
```

> 💡 这就是为什么 Vuex 必须配合 Vue 使用——它依赖 Vue 的响应式系统来实现数据驱动更新。

---

## 十六、nextTick 与异步更新

### 16.1 为什么需要 nextTick

```js
this.msg = '新消息'
console.log(this.$refs.msgEl.textContent)   // ❌ 还是旧内容！

this.$nextTick(() => {
  console.log(this.$refs.msgEl.textContent) // ✅ 新内容
})
```

因为 Vue 的 DOM 更新是**异步的**（第五章 5.9 讲过）。你改了 data，Vue 不会立即更新 DOM，而是把更新推入微任务队列，等当前同步代码执行完再批量更新。`nextTick` 就是让你的回调排在 DOM 更新之后执行。

### 16.2 nextTick 源码

```js
// 源码简化版：src/core/util/next-tick.js

const callbacks = []                // 回调队列
let pending = false

function nextTick(cb) {
  callbacks.push(cb)
  if (!pending) {
    pending = true
    // ★ 把 flushCallbacks 推入微任务队列
    Promise.resolve().then(flushCallbacks)
  }
}

function flushCallbacks() {
  pending = false
  const copies = callbacks.slice(0)
  callbacks.length = 0
  for (let i = 0; i < copies.length; i++) {
    copies[i]()                     // 依次执行所有回调
  }
}
```

**降级策略**（Promise 不可用时）：

```
Promise.then（微任务）
  ↓ 不支持
MutationObserver（微任务）
  ↓ 不支持
setImmediate（宏任务，IE/Node）
  ↓ 不支持
setTimeout(fn, 0)（宏任务，兜底）
```

### 16.3 执行顺序

```js
this.msg = 'A'                    // ① setter → queueWatcher → nextTick(flushSchedulerQueue)
this.msg = 'B'                    // ② setter → queueWatcher → 去重，不再入队
this.$nextTick(() => {            // ③ 回调入队
  console.log('DOM 更新后')
})
console.log('同步代码')            // ④ 先执行

// 执行顺序：④ → DOM 更新（flushSchedulerQueue） → ③
// 输出：'同步代码' → DOM 显示 'B' → 'DOM 更新后'
```

> 💡 `this.$nextTick()` 也支持 Promise 写法：`await this.$nextTick()`。

---

## 十七、keep-alive 与性能优化

### 17.1 keep-alive 是什么

`<keep-alive>` 是 Vue 内置组件，用来**缓存不活动的组件实例**，避免反复销毁和重建。

```html
<!-- 切换标签时，组件不会销毁，而是缓存起来 -->
<keep-alive>
  <component :is="currentTab"></component>
</keep-alive>

<!-- 配合路由使用 -->
<keep-alive>
  <router-view />
</keep-alive>

<!-- 指定缓存哪些 / 排除哪些 -->
<keep-alive include="Home,UserList" exclude="UserDetail">
  <router-view />
</keep-alive>

<!-- max 限制最多缓存几个（超过就淘汰最久没用的） -->
<keep-alive :max="10">
  <router-view />
</keep-alive>
```

### 17.2 activated 和 deactivated

被 keep-alive 缓存的组件**不会触发** created/mounted/destroyed，而是触发两个专属钩子：

```js
export default {
  activated() {
    // 组件被激活时（从缓存中取出显示）
    // 适合：刷新数据、恢复滚动位置
    this.fetchLatestData()
  },
  deactivated() {
    // 组件被停用时（被缓存起来）
    // 适合：暂停定时器、暂停视频播放
    clearInterval(this.timer)
  },
}
```

### 17.3 keep-alive 的缓存原理（LRU 算法）

```js
// 源码简化版：src/core/components/keep-alive.js

export default {
  name: 'keep-alive',
  abstract: true,                   // 抽象组件，不渲染 DOM，不出现在父子链中

  props: { include, exclude, max },

  created() {
    this.cache = Object.create(null) // 缓存对象：{ key: vnode }
    this.keys = []                   // 缓存 key 的顺序（用于 LRU）
  },

  render() {
    const slot = this.$slots.default
    const vnode = slot[0]            // 获取第一个子组件的 vnode
    const key = vnode.key || vnode.componentOptions.Ctor.cid

    if (this.cache[key]) {
      // ★ 命中缓存：复用旧的组件实例
      vnode.componentInstance = this.cache[key].componentInstance
      // LRU：把 key 移到最后（表示最近使用）
      remove(this.keys, key)
      this.keys.push(key)
    } else {
      // ★ 未命中：存入缓存
      this.cache[key] = vnode
      this.keys.push(key)

      // 超过 max，淘汰最久没使用的（LRU）
      if (this.max && this.keys.length > parseInt(this.max)) {
        const oldestKey = this.keys[0]
        this.cache[oldestKey].componentInstance.$destroy()
        delete this.cache[oldestKey]
        this.keys.shift()
      }
    }

    vnode.data.keepAlive = true      // 标记为 keep-alive 组件
    return vnode
  },
}
```

> 💡 **LRU（Least Recently Used）**：最近最少使用淘汰策略。每次访问缓存组件就把它移到队尾，淘汰时删队头（最久没用的）。

### 17.4 性能优化清单

| 优化手段 | 说明 |
|---------|------|
| `v-if` vs `v-show` | 频繁切换用 v-show，很少变用 v-if |
| `v-for` 加 `:key` | 用唯一 ID，不用 index |
| `computed` 代替 `methods` | 利用缓存避免重复计算 |
| 路由懒加载 | `() => import('./xxx.vue')` |
| `keep-alive` | 缓存不变的页面组件 |
| `Object.freeze()` | 大量纯展示数据不需要响应式，冻结后 Vue 不会 observe |
| 函数式组件 | 无状态组件用 `functional: true`，没有实例开销 |
| 长列表虚拟滚动 | 用 `vue-virtual-scroller`，只渲染可见区域 |

```js
// Object.freeze 示例：
export default {
  data() {
    return {
      // 这个大数组只用于展示，不需要修改
      // freeze 后 Vue 不会给每个元素加 getter/setter，节省初始化时间
      bigList: Object.freeze(hugeArray),
    }
  },
}
```

**函数式组件示例**：

```html
<!-- ❌ 普通组件：哪怕只是渲染一个 label，也有完整实例开销 -->
<script>
export default {
  props: ['label', 'value'],
}
</script>
<template>
  <span class="tag">{{ label }}: {{ value }}</span>
</template>

<!-- ✅ 函数式组件：无实例、无响应式、无生命周期，渲染更快 -->
<template functional>
  <span class="tag">{{ props.label }}: {{ props.value }}</span>
</template>

<script>
export default {
  functional: true,    // ★ 声明为函数式组件
  props: ['label', 'value'],
}
</script>
```

> 💡 函数式组件没有 `this`（无实例），模板里用 `props.xxx` 访问数据。适用场景：纯展示、不需要内部状态、不需要生命周期的叶子节点组件（如 Tag、Badge、Icon 等）。在长列表中大量渲染这类组件时，性能提升明显。

---

## 十八、总结——回到全链路

恭喜你读到这里。现在让我们回到第一章的全链路图，你会发现每个环节都已经深入理解了：

```
你写的 .vue 文件
  │
  ▼ 编译（第四章）
  │  template → render 函数
  │
  ▼ 初始化（第三、五章）
  │  data → Observer → defineReactive → 每个属性有 getter/setter + Dep
  │
  ▼ 挂载（第七章）
  │  创建渲染 Watcher → 执行 render → 读取数据 → 依赖收集
  │  render 返回 VNode → patch → 创建真实 DOM
  │
  ▼ 更新（第五、六、七章）
  │  修改数据 → setter → dep.notify() → Watcher.update()
  │  → queueWatcher → nextTick 批量执行 → 重新 render → Diff → 最小化 DOM 更新
  │
  ▼ 销毁（第十章）
     移除 Watcher、解绑指令、移除事件
```

### 核心概念速查表

| 概念 | 一句话解释 | 章节 |
|------|-----------|------|
| Observer | 递归劫持对象属性，装上 getter/setter | 第五章 |
| Dep | 每个属性的依赖收集箱，存谁在用这个属性 | 第五章 |
| Watcher | 观察者，分渲染/计算/用户三种 | 第五、六章 |
| VNode | 用 JS 对象描述 DOM 节点 | 第七章 |
| patch | 对比新旧 VNode，最小化 DOM 操作 | 第七章 |
| 双端 Diff | 四指针从两端向中间靠拢的子节点对比算法 | 第七章 |
| key | 让 Diff 精确识别节点身份 | 第七章 |
| computed | lazy Watcher + dirty 标记实现缓存 | 第六章 |
| watch / deep | traverse 递归读取触发依赖收集 | 第六章 |
| nextTick | 微任务队列，DOM 更新后执行回调 | 第十六章 |
| keep-alive | LRU 缓存策略，复用组件实例 | 第十七章 |
| provide/inject | 沿 $parent 链向上查找 _provided | 第八章 |
| 作用域插槽 | 父传渲染函数，子调用并传数据 | 第九章 |
| Vuex | 内部用隐藏 Vue 实例保存 state，借用响应式系统 | 第十五章 |

### Vue 2 → Vue 3 关键变化

| Vue 2 | Vue 3 | 为什么要改 |
|-------|-------|-----------|
| Options API | Composition API | 逻辑复用更灵活，替代 mixin |
| Object.defineProperty | Proxy | 能检测新增/删除属性，性能更好 |
| v-for 优先于 v-if | v-if 优先于 v-for | 更符合直觉 |
| $listeners | 合并到 $attrs | 简化 API |
| 双端 Diff | 双端 Diff + 最长递增子序列 | 减少 DOM 移动操作 |
| 全局 API（Vue.use 等） | 实例 API（app.use 等） | 避免全局污染 |
| template 根节点必须单个 | 支持多根节点（Fragment） | 减少无意义的包裹层 |

---

> 💡 **最后的话**：Vue 2 的所有设计都围绕一个核心循环——**数据变 → 通知 → 重新渲染 → 最小化更新 DOM**。理解了这个循环，再遇到任何 Vue 2 的问题，你都能从原理层面想清楚它是怎么回事。
