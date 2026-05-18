# Vue 3 精讲

## 一、全局视角：Vue 3 运行全链路

> 先看全貌，再看细节。Vue 3 的一切用法都能从这条链路推导出来。

### Vue 3 vs Vue 2：三个核心升级

| | Vue 2 | Vue 3 |
|---|---|---|
| 响应式 | `Object.defineProperty`（逐个劫持属性） | `Proxy`（代理整个对象） |
| API 风格 | Options API（data/methods/computed 分散写） | Composition API（按功能聚合） |
| 编译优化 | 每次 Diff 遍历整棵 VNode 树 | PatchFlags + 静态提升，只 Diff 动态节点 |

### 运行全链路图

```
你写的 .vue 文件（<script setup> + <template> + <style>）
  ↓ 编译阶段（Vite + @vue/compiler-sfc）
JS 模块：setup 函数 + render 函数（带 PatchFlags 标记）
  ↓ 运行时：执行 setup
创建响应式数据（Proxy 代理）
  ↓ 运行时：执行 render
读取响应式数据 → 触发 Proxy 的 get → track（收集依赖）→ 生成 VNode 树
  ↓ 运行时：mount
VNode → 创建真实 DOM → 挂载到页面
  ↓ 数据变化
触发 Proxy 的 set → trigger（通知依赖）→ 重新执行 render → 新 VNode
  ↓ Diff（快速 Diff 算法）
对比新旧 VNode，靠 PatchFlags 跳过静态节点，只更新动态部分
  ↓ patch
最小化 DOM 操作 → 页面更新
```

> **和 Vue 2 的关键区别**：Vue 2 是 `defineProperty + 双端 Diff 遍历全树`，Vue 3 是 `Proxy + PatchFlags 只 Diff 动态节点`，性能提升的核心就在这两点。

---

## 二、环境搭建

### 创建项目

```bash
npm create vite@latest my-project -- --template vue
cd my-project
npm install
npm run dev
```

> 不用 Vue CLI 了。Vue 3 官方推荐 Vite，启动快（按需编译，不打包全部文件）。

### 项目结构

```
my-project/
├── index.html          ← Vite 入口（不是 public/index.html）
├── src/
│   ├── main.js         ← 应用入口
│   ├── App.vue         ← 根组件
│   └── components/     ← 组件目录
├── vite.config.js      ← Vite 配置
└── package.json
```

### 入口文件：createApp 替代 new Vue

```js
// Vue 2
import Vue from 'vue'
new Vue({ render: h => h(App) }).$mount('#app')

// Vue 3
import { createApp } from 'vue'
import App from './App.vue'
createApp(App).mount('#app')
```

**为什么改成 createApp？**

```js
// Vue 2 的问题：全局配置污染
Vue.mixin({ ... })       // 影响所有 Vue 实例
Vue.component('Btn', Btn) // 全局注册，影响所有实例

// 如果一个页面有两个 Vue 应用，它们共享同一个 Vue 构造函数
// 一个应用注册的全局组件/mixin，另一个也会受影响

// Vue 3 的解决：每个应用独立
const app1 = createApp(App1)
const app2 = createApp(App2)
app1.component('Btn', Btn)  // 只影响 app1
app2.mixin({ ... })         // 只影响 app2
// 互不干扰
```

> **createApp 的本质**：把全局 API 从「挂在 Vue 构造函数上」改成「挂在应用实例上」，解决多应用隔离问题。

---

## 三、两种 API 风格 + `<script setup>`

### Options API（Vue 2 的写法，Vue 3 仍然支持）

```html
<script>
export default {
  data() {
    return { count: 0 }
  },
  computed: {
    double() { return this.count * 2 }
  },
  methods: {
    increment() { this.count++ }
  },
  mounted() {
    console.log('组件挂载了')
  },
}
</script>
```

**问题**：功能 A 的数据在 data，方法在 methods，计算属性在 computed——同一个功能的代码**散落在不同选项里**。组件大了之后来回跳着看，很痛苦。

### Composition API（Vue 3 推荐）

```html
<script>
import { ref, computed, onMounted } from 'vue'

export default {
  setup() {
    // 功能 A 的所有代码放在一起
    const count = ref(0)
    const double = computed(() => count.value * 2)
    function increment() { count.value++ }
    onMounted(() => console.log('组件挂载了'))

    // 必须 return 出去，模板才能用
    return { count, double, increment }
  },
}
</script>
```

**优势**：同一个功能的数据、方法、生命周期钩子写在一起，按功能组织而不是按选项分类。

### `<script setup>`：Composition API 的语法糖

```html
<script setup>
import { ref, computed, onMounted } from 'vue'

// 不用写 setup() 函数，不用 return
// 顶层声明的变量、函数自动暴露给模板
const count = ref(0)
const double = computed(() => count.value * 2)
function increment() { count.value++ }
onMounted(() => console.log('组件挂载了'))
</script>

<template>
  <button @click="increment">{{ count }} × 2 = {{ double }}</button>
</template>
```

> **`<script setup>` 的本质**：编译器自动帮你生成 `setup()` 函数和 `return`，少写模板代码，其他完全一样。

### defineProps / defineEmits / defineExpose

```html
<script setup>
// defineProps：声明 props（编译器宏，不需要 import）
const props = defineProps({
  name: String,
  age: { type: Number, default: 18 },
})

// defineEmits：声明事件
const emit = defineEmits(['update', 'delete'])
function handleClick() {
  emit('update', props.name)
}

// defineExpose：暴露给父组件通过 ref 访问的属性
defineExpose({ handleClick })
</script>
```

**编译后等价于什么？**

```js
// <script setup> 编译后生成的组件对象（简化版）：
export default {
  props: {
    name: String,
    age: { type: Number, default: 18 },
  },
  emits: ['update', 'delete'],
  setup(props, { emit, expose }) {
    function handleClick() {
      emit('update', props.name)
    }
    expose({ handleClick })
    return { handleClick }
  },
}
```

> **defineProps / defineEmits 不是运行时函数**，是**编译器宏**。它们在编译阶段被转换成组件选项，运行时根本不存在。所以不需要 import，直接写就行。

### withDefaults（TS 场景下给 props 设默认值）

```html
<script setup lang="ts">
interface Props {
  name: string
  age?: number
  tags?: string[]
}

// TypeScript 的类型声明 + withDefaults 设默认值
const props = withDefaults(defineProps<Props>(), {
  age: 18,
  tags: () => [],  // 引用类型必须用工厂函数
})
</script>
---

## 四、响应式原理（Proxy）

### ref 和 reactive：两种创建响应式数据的方式

```html
<script setup>
import { ref, reactive } from 'vue'

// ref：包装基本类型（也能包装对象）
const count = ref(0)
console.log(count.value)  // 0（JS 中要 .value）

// reactive：包装对象
const user = reactive({ name: '张三', age: 25 })
console.log(user.name)    // '张三'（不需要 .value）
</script>

<template>
  <!-- 模板中 ref 自动解包，不用写 .value -->
  <p>{{ count }}</p>
  <p>{{ user.name }}</p>
</template>
```

### 原理：为什么 ref 要 .value

```js
// ref 的简化实现
function ref(rawValue) {
  return {
    get value() {
      track(this, 'value')  // 收集依赖
      return rawValue
    },
    set value(newVal) {
      rawValue = newVal
      trigger(this, 'value')  // 通知更新
    },
    __v_isRef: true,  // 标记这是一个 ref
  }
}

// 为什么需要 .value？
// 因为 JS 的基本类型（number/string/boolean）不是对象，Proxy 无法代理
// 所以 ref 用一个 { value: xxx } 对象把基本类型包起来
// 通过 value 属性的 getter/setter 来实现响应式

// 模板中为什么不用 .value？
// 编译器自动帮你加了：{{ count }} 编译成 count.value
```

### 原理：reactive 的 Proxy 实现

```js
// 简化版 reactive
function reactive(target) {
  return new Proxy(target, {
    get(target, key, receiver) {
      track(target, key)  // 收集依赖：谁在读这个属性
      const result = Reflect.get(target, key, receiver)
      // 如果值是对象，递归代理（懒代理：用到才代理，不像 Vue 2 一次性递归）
      if (typeof result === 'object' && result !== null) {
        return reactive(result)
      }
      return result
    },
    set(target, key, value, receiver) {
      const oldValue = target[key]
      const result = Reflect.set(target, key, value, receiver)
      if (oldValue !== value) {
        trigger(target, key)  // 通知更新：这个属性变了
      }
      return result
    },
    deleteProperty(target, key) {
      const result = Reflect.deleteProperty(target, key)
      trigger(target, key)  // 删除属性也能触发更新！
      return result
    },
  })
}
```

### 原理：Proxy vs Object.defineProperty

| | Vue 2（defineProperty） | Vue 3（Proxy） |
|---|---|---|
| 劫持方式 | 逐个属性定义 getter/setter | 代理整个对象 |
| 新增属性 | ❌ 检测不到，需要 `$set` | ✅ 自动检测 |
| 删除属性 | ❌ 检测不到，需要 `$delete` | ✅ 自动检测 |
| 数组索引修改 | ❌ 检测不到 | ✅ 自动检测 |
| 深层对象 | 初始化时递归遍历所有层级 | 懒代理：访问到才代理（性能更好） |
| 兼容性 | IE9+ | 不支持 IE（Proxy 无法 polyfill） |

> **Vue 3 放弃 IE 的根本原因**：Proxy 无法用 polyfill 模拟，这是语言层面的限制。

### 原理：track 和 trigger（依赖收集与通知）

```js
// 全局依赖存储结构
// targetMap: WeakMap<target, Map<key, Set<effect>>>
const targetMap = new WeakMap()

// 当前正在执行的 effect（类似 Vue 2 的 Dep.target）
let activeEffect = null

function track(target, key) {
  if (!activeEffect) return
  let depsMap = targetMap.get(target)
  if (!depsMap) {
    depsMap = new Map()
    targetMap.set(target, depsMap)
  }
  let dep = depsMap.get(key)
  if (!dep) {
    dep = new Set()
    depsMap.set(key, dep)
  }
  dep.add(activeEffect)  // 把当前 effect 加入依赖集合
}

function trigger(target, key) {
  const depsMap = targetMap.get(target)
  if (!depsMap) return
  const dep = depsMap.get(key)
  if (!dep) return
  dep.forEach(effect => effect.run())  // 通知所有依赖的 effect 重新执行
}
```

```
存储结构示意：
targetMap = {
  user对象 → {
    'name' → [渲染effect, watchEffect_1],
    'age'  → [渲染effect, computed_double],
  }
}
```

> **和 Vue 2 的对比**：Vue 2 用 Dep 类 + Watcher 类，Vue 3 用 WeakMap + Set + effect 函数。思路一样（收集 → 通知），但 Vue 3 的结构更扁平，不依赖类继承。

### 常见坑

```js
// 坑 1：reactive 解构会丢失响应性
const user = reactive({ name: '张三', age: 25 })
const { name } = user  // ❌ name 变成普通字符串，失去响应性
const { name } = toRefs(user)  // ✅ toRefs 把每个属性转成 ref

// 坑 2：reactive 整体替换会丢失响应性
let user = reactive({ name: '张三' })
user = reactive({ name: '李四' })  // ❌ 模板还指向旧对象
user.name = '李四'  // ✅ 修改属性，不要替换整个对象

// 坑 3：ref 在 JS 中忘写 .value
const count = ref(0)
count++      // ❌ 这是给 count 变量重新赋值，不是修改 ref
count.value++ // ✅
```

---

## 五、computed / watch / watchEffect

### computed：和 Vue 2 几乎一样，只是写法变了

```html
<script setup>
import { ref, computed } from 'vue'

const firstName = ref('张')
const lastName = ref('三')

// 只读
const fullName = computed(() => firstName.value + lastName.value)

// 可读可写
const fullName2 = computed({
  get: () => firstName.value + lastName.value,
  set: (val) => {
    firstName.value = val[0]
    lastName.value = val.slice(1)
  },
})
</script>
```

**原理和 Vue 2 一样**：dirty 标记 + 缓存。依赖没变就返回缓存值，依赖变了标记 dirty，下次访问才重新计算。

### watch：侦听特定数据源

```html
<script setup>
import { ref, reactive, watch } from 'vue'

const count = ref(0)
const user = reactive({ name: '张三', profile: { age: 25 } })

// 侦听 ref
watch(count, (newVal, oldVal) => {
  console.log(`count: ${oldVal} → ${newVal}`)
})

// 侦听 reactive 的某个属性（必须用 getter 函数）
watch(
  () => user.name,
  (newVal, oldVal) => {
    console.log(`name: ${oldVal} → ${newVal}`)
  }
)

// 侦听多个数据源
watch(
  [count, () => user.name],
  ([newCount, newName], [oldCount, oldName]) => {
    console.log('count 或 name 变了')
  }
)

// deep + immediate
watch(
  () => user.profile,
  (newVal) => { console.log('profile 变了') },
  { deep: true, immediate: true }
)
</script>
```

### watchEffect：自动收集依赖

```html
<script setup>
import { ref, watchEffect } from 'vue'

const keyword = ref('')
const page = ref(1)

// 不需要指定侦听谁，用到谁就自动侦听谁
watchEffect(() => {
  // 这个函数里读了 keyword.value 和 page.value
  // 所以它们任何一个变化，都会重新执行这个函数
  console.log(`搜索：${keyword.value}，第 ${page.value} 页`)
  fetchData(keyword.value, page.value)
})

// 停止侦听
const stop = watchEffect(() => { ... })
stop()  // 手动停止
</script>
```

### 原理：watchEffect 怎么做到自动收集依赖

```js
// 简化版原理
function watchEffect(fn) {
  const effect = new ReactiveEffect(fn)

  // 1. 把这个 effect 设为 activeEffect
  activeEffect = effect
  // 2. 执行 fn → fn 里读了 keyword.value → 触发 Proxy 的 get → track 收集了这个 effect
  fn()
  // 3. 清空 activeEffect
  activeEffect = null

  // 之后 keyword 变化 → trigger → 重新执行 fn → 重新收集依赖
  // 每次执行前会清除旧依赖，重新收集（所以条件分支里的依赖能正确更新）
}
```

> **和 Vue 2 的 Watcher 对比**：Vue 2 的 Watcher 也是同样的原理（设 Dep.target → 执行 getter → 收集 → 清空）。Vue 3 只是把 Watcher 换成了 effect 函数。

### 三者对比

| | computed | watch | watchEffect |
|---|---|---|---|
| 目的 | 计算派生值 | 监听变化后执行副作用 | 自动追踪依赖并执行副作用 |
| 指定数据源 | 自动（读谁就依赖谁） | 手动指定 | 自动（读谁就依赖谁） |
| 有返回值 | ✅ 返回计算结果 | ❌ | ❌ |
| 有缓存 | ✅ dirty 标记 | ❌ | ❌ |
| 立即执行 | ❌ 懒执行（用到才算） | ❌ 默认不立即（除非 immediate） | ✅ 立即执行一次 |
| 能拿到旧值 | ❌ | ✅ (newVal, oldVal) | ❌ |
| 适合场景 | 模板显示的派生数据 | 数据变化后调接口、弹提示 | 自动同步多个数据源 |

> **选择口诀**：要返回值用 computed，要旧值用 watch，其他用 watchEffect。

---

## 六、模板编译与优化

> 这是 Vue 3 性能提升最大的地方。Vue 2 每次更新都 Diff 整棵树，Vue 3 只 Diff 动态节点。

### 优化 1：PatchFlags（补丁标记）

```html
<template>
  <div>
    <h1>Vue 3 精讲</h1>        <!-- 静态节点 -->
    <p>{{ message }}</p>        <!-- 动态节点：文本会变 -->
    <span :class="cls">hi</span> <!-- 动态节点：class 会变 -->
  </div>
</template>
```

编译后的 render 函数：

```js
import { createElementVNode as _c, toDisplayString as _s, openBlock as _o, createElementBlock as _b } from 'vue'

function render(_ctx) {
  return (_o(), _b('div', null, [
    _c('h1', null, 'Vue 3 精讲'),                       // 没有 PatchFlag → 静态
    _c('p', null, _s(_ctx.message), 1 /* TEXT */),       // PatchFlag = 1 → 只有文本是动态的
    _c('span', { class: _ctx.cls }, 'hi', 2 /* CLASS */), // PatchFlag = 2 → 只有 class 是动态的
  ]))
}
```

| PatchFlag 值 | 含义 | Diff 时只检查 |
|---|---|---|
| 1 (TEXT) | 动态文本 | textContent |
| 2 (CLASS) | 动态 class | className |
| 4 (STYLE) | 动态 style | style 对象 |
| 8 (PROPS) | 动态属性 | 指定的 props |
| 32 (NEED_HYDRATION) | 需要 hydration | - |
| 64 (STABLE_FRAGMENT) | 子节点顺序稳定 | - |

> **Vue 2 的 Diff**：遍历整棵 VNode 树，逐个比较所有属性。
> **Vue 3 的 Diff**：看到 PatchFlag = 1，直接只比较 textContent，跳过 class、style、attrs 等所有其他属性。

### 优化 2：静态提升（hoistStatic）

```js
// Vue 2：每次渲染都重新创建静态节点的 VNode
function render() {
  return _c('div', [
    _c('h1', null, 'Vue 3 精讲'),  // 每次都创建新的 VNode 对象
    _c('p', null, _s(message)),
  ])
}

// Vue 3：静态节点提升到 render 函数外面，只创建一次
const _hoisted_1 = _c('h1', null, 'Vue 3 精讲')  // 只创建一次，复用

function render() {
  return _c('div', [
    _hoisted_1,                     // 直接引用，不重新创建
    _c('p', null, _s(message), 1),
  ])
}
```

> **好处**：减少 VNode 创建开销 + Diff 时直接跳过（引用相同 = 没变化）。

### 优化 3：Block Tree（块树）

```js
// Vue 3 的 Block 会收集所有动态子节点到一个扁平数组
// Diff 时不再递归遍历整棵树，而是直接遍历这个数组

function render(_ctx) {
  return (_o(), _b('div', null, [
    _hoisted_1,                              // 静态，跳过
    _hoisted_2,                              // 静态，跳过
    _c('p', null, _s(_ctx.msg), 1 /* TEXT */), // 动态，收集
    _c('span', { id: _ctx.id }, 'hi', 8, ['id']), // 动态，收集
  ]))
}

// openBlock() 开启一个 Block
// createElementBlock() 关闭 Block，把 Block 内的动态节点收集到 dynamicChildren 数组
// Diff 时只遍历 dynamicChildren，不遍历 children

// 假设模板有 100 个节点，只有 3 个是动态的
// Vue 2：Diff 100 个节点
// Vue 3：Diff 3 个节点（dynamicChildren 里只有 3 个）
```

### 优化 4：事件缓存（cacheHandlers）

```js
// Vue 2：每次渲染都创建新的事件函数
_c('button', { on: { click: () => _ctx.handleClick() } })
// 新旧 VNode 的事件函数引用不同 → 需要 removeEventListener + addEventListener

// Vue 3：缓存事件处理函数
_c('button', {
  onClick: _cache[0] || (_cache[0] = () => _ctx.handleClick())
})
// 第一次创建并缓存，之后复用同一个函数引用 → 不需要重新绑定事件
```

### 指令的编译结果

```js
// v-if 编译后：条件渲染
(_ctx.show)
  ? _c('div', null, '显示')
  : _c('div', null, '隐藏')  // 或者 createCommentVNode("v-if")

// v-show 编译后：切换 display
_c('div', {
  style: { display: _ctx.show ? null : 'none' }
}, '内容')

// v-for 编译后：循环 + Fragment
(_o(true), _b(Fragment, null,
  renderList(_ctx.list, (item) => {
    return _c('div', { key: item.id }, _s(item.name), 1)
  }),
  128 /* KEYED_FRAGMENT */
))

// v-model 编译后（input）：value + onInput 的语法糖
_c('input', {
  value: _ctx.msg,
  onInput: ($event) => { _ctx.msg = $event.target.value }
})
```

---

## 七、虚拟 DOM 与 Diff（快速 Diff）

### VNode 长什么样

```js
// Vue 3 的 VNode 比 Vue 2 多了 patchFlag 和 dynamicChildren
const vnode = {
  type: 'div',                    // Vue 2 叫 tag
  props: { id: 'app' },          // Vue 2 叫 data
  children: [
    { type: 'p', children: 'hello', patchFlag: 1 /* TEXT */ },
  ],
  patchFlag: 0,
  dynamicChildren: [              // Vue 2 没有这个！
    { type: 'p', children: 'hello', patchFlag: 1 },
  ],
}
```

### Diff 流程：先走捷径，再用算法

Vue 3 的快速 Diff 算法分三步：

**第一步：预处理——从头和从尾找相同节点**

```
旧：[A, B, C, D, E]
新：[A, B, F, G, E]

从头比：A=A ✅，B=B ✅，C≠F 停下
从尾比：E=E ✅，D≠G 停下

剩下需要处理的：
旧：[C, D]
新：[F, G]
```

> **Vue 2 的双端 Diff 没有这步预处理**，直接用四个指针比。Vue 3 先处理头尾相同的部分，很多场景（比如只改了中间一个元素）在这步就结束了。

**第二步：简单情况——只有新增或只有删除**

```
// 情况 1：旧的处理完了，新的还有剩余 → 新增
旧：[A, B]
新：[A, B, C, D]
→ 新增 C, D

// 情况 2：新的处理完了，旧的还有剩余 → 删除
旧：[A, B, C, D]
新：[A, B]
→ 删除 C, D
```

**第三步：复杂情况——最长递增子序列（LIS）**

```
// 旧的和新的都有剩余，需要判断：移动、新增、删除

旧：[A, B, C, D, E]
新：[A, D, B, C, E]

预处理后剩余：
旧：[B, C, D]  索引 [1, 2, 3]
新：[D, B, C]

步骤：
1. 建立新节点的 key → index 映射：{ D: 0, B: 1, C: 2 }
2. 遍历旧节点，查找在新节点中的位置：
   B → 在新的位置 1
   C → 在新的位置 2
   D → 在新的位置 0
   位置数组：[1, 2, 0]
3. 求最长递增子序列：[1, 2]（B 和 C 的相对顺序没变）
4. 不在 LIS 中的节点需要移动：D 需要移动
   → 只移动 D，B 和 C 不动
```

> **为什么用最长递增子序列？** 找出「不需要移动」的最大集合，让需要移动的节点最少。Vue 2 的双端 Diff 可能做更多不必要的移动。

### key 的反面案例

```html
<!-- ❌ 用 index 做 key -->
<div v-for="(item, index) in list" :key="index">
  <input v-model="item.text" />
</div>

<!-- 假设 list = [{text:'A'}, {text:'B'}, {text:'C'}] -->
<!-- 删除第一项后：list = [{text:'B'}, {text:'C'}] -->

<!-- 用 index 做 key 时：
  key=0: A → B（Diff 认为"同一个节点内容变了"，更新文本，但 input 的输入状态保留了 A 的值）
  key=1: B → C（同上）
  key=2: C → 没了（删除）
  结果：删的是最后一个，前面的 input 状态全乱了！
-->

<!-- ✅ 用唯一 id 做 key -->
<div v-for="item in list" :key="item.id">
  <input v-model="item.text" />
</div>
<!-- Diff 通过 id 识别：A 被删了，B 和 C 不变，input 状态正确 -->
```

### Vue 3 Diff 的完整流程总结

```
patch(旧VNode, 新VNode)
  ├── 类型不同 → 直接替换
  ├── 类型相同，是元素节点
  │   ├── 有 patchFlag → 按标记精准更新（只更新 TEXT/CLASS/STYLE 等）
  │   ├── 没有 patchFlag → 全量比较 props
  │   └── 有 dynamicChildren → 只 Diff 动态子节点（跳过静态）
  │       └── 没有 → 全量 Diff children
  └── 类型相同，是组件节点
      └── 比较 props → 需要更新则重新渲染子组件
```

---

## 八、组件通信（7 种方式）

### 1. props / emits（父子通信，最常用）

```html
<!-- 父组件 -->
<script setup>
import { ref } from 'vue'
import Child from './Child.vue'
const name = ref('张三')
function handleUpdate(newName) { name.value = newName }
</script>
<template>
  <Child :name="name" @update="handleUpdate" />
</template>

<!-- 子组件 Child.vue -->
<script setup>
const props = defineProps({ name: String })
const emit = defineEmits(['update'])
function changeName() {
  emit('update', '李四')
}
</script>
```

### 2. v-model（父子双向绑定，语法糖）

```html
<!-- 父组件 -->
<Child v-model="name" v-model:age="age" />

<!-- 等价于 -->
<Child
  :modelValue="name" @update:modelValue="name = $event"
  :age="age" @update:age="age = $event"
/>

<!-- 子组件 -->
<script setup>
const props = defineProps({ modelValue: String, age: Number })
const emit = defineEmits(['update:modelValue', 'update:age'])
function changeName() { emit('update:modelValue', '李四') }
function changeAge() { emit('update:age', 30) }
</script>
```

> **和 Vue 2 的区别**：Vue 2 只能一个 v-model（.sync 修饰符做额外的），Vue 3 可以多个 v-model。

### 3. provide / inject（跨层级通信）

```html
<!-- 祖先组件 -->
<script setup>
import { ref, provide } from 'vue'
const theme = ref('dark')
provide('theme', theme)         // 提供响应式数据
provide('changeTheme', (val) => { theme.value = val })  // 提供修改方法
</script>

<!-- 后代组件（中间可以隔很多层） -->
<script setup>
import { inject } from 'vue'
const theme = inject('theme')                // 注入
const changeTheme = inject('changeTheme')    // 注入修改方法
// theme 是 ref，修改 theme.value 会影响祖先组件
</script>
```

> **原理**：provide 把数据存在当前组件实例上，inject 沿着组件链往上找，找到第一个 provide 了这个 key 的祖先。和 Vue 2 一样，但 Vue 3 的 provide/inject 支持响应式。

### 4. $attrs（透传属性）

```html
<!-- 父组件 -->
<Child class="big" style="color:red" data-id="1" @click="handleClick" />

<!-- 子组件 -->
<script setup>
import { useAttrs } from 'vue'
const attrs = useAttrs()
// attrs = { class: 'big', style: { color: 'red' }, 'data-id': '1', onClick: handleClick }
// 没在 defineProps 中声明的属性和非 emits 声明的事件，都会出现在 attrs 里
</script>

<template>
  <!-- 默认 attrs 自动继承到根元素 -->
  <div>内容</div>
  <!-- 渲染结果：<div class="big" style="color:red" data-id="1">内容</div> -->

  <!-- 关闭自动继承，手动绑定到指定元素 -->
  <div>
    <input v-bind="attrs" />
  </div>
</template>
```

```html
<!-- 关闭自动继承 -->
<script setup>
defineOptions({ inheritAttrs: false })
</script>
```

> **和 Vue 2 的区别**：Vue 2 有 `$attrs`（属性）和 `$listeners`（事件）两个，Vue 3 合并成一个 `$attrs`，事件也在里面（以 `onXxx` 形式）。

### 5. expose / ref（父组件直接调用子组件方法）

```html
<!-- 子组件 -->
<script setup>
import { ref } from 'vue'
const count = ref(0)
function reset() { count.value = 0 }

// <script setup> 默认不暴露任何东西给父组件
// 必须用 defineExpose 显式暴露
defineExpose({ count, reset })
</script>

<!-- 父组件 -->
<script setup>
import { ref } from 'vue'
import Child from './Child.vue'
const childRef = ref(null)
function handleClick() {
  console.log(childRef.value.count)  // 访问子组件的 count
  childRef.value.reset()             // 调用子组件的 reset
}
</script>
<template>
  <Child ref="childRef" />
</template>
```

> **和 Vue 2 的区别**：Vue 2 通过 `this.$refs.child` 可以访问子组件所有东西。Vue 3 的 `<script setup>` 默认什么都不暴露，必须 defineExpose。更安全。

### 6. EventBus（mitt）

```js
// Vue 2：用 new Vue() 做 EventBus
// Vue 3：Vue 实例没有 $on/$off 了，用第三方库 mitt

import mitt from 'mitt'
const bus = mitt()

// 组件 A：发送
bus.emit('refresh', { id: 1 })

// 组件 B：监听
bus.on('refresh', (data) => { console.log(data) })

// 组件卸载时移除
import { onUnmounted } from 'vue'
onUnmounted(() => bus.off('refresh'))
```

### 7. Pinia（全局状态管理，第十五章详讲）

```js
// 任何组件都可以读写同一个 store
import { useCounterStore } from '@/stores/counter'
const store = useCounterStore()
store.count++
```

### 通信方式选择

| 场景 | 推荐方式 |
|---|---|
| 父 → 子 | props |
| 子 → 父 | emits |
| 父子双向 | v-model |
| 跨多层 | provide / inject |
| 透传属性 | $attrs |
| 父调用子方法 | expose / ref |
| 兄弟/任意组件 | mitt 或 Pinia |
| 全局共享状态 | Pinia |

---

## 九、插槽

### 默认插槽

```html
<!-- 子组件 MyButton.vue -->
<template>
  <button class="btn">
    <slot>默认文本</slot>   <!-- 父组件不传内容时显示"默认文本" -->
  </button>
</template>

<!-- 父组件 -->
<MyButton>提交订单</MyButton>
<!-- 渲染结果：<button class="btn">提交订单</button> -->

<MyButton />
<!-- 渲染结果：<button class="btn">默认文本</button> -->
```

### 具名插槽

```html
<!-- 子组件 Layout.vue -->
<template>
  <div class="layout">
    <header><slot name="header"></slot></header>
    <main><slot></slot></main>            <!-- 没有 name = 默认插槽 -->
    <footer><slot name="footer"></slot></footer>
  </div>
</template>

<!-- 父组件 -->
<Layout>
  <template #header>              <!-- #header 是 v-slot:header 的简写 -->
    <h1>页面标题</h1>
  </template>

  <p>主要内容</p>                  <!-- 没有 template 包裹的内容进默认插槽 -->

  <template #footer>
    <p>版权信息</p>
  </template>
</Layout>
```

### 作用域插槽

```html
<!-- 子组件 UserList.vue -->
<script setup>
const users = [{ name: '张三', age: 25 }, { name: '李四', age: 30 }]
</script>
<template>
  <ul>
    <li v-for="user in users" :key="user.name">
      <!-- 把子组件的数据通过 slot 传给父组件 -->
      <slot :user="user" :index="index"></slot>
    </li>
  </ul>
</template>

<!-- 父组件 -->
<UserList>
  <!-- 通过 v-slot 接收子组件传过来的数据 -->
  <template #default="{ user, index }">
    <span>{{ index }}. {{ user.name }} - {{ user.age }}岁</span>
  </template>
</UserList>
```

> **作用域插槽的本质**：子组件调用 slot 时传参，父组件通过 `v-slot="xxx"` 接收参数。编译后就是一个函数调用。

### 编译后的样子

```js
// 父组件传递插槽内容，编译后是一个函数：
_c(UserList, null, {
  default: ({ user, index }) => [
    _c('span', null, `${index}. ${user.name} - ${user.age}岁`)
  ],
})

// 子组件渲染 <slot> 时，调用这个函数并传入数据：
renderSlot(slots, 'default', { user, index })
// 等价于：slots.default({ user, index })
```

---

## 十、生命周期

### Vue 3 生命周期钩子

```html
<script setup>
import {
  onBeforeMount,
  onMounted,
  onBeforeUpdate,
  onUpdated,
  onBeforeUnmount,
  onUnmounted,
} from 'vue'

// setup 本身 = beforeCreate + created
// 所以没有 onBeforeCreate 和 onCreated

onBeforeMount(() => console.log('DOM 即将挂载'))
onMounted(() => console.log('DOM 挂载完成'))
onBeforeUpdate(() => console.log('DOM 即将更新'))
onUpdated(() => console.log('DOM 更新完成'))
onBeforeUnmount(() => console.log('组件即将卸载'))
onUnmounted(() => console.log('组件已卸载'))
</script>
```

### 对照表

| Vue 2（Options API） | Vue 3（Composition API） | 执行时机 |
|---|---|---|
| beforeCreate | setup() 本身 | 组件实例创建前 |
| created | setup() 本身 | 组件实例创建后 |
| beforeMount | onBeforeMount | DOM 挂载前 |
| mounted | onMounted | DOM 挂载后 |
| beforeUpdate | onBeforeUpdate | 响应式数据变了，DOM 更新前 |
| updated | onUpdated | DOM 更新后 |
| beforeDestroy | onBeforeUnmount | 组件卸载前 |
| destroyed | onUnmounted | 组件卸载后 |

> **命名变化**：destroy → unmount（更准确：组件是"卸载"不是"销毁"）

### 父子组件生命周期顺序

```
挂载阶段：
  父 setup → 父 onBeforeMount
    → 子 setup → 子 onBeforeMount → 子 onMounted
  → 父 onMounted

更新阶段（父组件数据变化导致子组件更新）：
  父 onBeforeUpdate
    → 子 onBeforeUpdate → 子 onUpdated
  → 父 onUpdated

卸载阶段：
  父 onBeforeUnmount
    → 子 onBeforeUnmount → 子 onUnmounted
  → 父 onUnmounted
```

> **记忆口诀**：父组件等子组件完成后才算完成。挂载是"父开始 → 子完成 → 父完成"，卸载同理。

### 常见场景

```html
<script setup>
import { onMounted, onUnmounted } from 'vue'

// 场景 1：挂载后操作 DOM（ECharts、地图等第三方库）
onMounted(() => {
  const chart = echarts.init(document.getElementById('chart'))
  chart.setOption({ ... })
})

// 场景 2：注册/清理全局事件
onMounted(() => {
  window.addEventListener('resize', handleResize)
})
onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})

// 场景 3：清理定时器
const timer = setInterval(() => { ... }, 1000)
onUnmounted(() => clearInterval(timer))
</script>
```

---

## 十一、Composables（组合式函数）

> Vue 3 最重要的复用模式。替代 Vue 2 的 Mixin，解决了 Mixin 的所有问题。

### Vue 2 Mixin 的问题

```js
// Vue 2 Mixin
const mousePositionMixin = {
  data() { return { x: 0, y: 0 } },
  mounted() { window.addEventListener('mousemove', this.update) },
  methods: { update(e) { this.x = e.pageX; this.y = e.pageY } },
}

// 问题 1：来源不明——组件里用了 this.x，不知道是自己的 data 还是哪个 mixin 的
// 问题 2：命名冲突——两个 mixin 都有 data.x，谁覆盖谁？
// 问题 3：隐式依赖——mixin 之间可能互相依赖，但看不出来
```

### Composable 的写法

```js
// composables/useMouse.js
import { ref, onMounted, onUnmounted } from 'vue'

export function useMouse() {
  const x = ref(0)
  const y = ref(0)

  function update(e) {
    x.value = e.pageX
    y.value = e.pageY
  }

  onMounted(() => window.addEventListener('mousemove', update))
  onUnmounted(() => window.removeEventListener('mousemove', update))

  return { x, y }  // 明确返回什么
}
```

```html
<!-- 使用 -->
<script setup>
import { useMouse } from '@/composables/useMouse'

const { x, y } = useMouse()  // 来源一目了然
// 不会和组件自己的数据冲突（解构时可以重命名）
</script>

<template>
  <p>鼠标位置：{{ x }}, {{ y }}</p>
</template>
```

### 实际案例：useFetch

```js
// composables/useFetch.js
import { ref, watchEffect, toValue } from 'vue'

export function useFetch(url) {
  const data = ref(null)
  const error = ref(null)
  const loading = ref(false)

  watchEffect(async () => {
    loading.value = true
    error.value = null
    try {
      const res = await fetch(toValue(url))  // toValue：如果 url 是 ref 就取 .value，不是就直接用
      data.value = await res.json()
    } catch (e) {
      error.value = e
    } finally {
      loading.value = false
    }
  })

  return { data, error, loading }
}
```

```html
<script setup>
import { useFetch } from '@/composables/useFetch'

// url 可以是字符串，也可以是 ref（url 变了会自动重新请求）
const { data, error, loading } = useFetch('/api/users')
</script>

<template>
  <p v-if="loading">加载中...</p>
  <p v-else-if="error">{{ error.message }}</p>
  <ul v-else>
    <li v-for="user in data" :key="user.id">{{ user.name }}</li>
  </ul>
</template>
```

### Composable vs Mixin

| | Mixin | Composable |
|---|---|---|
| 数据来源 | 不明确（this.x 不知道从哪来） | 明确（const { x } = useMouse()） |
| 命名冲突 | 有（多个 mixin 同名属性会覆盖） | 无（解构时可重命名） |
| 类型推导 | ❌ TypeScript 无法推导 | ✅ 完美支持 |
| 复用粒度 | 整个选项合并 | 只取需要的返回值 |
| 逻辑组合 | 难（mixin 之间互相依赖不透明） | 易（composable 可以互相调用） |

> **约定**：composable 函数以 `use` 开头，放在 `composables/` 目录。

---

## 十二、新内置组件

### Teleport（传送门）

```html
<!-- 问题：模态框写在组件里，但需要渲染到 body 下（避免被父元素 overflow:hidden 裁剪） -->

<script setup>
import { ref } from 'vue'
const show = ref(false)
</script>

<template>
  <button @click="show = true">打开弹窗</button>

  <!-- to：传送到哪个 DOM 元素 -->
  <Teleport to="body">
    <div v-if="show" class="modal">
      <p>我是弹窗，但我渲染在 body 下</p>
      <button @click="show = false">关闭</button>
    </div>
  </Teleport>
</template>

<!-- 
  组件树：App → Page → Modal（逻辑上 Modal 是 Page 的子组件）
  DOM 树：body → div#app → ... 和 body → div.modal（DOM 上 Modal 在 body 下）
  组件关系没变，只是 DOM 位置变了
-->
```

> **原理**：patch 时发现是 Teleport 类型的 VNode，不把子节点插入父元素，而是插入 `to` 指定的目标元素。

### Fragment（多根节点）

```html
<!-- Vue 2：组件必须有且只有一个根元素 -->
<template>
  <div>   <!-- 被迫加一层 div 包裹 -->
    <h1>标题</h1>
    <p>内容</p>
  </div>
</template>

<!-- Vue 3：组件可以有多个根元素 -->
<template>
  <h1>标题</h1>
  <p>内容</p>
</template>
<!-- 编译后用 Fragment（虚拟节点）包裹，不会生成多余的 DOM 元素 -->
```

### Suspense（异步组件加载）

```html
<script setup>
import { defineAsyncComponent } from 'vue'

// 异步组件：需要时才加载（代码分割）
const AsyncUserProfile = defineAsyncComponent(() =>
  import('./UserProfile.vue')
)
</script>

<template>
  <Suspense>
    <!-- 异步组件加载完成后显示 -->
    <template #default>
      <AsyncUserProfile />
    </template>

    <!-- 加载中显示的占位内容 -->
    <template #fallback>
      <p>加载中...</p>
    </template>
  </Suspense>
</template>
```

> **Suspense 还能配合 async setup 使用**：如果子组件的 setup 是 async 函数（返回 Promise），Suspense 会等它 resolve 后再渲染。

### Transition（过渡动画）

```html
<script setup>
import { ref } from 'vue'
const show = ref(true)
</script>

<template>
  <button @click="show = !show">切换</button>
  <Transition name="fade">
    <p v-if="show">这段文字有淡入淡出效果</p>
  </Transition>
</template>

<style>
/* Vue 自动在进入/离开时添加以下 class */
.fade-enter-from { opacity: 0; }          /* 进入前 */
.fade-enter-active { transition: opacity 0.3s; }  /* 进入过程 */
.fade-enter-to { opacity: 1; }            /* 进入后 */

.fade-leave-from { opacity: 1; }          /* 离开前 */
.fade-leave-active { transition: opacity 0.3s; }  /* 离开过程 */
.fade-leave-to { opacity: 0; }            /* 离开后 */
</style>
```

```html
<!-- 列表过渡用 TransitionGroup -->
<TransitionGroup name="list" tag="ul">
  <li v-for="item in list" :key="item.id">{{ item.name }}</li>
</TransitionGroup>
```

---

## 十三、自定义指令

### 用法

```html
<script setup>
// 在 <script setup> 中，以 v 开头的变量自动注册为指令
const vFocus = {
  mounted(el) {
    el.focus()  // 元素挂载后自动聚焦
  },
}

const vClickOutside = {
  mounted(el, binding) {
    el._clickOutside = (e) => {
      if (!el.contains(e.target)) {
        binding.value()  // 点击外部时调用绑定的函数
      }
    }
    document.addEventListener('click', el._clickOutside)
  },
  unmounted(el) {
    document.removeEventListener('click', el._clickOutside)
  },
}
</script>

<template>
  <input v-focus />
  <div v-click-outside="closeMenu">菜单内容</div>
</template>
```

### 钩子函数（和组件生命周期对齐）

| Vue 2 指令钩子 | Vue 3 指令钩子 | 说明 |
|---|---|---|
| bind | **mounted** | 元素挂载后 |
| inserted | - | 移除了 |
| update | **updated** | 组件更新后 |
| componentUpdated | - | 移除了 |
| unbind | **unmounted** | 元素卸载后 |
| - | **beforeMount** | 新增 |
| - | **beforeUpdate** | 新增 |
| - | **beforeUnmount** | 新增 |

> **Vue 3 的改进**：指令钩子名称和组件生命周期完全一致，不用再记两套名字。

### 钩子参数

```js
const vMyDirective = {
  mounted(el, binding, vnode) {
    // el：指令绑定的 DOM 元素
    // binding.value：v-my-directive="value" 中的 value
    // binding.oldValue：更新前的值（只在 updated 中可用）
    // binding.arg：v-my-directive:arg 中的 arg
    // binding.modifiers：v-my-directive.lazy 中的 { lazy: true }
    // vnode：虚拟节点
  },
}
```

### 全局注册

```js
// main.js
const app = createApp(App)
app.directive('focus', {
  mounted(el) { el.focus() },
})
```

---

## 十四、Vue Router 4

### 基本用法

```js
// router/index.js
import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),  // Vue 2 是 mode: 'history'
  routes: [
    { path: '/', component: () => import('@/views/Home.vue') },
    { path: '/user/:id', component: () => import('@/views/User.vue'), props: true },
    { path: '/:pathMatch(.*)*', component: () => import('@/views/404.vue') },  // 404
  ],
})

export default router
```

```js
// main.js
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

createApp(App).use(router).mount('#app')
```

### 在组件中使用

```html
<script setup>
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()    // 当前路由信息（等价于 Vue 2 的 this.$route）
const router = useRouter()  // 路由实例（等价于 Vue 2 的 this.$router）

console.log(route.params.id)  // 路由参数
console.log(route.query.page) // 查询参数

function goHome() {
  router.push('/')
}
function goBack() {
  router.back()
}
</script>

<template>
  <router-link to="/">首页</router-link>
  <router-link :to="{ name: 'user', params: { id: 1 } }">用户</router-link>
  <router-view />
</template>
```

### 路由守卫

```js
// 全局守卫
router.beforeEach((to, from) => {
  // Vue 2 需要写 next()，Vue 3 不需要了
  // 返回 false 取消导航
  // 返回路由地址重定向
  // 不返回或返回 true 放行

  if (to.meta.requiresAuth && !isLoggedIn()) {
    return { path: '/login' }  // 重定向到登录页
  }
  // 不写 return = 放行
})

// 路由独享守卫
{
  path: '/admin',
  component: Admin,
  beforeEnter: (to, from) => {
    if (!isAdmin()) return false
  },
}

// 组件内守卫
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

onBeforeRouteLeave((to, from) => {
  if (hasUnsavedChanges()) {
    return confirm('有未保存的更改，确认离开？')
  }
})

onBeforeRouteUpdate((to, from) => {
  // 路由参数变化时触发（如 /user/1 → /user/2）
  fetchUser(to.params.id)
})
```

### 和 Vue Router 3 的区别

| | Vue Router 3（Vue 2） | Vue Router 4（Vue 3） |
|---|---|---|
| 创建 | `new VueRouter({ mode: 'history' })` | `createRouter({ history: createWebHistory() })` |
| 注册 | `Vue.use(VueRouter)` | `app.use(router)` |
| 组件内访问 | `this.$route` / `this.$router` | `useRoute()` / `useRouter()` |
| 守卫 next | 必须调用 `next()` | 不需要，用返回值控制 |
| 404 | `{ path: '*' }` | `{ path: '/:pathMatch(.*)*' }` |

---

## 十五、Pinia

> Vue 3 官方推荐的状态管理库，替代 Vuex。

### 为什么不用 Vuex 了

| | Vuex | Pinia |
|---|---|---|
| mutations | 必须写 mutations 才能改 state | **没有 mutations**，直接改 |
| TypeScript | 支持差 | 完美支持 |
| 模块化 | 需要 modules + namespaced | 每个 store 独立，天然模块化 |
| 体积 | ~1KB | ~1KB |
| devtools | 支持 | 支持 |

### 定义 Store

```js
// stores/counter.js
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

// 方式 1：Composition API 风格（推荐）
export const useCounterStore = defineStore('counter', () => {
  // state → ref
  const count = ref(0)

  // getters → computed
  const double = computed(() => count.value * 2)

  // actions → 普通函数
  function increment() {
    count.value++
  }
  async function fetchCount() {
    const res = await fetch('/api/count')
    count.value = await res.json()
  }

  return { count, double, increment, fetchCount }
})

// 方式 2：Options API 风格
export const useCounterStore2 = defineStore('counter', {
  state: () => ({ count: 0 }),
  getters: { double: (state) => state.count * 2 },
  actions: {
    increment() { this.count++ },
  },
})
```

### 在组件中使用

```html
<script setup>
import { useCounterStore } from '@/stores/counter'
import { storeToRefs } from 'pinia'

const store = useCounterStore()

// ❌ 直接解构会丢失响应性（和 reactive 一样的问题）
const { count, double } = store

// ✅ 用 storeToRefs 解构 state 和 getters
const { count, double } = storeToRefs(store)

// actions 可以直接解构（它们是普通函数）
const { increment } = store
</script>

<template>
  <p>{{ count }} × 2 = {{ double }}</p>
  <button @click="increment">+1</button>
  <button @click="store.fetchCount()">从接口获取</button>
</template>
```

### 修改 state 的几种方式

```js
const store = useCounterStore()

// 方式 1：直接改（最简单）
store.count++

// 方式 2：$patch 批量改（一次触发一次更新）
store.$patch({
  count: store.count + 1,
  // name: '张三',  // 可以同时改多个
})

// 方式 3：$patch 函数形式（适合修改数组等复杂操作）
store.$patch((state) => {
  state.count++
  state.items.push({ name: '新项目' })
})

// 方式 4：$reset 重置为初始值（只有 Options API 风格的 store 支持）
store.$reset()
```

### Store 之间互相调用

```js
// stores/user.js
import { defineStore } from 'pinia'
import { useCounterStore } from './counter'

export const useUserStore = defineStore('user', () => {
  function doSomething() {
    const counterStore = useCounterStore()  // 直接调用另一个 store
    counterStore.increment()
  }
  return { doSomething }
})
```

### 原理：Pinia 的本质

```js
// 简化版 defineStore
function defineStore(id, setup) {
  function useStore() {
    // 1. 创建一个 reactive 对象存储 state
    // 2. 执行 setup 函数，收集返回的 ref/computed/function
    // 3. 把它们都放到 reactive 对象上
    // 4. 每个组件调用 useStore() 拿到的是同一个 reactive 对象（单例）

    const store = reactive(setup())
    return store
  }
  return useStore
}

// 所以 Pinia 的本质：
// state = ref（响应式）
// getters = computed（缓存）
// actions = 普通函数
// store = 一个 reactive 单例对象
// 没有什么黑魔法，就是 Vue 3 响应式 API 的组合
```

---

## 十六、nextTick 与异步更新

### 用法

```html
<script setup>
import { ref, nextTick } from 'vue'

const count = ref(0)

async function increment() {
  count.value++
  // DOM 还没更新！Vue 的 DOM 更新是异步的
  console.log(document.querySelector('#count').textContent) // 旧值

  await nextTick()
  // DOM 更新完了
  console.log(document.querySelector('#count').textContent) // 新值
}
</script>

<template>
  <span id="count">{{ count }}</span>
</template>
```

### 原理：和 Vue 2 一样的批量更新

```js
count.value = 1   → trigger → 渲染 effect 加入调度队列
count.value = 2   → trigger → 已在队列，跳过（去重）
name.value = 'x'  → trigger → 渲染 effect 加入调度队列

// 同步代码执行完后，在微任务中批量执行队列
// 所以多次修改只触发一次 DOM 更新

// nextTick 就是 Promise.resolve().then(callback)
// 确保在 DOM 更新的微任务之后执行
```

```js
// Vue 3 的 nextTick 实现极简
export function nextTick(fn) {
  return fn ? Promise.resolve().then(fn) : Promise.resolve()
}
// 就是一个 Promise.resolve()，利用微任务队列确保在 DOM 更新后执行
```

> **和 Vue 2 的区别**：Vue 2 的 nextTick 有降级策略（Promise → MutationObserver → setImmediate → setTimeout），Vue 3 直接用 Promise.resolve()，不再兼容不支持 Promise 的浏览器。

---

## 十七、性能优化实战

### keep-alive

```html
<!-- 缓存组件，避免重复创建/销毁 -->
<script setup>
import { ref } from 'vue'
const currentTab = ref('Home')
</script>

<template>
  <button @click="currentTab = 'Home'">首页</button>
  <button @click="currentTab = 'Profile'">个人中心</button>

  <KeepAlive :include="['Home', 'Profile']" :max="5">
    <component :is="currentTab" />
  </KeepAlive>
</template>
```

```html
<!-- 被缓存的组件用 onActivated / onDeactivated 代替 onMounted / onUnmounted -->
<script setup>
import { onActivated, onDeactivated } from 'vue'

onActivated(() => {
  // 每次从缓存中恢复时执行（刷新数据等）
  fetchLatestData()
})
onDeactivated(() => {
  // 每次被缓存时执行（暂停定时器等）
})
</script>
```

> **原理和 Vue 2 一样**：LRU 缓存 + VNode 复用。max 超过时淘汰最久没访问的组件。

### 异步组件（代码分割）

```js
import { defineAsyncComponent } from 'vue'

// 基本用法：按需加载
const HeavyChart = defineAsyncComponent(() =>
  import('./HeavyChart.vue')
)

// 完整用法：带加载/错误/延迟/超时
const HeavyChart = defineAsyncComponent({
  loader: () => import('./HeavyChart.vue'),
  loadingComponent: LoadingSpinner,   // 加载中显示
  errorComponent: ErrorDisplay,       // 加载失败显示
  delay: 200,                         // 200ms 后才显示 loading（避免闪烁）
  timeout: 10000,                     // 10 秒超时
})
```

### shallowRef / shallowReactive（大数据优化）

```js
import { shallowRef, shallowReactive } from 'vue'

// 普通 ref：深层响应式（对象内部的每一层都是响应式的）
const data = ref({ a: { b: { c: 1 } } })
data.value.a.b.c = 2  // ✅ 触发更新

// shallowRef：只有 .value 的赋值是响应式的
const data = shallowRef({ a: { b: { c: 1 } } })
data.value.a.b.c = 2  // ❌ 不触发更新
data.value = { a: { b: { c: 2 } } }  // ✅ 整体替换才触发

// 适用场景：大列表、大对象（几千个属性），不需要深层响应式
// 用 shallowRef 避免 Proxy 递归代理所有属性的开销
```

### 性能优化清单

| 优化手段 | 适用场景 |
|---|---|
| `v-show` 代替 `v-if` | 频繁切换显隐 |
| `v-for` 加 `:key` | 列表渲染 |
| `v-once` | 只渲染一次的静态内容 |
| `v-memo` | 列表中部分元素不需要更新 |
| `computed` 代替方法 | 需要缓存的派生数据 |
| `shallowRef/shallowReactive` | 大数据对象 |
| `defineAsyncComponent` | 大组件按需加载 |
| `KeepAlive` | 频繁切换的页面/tab |
| `虚拟列表` | 超长列表（几千条） |

---

## 十八、TypeScript 集成

### defineProps 类型声明

```html
<script setup lang="ts">
// 方式 1：运行时声明
const props = defineProps({
  name: String,
  age: { type: Number, required: true },
  tags: { type: Array as PropType<string[]>, default: () => [] },
})

// 方式 2：类型声明（推荐，更简洁）
const props = defineProps<{
  name: string
  age: number
  tags?: string[]
}>()

// 方式 2 + 默认值
const props = withDefaults(defineProps<{
  name: string
  age?: number
  tags?: string[]
}>(), {
  age: 18,
  tags: () => [],
})
</script>
```

### defineEmits 类型声明

```html
<script setup lang="ts">
const emit = defineEmits<{
  (e: 'update', name: string): void
  (e: 'delete', id: number): void
}>()

// 3.3+ 简写语法
const emit = defineEmits<{
  update: [name: string]
  delete: [id: number]
}>()
</script>
```

### ref 类型

```ts
import { ref, reactive } from 'vue'

// 自动推导
const count = ref(0)          // Ref<number>
const name = ref('张三')       // Ref<string>

// 手动指定（复杂类型）
interface User {
  name: string
  age: number
}
const user = ref<User | null>(null)
user.value = { name: '张三', age: 25 }

// reactive
const state = reactive<{ count: number; users: User[] }>({
  count: 0,
  users: [],
})
```

### 模板 ref 类型

```html
<script setup lang="ts">
import { ref, onMounted } from 'vue'

// DOM 元素 ref
const inputRef = ref<HTMLInputElement | null>(null)
onMounted(() => {
  inputRef.value?.focus()
})

// 组件 ref
import type { ComponentExposed } from 'vue'
import MyComponent from './MyComponent.vue'
const compRef = ref<InstanceType<typeof MyComponent> | null>(null)
</script>

<template>
  <input ref="inputRef" />
  <MyComponent ref="compRef" />
</template>
```

---

## 十九、总结与面试高频题

### Vue 2 vs Vue 3 差异速查表

| 特性 | Vue 2 | Vue 3 |
|---|---|---|
| 响应式 | Object.defineProperty | Proxy |
| API 风格 | Options API | Composition API + `<script setup>` |
| 根节点 | 必须单根 | 支持多根（Fragment） |
| 生命周期 | beforeDestroy / destroyed | onBeforeUnmount / onUnmounted |
| 事件总线 | new Vue() 的 $on/$off | mitt（第三方） |
| 全局 API | Vue.xxx | app.xxx（createApp） |
| v-model | 只能一个 + .sync | 支持多个 v-model |
| 复用模式 | Mixin | Composables（useXxx） |
| 路由 | Vue Router 3 | Vue Router 4 |
| 状态管理 | Vuex | Pinia |
| 编译优化 | 无 | PatchFlags + 静态提升 + Block Tree |
| Diff 算法 | 双端比较 | 快速 Diff（最长递增子序列） |
| TS 支持 | 差 | 好 |
| IE 支持 | ✅ IE9+ | ❌ 不支持 |

### 面试高频题

**Q：Vue 3 的 Proxy 比 Vue 2 的 defineProperty 好在哪？**
A：能检测新增/删除属性、数组索引修改；懒代理（用到才代理，性能更好）；不需要 $set/$delete。代价是不支持 IE。

**Q：ref 和 reactive 的区别？什么时候用哪个？**
A：ref 包装任意类型（基本类型用 .value），reactive 包装对象（不需要 .value）。推荐统一用 ref，因为 reactive 有解构丢失响应性和不能整体替换的坑。

**Q：Vue 3 的编译优化做了什么？**
A：四个优化——PatchFlags（标记动态内容类型，精准 Diff）、静态提升（静态节点只创建一次）、Block Tree（只 Diff 动态节点集合）、事件缓存（事件函数不重复创建）。

**Q：Composition API 比 Options API 好在哪？**
A：按功能组织代码（不再按选项分散）、更好的类型推导、更好的复用（composables 替代 mixin）、更好的 tree-shaking。

**Q：Pinia 和 Vuex 的区别？**
A：去掉了 mutations（直接改 state）、天然模块化（每个 store 独立文件）、完美 TS 支持、更简洁的 API。

**Q：watchEffect 和 watch 的区别？**
A：watchEffect 自动收集依赖 + 立即执行，watch 手动指定数据源 + 能拿到新旧值。

**Q：`<script setup>` 是什么？**
A：Composition API 的编译时语法糖。编译器自动生成 setup 函数和 return，defineProps/defineEmits 是编译器宏不是运行时函数。

---

> **Vue 3 的核心原理：Proxy 响应式 + Composition API + 编译时优化（PatchFlags/静态提升/Block Tree）+ 快速 Diff**。理解了这四个核心，Vue 3 的所有 API 都能从原理推导出来。

### Vue 3 全家桶

| 库 | 作用 | 安装 |
|---|---|---|
| Vue | 核心框架 | `vue@3` |
| Vue Router | 路由 | `vue-router@4` |
| Pinia | 状态管理 | `pinia` |
| Axios | HTTP 请求 | `axios` |
| Element Plus | UI 组件库 PC | `element-plus` |
| Vant | UI 组件库 H5 | `vant@4` |
| VueUse | 工具函数集合 | `@vueuse/core` |

> **注意版本号：Vue 3 对应 Vue Router 4 和 Pinia（不是 Vuex），Element Plus（不是 Element UI），Vant 4（不是 Vant 2）**
