# TypeScript 精讲（前端实战版）

> 你已经会写 JS，也用过一些 TS。这份文档不讲入门知识，而是**系统补全盲区、搞清楚原理**。看完能写出类型安全的 Vue/React 项目，面试不被问倒。

---

## 一、TS 是什么 + 为什么用

### 本质：带类型的 JavaScript

```ts
// JS：运行时才知道类型错了
function add(a, b) { return a + b }
add(1, '2')   // 运行结果：'12'，不是 3。没有报错！

// TS：编译期就知道类型错了
function add(a: number, b: number): number { return a + b }
add(1, '2')   // ❌ 编译错误：Argument of type 'string' is not assignable to parameter of type 'number'
```

### 类型系统的价值

```
1. 编译期报错：把运行时的 bug 提前到写代码时发现
2. 智能提示：IDE 知道变量的类型，能准确给出提示和自动补全
3. 代码即文档：函数签名本身就是文档，不用单独写注释说明参数类型
4. 重构安全：改了一个类型定义，所有用到的地方会自动标红
```

### 编译期 vs 运行时

```ts
// TS 的类型只存在于编译期，编译成 JS 后类型信息全部消失

// TS 源码
const user: { name: string; age: number } = { name: '张三', age: 25 }

// 编译后的 JS
const user = { name: '张三', age: 25 }
// 类型标注被完全擦除，运行时没有类型

// 这意味着：
// ✅ 类型错误可以在编译期报错
// ❌ 运行时无法通过 TS 类型做参数校验（那是 zod/yup 等运行时校验库的事）
```

---

## 二、基础类型系统

### 原始类型

```ts
// 和 JS 的类型一一对应，首字母小写
let name: string = '张三'
let age: number = 25
let isVip: boolean = true
let nothing: null = null
let undef: undefined = undefined
let sym: symbol = Symbol('id')
let big: bigint = 9007199254740991n

// 大写的 String/Number/Boolean 是包装对象类型，不要用！
let badStr: String = '张三'   // ❌ 别这么写
let goodStr: string = '张三'  // ✅
```

### 类型推断（能推断的不用写）

```ts
// TS 能根据赋值自动推断类型，不需要手动标注
let name = '张三'      // 推断为 string
let age = 25           // 推断为 number
let flag = true        // 推断为 boolean

const arr = [1, 2, 3]  // 推断为 number[]
const obj = { x: 1, y: '2' }  // 推断为 { x: number; y: string }

// 函数返回值也能推断
function add(a: number, b: number) {
  return a + b   // 返回值推断为 number，不用写 : number
}

// 原则：能推断的不写，推断不了的才手动标注
```

### 联合类型（Union）

```ts
// 可以是多种类型之一
let value: string | number = '张三'
value = 25   // ✅ 也可以是 number

// 最常用场景：可以为 null 的值
function getUser(id: number): User | null {
  // 找不到时返回 null
}

// 字面量联合类型（更精确，比 string 强多了）
type Direction = 'left' | 'right' | 'up' | 'down'
type Status = 'pending' | 'success' | 'error'
type Size = 'sm' | 'md' | 'lg'

let dir: Direction = 'left'   // ✅
dir = 'center'                // ❌ 编译报错：不在联合类型里
```

### 交叉类型（Intersection）

```ts
// 同时满足多个类型（合并类型），用 &
type User = { name: string; age: number }
type Admin = { role: string; permissions: string[] }

type AdminUser = User & Admin
// 等价于：{ name: string; age: number; role: string; permissions: string[] }

const adminUser: AdminUser = {
  name: '张三',
  age: 25,
  role: 'admin',
  permissions: ['read', 'write']
}
```

### 数组和元组

```ts
// 数组：所有元素同一类型
const names: string[] = ['张三', '李四']
const ids: number[] = [1, 2, 3]
const mixed: (string | number)[] = ['a', 1, 'b', 2]  // 联合类型数组

// 另一种写法（不推荐）
const names2: Array<string> = ['张三', '李四']

// 元组：固定长度、固定类型的数组
const point: [number, number] = [10, 20]
const entry: [string, number] = ['age', 25]

// 常见用途：函数返回多个值（类似 useState 的返回值）
function useToggle(init: boolean): [boolean, () => void] {
  let state = init
  const toggle = () => { state = !state }
  return [state, toggle]
}
const [isOpen, toggleOpen] = useToggle(false)
```

### any、unknown、never

```ts
// any：关闭类型检查，能做任何操作（尽量避免！）
let val: any = '张三'
val = 25           // ✅ 任意赋值
val.foo.bar.baz()  // ✅ 不报错，但运行时可能崩

// unknown：类型安全的 any。赋值随意，但使用前必须做类型收窄
let safeVal: unknown = '张三'
safeVal.length     // ❌ 不知道是什么类型，不能直接访问属性
if (typeof safeVal === 'string') {
  safeVal.length   // ✅ 收窄为 string 后才能访问
}

// never：永远不会出现的类型（函数抛出异常、死循环）
function throwError(msg: string): never {
  throw new Error(msg)   // 永远不会正常返回
}
```

> **最佳实践**：`any` 只在迫不得已时用（如第三方库没有类型定义）。接收外部不确定数据用 `unknown`，用前做类型收窄。

---

## 三、interface vs type

> 这是 TS 最常被问到的问题。先说结论：**大部分场景都可以互换，但各有适合的场景。**

### 相似点

```ts
// 定义对象类型，两者写法几乎一样
interface User {
  name: string
  age: number
  email?: string  // 可选属性
}

type User = {
  name: string
  age: number
  email?: string
}

// 都能用泛型
interface Response<T> { data: T; code: number }
type Response<T> = { data: T; code: number }
```

### 关键区别

```ts
// 区别 1：扩展语法不同
// interface 用 extends
interface Animal { name: string }
interface Dog extends Animal { breed: string }

// type 用 &（交叉类型）
type Animal = { name: string }
type Dog = Animal & { breed: string }

// 区别 2：interface 可以声明合并，type 不行
interface User { name: string }
interface User { age: number }   // ✅ 自动合并为 { name: string; age: number }

type User = { name: string }
type User = { age: number }      // ❌ 报错：标识符重复

// 区别 3：type 可以定义任意类型，interface 只能定义对象类型
type ID = string | number       // ✅ type 可以是联合类型
type Callback = () => void      // ✅ type 可以是函数
// interface 不能这样写
```

### 如何选择

```ts
// 推荐原则：
// 用 interface：定义对象结构（组件 Props、API 响应、实体类）
interface UserProps {
  name: string
  onClick: () => void
}

// 用 type：联合类型、交叉类型、函数类型、工具类型
type Status = 'active' | 'inactive'
type Handler = (e: Event) => void
type AdminUser = User & Admin

// 实际项目中：统一用一种就行，不要混着来
```

---

## 四、函数类型

### 基本写法

```ts
// 参数类型 + 返回值类型
function greet(name: string, age: number): string {
  return `你好，${name}，${age}岁`
}

// 箭头函数
const greet = (name: string, age: number): string => `你好，${name}，${age}岁`

// 可选参数（必须放在必填参数后面）
function log(msg: string, level?: 'info' | 'warn' | 'error'): void {
  console[level ?? 'info'](msg)
}

// 默认参数（和 JS 完全一样，有默认值就不用标注类型）
function createUser(name: string, role = 'user') {
  return { name, role }  // role 推断为 string
}

// 剩余参数
function sum(...nums: number[]): number {
  return nums.reduce((a, b) => a + b, 0)
}
```

### 函数类型定义

```ts
// 用 type 定义函数签名
type Formatter = (value: string) => string
type EventHandler = (event: MouseEvent) => void
type Comparator<T> = (a: T, b: T) => number

// 作为参数传入（高阶函数）
function process(data: string[], formatter: Formatter): string[] {
  return data.map(formatter)
}

// 函数重载：同一函数根据参数类型返回不同类型
function format(value: string): string
function format(value: number): string
function format(value: string | number): string {
  return String(value)
}
```

### 泛型函数

```ts
// 不用 any，用泛型保持类型信息
// ❌ 用 any：返回值类型信息丢失
function first(arr: any[]): any { return arr[0] }
const result = first([1, 2, 3])  // result 类型是 any

// ✅ 用泛型：类型信息保留
function first<T>(arr: T[]): T | undefined { return arr[0] }
const num = first([1, 2, 3])        // num 推断为 number | undefined
const str = first(['a', 'b', 'c'])  // str 推断为 string | undefined
```

---

## 五、泛型——TS 的核心

> 泛型 = 类型的"参数"。写一个函数/接口/类，能适配多种类型，同时保持类型安全。

### 为什么需要泛型

```ts
// 场景：封装一个通用的 API 响应类型
// ❌ 不用泛型：每种响应都要写一遍
interface UserResponse { data: User; code: number; message: string }
interface OrderResponse { data: Order; code: number; message: string }
interface ListResponse { data: Product[]; code: number; message: string }

// ✅ 用泛型：一个类型搞定所有
interface ApiResponse<T> {
  data: T
  code: number
  message: string
}

type UserResponse = ApiResponse<User>
type OrderResponse = ApiResponse<Order>
type ListResponse = ApiResponse<Product[]>
```

### 泛型约束（extends）

```ts
// 约束泛型必须满足某个条件
function getLength<T extends { length: number }>(arr: T): number {
  return arr.length  // 因为约束了有 length 属性，所以可以访问
}
getLength([1, 2, 3])   // ✅ 数组有 length
getLength('hello')     // ✅ 字符串有 length
getLength(123)         // ❌ 数字没有 length

// 约束 key 必须是对象的属性名
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key]
}
const user = { name: '张三', age: 25 }
getProperty(user, 'name')  // ✅ 返回 string
getProperty(user, 'age')   // ✅ 返回 number
getProperty(user, 'email') // ❌ 'email' 不在 user 的属性里
```

### 内置工具泛型（最实用的部分）

```ts
interface User {
  id: number
  name: string
  email: string
  password: string
  age: number
}

// Partial<T>：所有属性变可选（更新时常用）
type UserUpdate = Partial<User>
// { id?: number; name?: string; email?: string; ... }

// Required<T>：所有属性变必填（和 Partial 相反）
type UserRequired = Required<UserUpdate>

// Readonly<T>：所有属性变只读
type UserReadonly = Readonly<User>
const u: UserReadonly = { id: 1, name: '张三', email: 'a@b.com', password: '123', age: 25 }
u.name = '李四'  // ❌ 只读，不能修改

// Pick<T, K>：只保留指定属性（最常用）
type UserProfile = Pick<User, 'id' | 'name' | 'email'>
// { id: number; name: string; email: string }

// Omit<T, K>：去掉指定属性（最常用）
type PublicUser = Omit<User, 'password'>
// { id: number; name: string; email: string; age: number }
// 这就是接口返回给前端的"安全用户信息"（不含密码）

// Record<K, V>：键值对类型
type RoleMap = Record<string, string[]>
// { [key: string]: string[] }
const roles: RoleMap = { admin: ['read', 'write'], user: ['read'] }

// ReturnType<T>：获取函数返回值的类型
function getUser() { return { id: 1, name: '张三' } }
type UserReturn = ReturnType<typeof getUser>
// { id: number; name: string }
```

> **日常最常用的 4 个**：`Partial`（更新对象）、`Omit`（去掉敏感字段）、`Pick`（只取需要的字段）、`Record`（键值对 Map）。

---

## 六、类型收窄

> 类型收窄 = 在代码执行过程中，从宽泛的类型收窄到更具体的类型。这是写出健壮代码的关键。

### typeof 收窄

```ts
function format(value: string | number): string {
  if (typeof value === 'string') {
    return value.toUpperCase()  // 这里 value 是 string
  }
  return value.toFixed(2)       // 这里 value 是 number
}
```

### instanceof 收窄

```ts
function handleError(error: Error | string) {
  if (error instanceof Error) {
    console.error(error.message)  // 这里是 Error 类型
  } else {
    console.error(error)          // 这里是 string 类型
  }
}
```

### in 操作符收窄

```ts
interface Cat { meow(): void }
interface Dog { bark(): void }

function makeSound(animal: Cat | Dog) {
  if ('meow' in animal) {
    animal.meow()   // 这里是 Cat
  } else {
    animal.bark()   // 这里是 Dog
  }
}
```

### 类型谓词（自定义类型守卫）

```ts
// 返回类型写 "参数 is 类型"，告诉 TS 函数返回 true 时参数是什么类型
function isString(value: unknown): value is string {
  return typeof value === 'string'
}

function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'name' in obj
}

// 使用
function process(value: unknown) {
  if (isString(value)) {
    value.toUpperCase()  // ✅ TS 知道这里 value 是 string
  }
  if (isUser(value)) {
    value.name           // ✅ TS 知道这里 value 是 User
  }
}
```

### never 穷举检查

```ts
// never 的妙用：确保 switch 覆盖了所有情况
type Shape = 'circle' | 'square' | 'triangle'

function getArea(shape: Shape): number {
  switch (shape) {
    case 'circle': return Math.PI * 5 * 5
    case 'square': return 10 * 10
    case 'triangle': return 0.5 * 10 * 8
    default:
      // 如果 Shape 新增了类型但 switch 没处理，这里会报错
      const _exhaustive: never = shape
      throw new Error(`未处理的形状: ${shape}`)
  }
}
// 好处：以后给 Shape 加了 'hexagon'，这里立刻报红，不会遗漏
```

---

## 七、高级类型

### 条件类型

```ts
// 语法：T extends U ? X : Y
// 如果 T 能赋值给 U，类型是 X，否则是 Y
type IsString<T> = T extends string ? true : false

type A = IsString<string>   // true
type B = IsString<number>   // false

// 实用场景：获取数组的元素类型
type ElementType<T> = T extends (infer E)[] ? E : never
type StrElem = ElementType<string[]>   // string
type NumElem = ElementType<number[]>   // number
```

### infer——类型推断

```ts
// infer = 在条件类型中"提取"某个类型
// 获取函数返回值类型（手写 ReturnType）
type MyReturnType<T> = T extends (...args: any[]) => infer R ? R : never

function getUser() { return { id: 1, name: '张三' } }
type UserType = MyReturnType<typeof getUser>  // { id: number; name: string }

// 获取 Promise 的内部类型
type Awaited<T> = T extends Promise<infer R> ? R : T
type A = Awaited<Promise<string>>  // string
type B = Awaited<string>           // string（不是 Promise，直接返回）
```

### 映射类型

```ts
// 遍历对象类型的所有属性，生成新类型
// 手写 Partial
type MyPartial<T> = {
  [K in keyof T]?: T[K]
}

// 手写 Readonly
type MyReadonly<T> = {
  readonly [K in keyof T]: T[K]
}

// 实用：把所有属性值改为 string（表单字段类型）
type Stringify<T> = {
  [K in keyof T]: string
}

interface User { id: number; name: string; age: number }
type UserFormFields = Stringify<User>
// { id: string; name: string; age: string }  // 表单里都是字符串
```

### 模板字面量类型

```ts
// 字符串类型的模板拼接
type EventName = 'click' | 'focus' | 'blur'
type HandlerName = `on${Capitalize<EventName>}`
// 'onClick' | 'onFocus' | 'onBlur'

// 实用：API 路径类型
type ApiVersion = 'v1' | 'v2'
type Resource = 'users' | 'orders' | 'products'
type ApiPath = `/api/${ApiVersion}/${Resource}`
// '/api/v1/users' | '/api/v1/orders' | ... 共 6 种

// CSS 属性值
type Direction = 'top' | 'right' | 'bottom' | 'left'
type Padding = `padding-${Direction}`
// 'padding-top' | 'padding-right' | 'padding-bottom' | 'padding-left'
```

---

## 八、类

> TS 的类是 JS class 的增强版，加了访问修饰符、readonly、抽象类等特性。

### 访问修饰符

```ts
class User {
  public name: string        // 公开（默认就是 public，可以不写）
  private password: string   // 私有：只有类内部能访问
  protected age: number      // 受保护：类内部 + 子类能访问
  readonly id: number        // 只读：初始化后不能修改

  constructor(id: number, name: string, password: string, age: number) {
    this.id = id
    this.name = name
    this.password = password
    this.age = age
  }

  // 参数属性简写（直接在构造函数参数里声明，省去 this.xxx = xxx）
  // constructor(public name: string, private password: string) {}
}

const user = new User(1, '张三', '123456', 25)
user.name       // ✅
user.password   // ❌ 私有，外部不能访问
user.id = 2     // ❌ 只读
```

### 抽象类

```ts
// 抽象类：不能直接实例化，只能被继承
// 用来定义"模板方法"，子类必须实现抽象方法

abstract class Animal {
  abstract makeSound(): void   // 抽象方法：子类必须实现

  move(): void {               // 普通方法：子类可以直接用
    console.log('移动')
  }
}

class Dog extends Animal {
  makeSound() {                // 必须实现
    console.log('汪汪')
  }
}

// new Animal()  // ❌ 不能直接实例化抽象类
new Dog()       // ✅
```

### 类实现接口

```ts
// 接口定义"能做什么"，类实现接口
interface Serializable {
  serialize(): string
  deserialize(data: string): void
}

interface Printable {
  print(): void
}

// 一个类可以实现多个接口
class Document implements Serializable, Printable {
  private content: string = ''

  serialize(): string {
    return JSON.stringify({ content: this.content })
  }

  deserialize(data: string): void {
    this.content = JSON.parse(data).content
  }

  print(): void {
    console.log(this.content)
  }
}
```

---

## 九、模块与声明文件

### 模块系统（和 JS 完全一样）

```ts
// 导出
export const PI = 3.14
export function add(a: number, b: number) { return a + b }
export interface User { name: string; age: number }
export type Status = 'active' | 'inactive'

// 默认导出
export default class UserService { ... }

// 导入
import UserService, { PI, add, type User } from './user'
// 注意：导入类型用 import type 或 import { type User }（避免运行时导入）
```

### 声明文件（.d.ts）

```ts
// 当你用 JS 写的库没有 TS 类型时，需要写 .d.ts 文件声明类型
// 通常第三方库的类型在 @types/xxx 包里

// 安装类型声明（比如 lodash 没有内置类型）
// npm install -D @types/lodash

// 有时候需要自己写声明文件，比如自定义的全局变量
// global.d.ts
declare global {
  interface Window {
    myGlobalFunc: () => void  // 扩展 window 对象
  }
}

// 声明没有类型的 JS 模块（让 TS 不报错）
declare module 'some-js-lib' {
  export function doSomething(value: string): void
  export const VERSION: string
}

// 声明静态资源（如图片、SVG）
declare module '*.svg' {
  const content: string
  export default content
}
declare module '*.png' {
  const content: string
  export default content
}
```

---

## 十、配置 tsconfig.json

```json
{
  "compilerOptions": {
    // 目标环境
    "target": "ES2020",         // 编译到哪个 JS 版本
    "module": "ESNext",         // 模块格式
    "lib": ["ES2020", "DOM"],   // 包含的类型库

    // 模块解析
    "moduleResolution": "bundler",  // Vite 项目用 bundler
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]         // 路径别名（对应 vite.config.ts 的 alias）
    },

    // 严格模式（强烈推荐全开）
    "strict": true,              // 等价于开启下面所有严格选项
    // "strictNullChecks": true, // null/undefined 不能赋给其他类型
    // "noImplicitAny": true,    // 不允许隐式 any
    // "strictFunctionTypes": true,

    // 其他
    "esModuleInterop": true,     // 允许 import xxx from 'xxx'（不用 import * as）
    "skipLibCheck": true,        // 跳过 .d.ts 文件的类型检查（加快编译）
    "jsx": "preserve",           // Vue 项目用 preserve，React 项目用 react-jsx
    "incremental": true,         // 增量编译（加快二次编译速度）

    // 输出（用 Vite/webpack 时通常不需要）
    "outDir": "./dist",
    "declaration": true          // 生成 .d.ts 文件（写库时用）
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### strict 模式详解

```ts
// strictNullChecks: true 的效果
// 没开：null/undefined 可以赋给任意类型（很危险）
let name: string = null    // ✅ 没开时不报错

// 开了：必须显式声明可以为 null
let name: string | null = null  // ✅

// noImplicitAny 的效果
function process(data) {   // ❌ 参数没有类型，推断为 any，报错
  return data
}
function process(data: unknown) { // ✅ 显式标注
  return data
}
```

> **强烈推荐**：新项目直接开 `"strict": true`。老项目迁移可以逐步开启。

---

## 十一、Vue 3 + TypeScript 实战

### defineProps 与 defineEmits 类型

```ts
// 方式 1：泛型参数（推荐，更简洁）
const props = defineProps<{
  title: string
  count?: number
  items: string[]
  user: { name: string; age: number }
}>()

// 带默认值（配合 withDefaults）
const props = withDefaults(defineProps<{
  title: string
  count?: number
}>(), {
  count: 0
})

// defineEmits
const emit = defineEmits<{
  change: [value: string]       // 事件名: [参数类型]
  submit: [form: FormData]
  close: []                     // 无参数
}>()

emit('change', 'new value')
emit('close')
```

### Composable（自定义 Hook）类型

```ts
// composables/useUser.ts
import type { Ref } from 'vue'

interface User {
  id: number
  name: string
  email: string
}

interface UseUserReturn {
  user: Ref<User | null>
  loading: Ref<boolean>
  fetchUser: (id: number) => Promise<void>
}

export function useUser(): UseUserReturn {
  const user = ref<User | null>(null)
  const loading = ref(false)

  const fetchUser = async (id: number) => {
    loading.value = true
    user.value = await api.getUser(id)
    loading.value = false
  }

  return { user, loading, fetchUser }
}

// 使用
const { user, loading, fetchUser } = useUser()
// user 类型：Ref<User | null>，自动推断
```

### Pinia Store 类型

```ts
// stores/user.ts
interface UserState {
  user: User | null
  token: string
}

export const useUserStore = defineStore('user', () => {
  const user = ref<User | null>(null)
  const token = ref('')

  const isLogin = computed(() => !!user.value)

  async function login(credentials: { username: string; password: string }) {
    const res = await api.login(credentials)
    user.value = res.user
    token.value = res.token
  }

  function logout() {
    user.value = null
    token.value = ''
  }

  return { user, token, isLogin, login, logout }
})

// 使用时 Pinia 会自动推断所有类型，无需额外标注
```

### Vue Router 类型

```ts
// router/index.ts
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  { path: '/', component: () => import('@/views/Home.vue') },
  { path: '/users/:id', component: () => import('@/views/UserDetail.vue') }
]

// 在组件里使用
const route = useRoute()
const id = route.params.id as string   // params 类型是 string | string[]，需要断言

// 类型安全的路由参数（进阶）
// 可以用 unplugin-vue-router 插件自动生成路由类型
```

---

## 十二、React + TypeScript 实战

### 组件 Props 与事件

```tsx
// 基础 Props 类型
interface ButtonProps {
  label: string
  onClick: () => void
  variant?: 'primary' | 'secondary' | 'danger'
  disabled?: boolean
  children?: React.ReactNode         // 插槽内容
  className?: string
  style?: React.CSSProperties        // 行内样式对象
}

const Button = ({ label, onClick, variant = 'primary', disabled }: ButtonProps) => (
  <button className={variant} onClick={onClick} disabled={disabled}>
    {label}
  </button>
)

// 事件类型
const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {}
const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {}
const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
  e.preventDefault()
}
const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
  if (e.key === 'Enter') submit()
}
```

### Hooks 类型

```tsx
// useState
const [count, setCount] = useState(0)                    // 推断 number
const [user, setUser] = useState<User | null>(null)      // 手动标注
const [list, setList] = useState<string[]>([])

// useRef
const inputRef = useRef<HTMLInputElement>(null)           // DOM ref
const countRef = useRef<number>(0)                        // 存值 ref

// useReducer
type Action =
  | { type: 'increment' }
  | { type: 'set'; payload: number }

type State = { count: number }

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment': return { count: state.count + 1 }
    case 'set': return { count: action.payload }
  }
}

const [state, dispatch] = useReducer(reducer, { count: 0 })
```

### Context 类型

```tsx
interface AuthContextType {
  user: User | null
  login: (credentials: LoginCredentials) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextType | null>(null)

// 封装 Hook，避免每次判断 null
function useAuth(): AuthContextType {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth 必须在 AuthProvider 内使用')
  return ctx
}
```

---

## 十三、常见坑 + 面试题

### 常见坑

```ts
// 坑 1：any 用滥了
// ❌ 遇到报错就 as any
const result = (data as any).user.name  // 掩盖了问题
// ✅ 用 unknown + 类型收窄，或者定义正确的类型
if (isUser(data)) { data.user.name }

// 坑 2：类型断言滥用
const input = document.getElementById('input') as HTMLInputElement
input.value  // 如果实际上 #input 不存在，运行时报错
// ✅ 做判断
const input = document.getElementById('input')
if (input instanceof HTMLInputElement) { input.value }

// 坑 3：可选链和非空断言混淆
const name = user?.name     // 安全：user 为 null 时返回 undefined
const name2 = user!.name    // 危险：告诉 TS "我保证 user 不为 null"，但运行时可能崩

// 坑 4：枚举的坑（反向映射）
enum Direction { Up = 1, Down, Left, Right }
Direction[1]          // 'Up'（数字枚举会生成反向映射，对象变大）
// 推荐用字面量联合类型替代
type Direction = 'Up' | 'Down' | 'Left' | 'Right'

// 坑 5：泛型函数调用时类型丢失
function identity<T>(value: T) { return value }
const result = identity([1, 2, 3])  // 推断为 number[]（正确）
const result2 = identity([])        // 推断为 never[]（错误！）
const result3 = identity<number[]>([])  // ✅ 手动指定
```

### 逆变与协变（面试常问）

```ts
// 协变：子类型可以赋给父类型（安全，方向一致）
type Animal = { name: string }
type Dog = { name: string; breed: string }

let animal: Animal
let dog: Dog = { name: '旺财', breed: '柯基' }
animal = dog   // ✅ Dog 是 Animal 的子类型，可以赋值（协变）

// 逆变：函数参数类型（方向相反）
type AnimalHandler = (a: Animal) => void
type DogHandler = (d: Dog) => void

let handleAnimal: AnimalHandler = (a) => console.log(a.name)
let handleDog: DogHandler

handleDog = handleAnimal   // ✅ 接受 Dog 的地方可以用接受 Animal 的函数（逆变）
// 因为 Dog 有 Animal 的所有属性，传给 handleAnimal 是安全的
handleAnimal = handleDog   // ❌ 反过来不行，Dog 需要的 breed 属性 Animal 没有
```

### 面试高频题

**Q：type 和 interface 的区别？**
A：主要三点：① interface 支持声明合并，type 不支持；② type 可以定义联合类型、函数类型等，interface 只能定义对象；③ 扩展语法不同（interface 用 extends，type 用 &）。

**Q：any 和 unknown 的区别？**
A：都能接受任意类型的值。区别在于使用时：any 可以直接访问任意属性和方法，关闭类型检查；unknown 必须先做类型收窄（typeof/instanceof/类型谓词）才能使用，是类型安全的 any。

**Q：泛型约束 extends 和继承 extends 是一回事吗？**
A：不同。继承的 extends 表示"is a"关系；泛型约束的 extends 表示"必须满足某个结构"（结构子类型），不要求是继承关系，只要有对应的属性就行。

**Q：什么是结构化类型系统？**
A：TS 使用结构化（鸭子）类型，不看类型名字，只看结构。只要一个类型有另一个类型需要的所有属性，就认为兼容。这和 Java 的名义类型系统不同（Java 必须显式继承或实现才算兼容）。

**Q：infer 有什么用？**
A：在条件类型中"推断"出某个位置的类型。常见用途：获取函数返回值类型（ReturnType）、获取 Promise 的内部类型（Awaited）、获取数组的元素类型等。

---

> **TS 的核心思维**：类型是工具，不是枷锁。目标是在不牺牲开发体验的前提下，让 IDE 更聪明、让 bug 更早暴露。能推断的不写，写不出来的用 unknown + 收窄，实在不行再 as（但要知道自己在做什么）。
