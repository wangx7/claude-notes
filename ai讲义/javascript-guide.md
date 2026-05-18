# JavaScript 精讲

> 你已经会写 JS，也在 Vue/React 项目里用过它。这份文档不讲入门语法，而是**系统补全盲区、搞清楚底层原理**。看完能真正理解这门语言在做什么。

---

## 一、数据类型

### JS 有哪些类型

JS 共有 **8 种数据类型**，分为两大类：

| 分类 | 类型 |
|---|---|
| **原始类型**（7 种） | `string`、`number`、`bigint`、`boolean`、`null`、`undefined`、`symbol` |
| **引用类型**（1 种） | `object`（包含 Array、Function、Date、Map、Set 等） |

```js
// 原始类型：值直接存在变量里
let name = '张三'       // string
let age = 25            // number
let big = 9007n         // bigint（超大整数）
let flag = true         // boolean
let nothing = null      // null
let undef = undefined   // undefined
let sym = Symbol('id')  // symbol（唯一值）

// 引用类型：变量存的是内存地址（引用）
let user = { name: '张三' }   // object
let list = [1, 2, 3]          // array（本质也是 object）
let fn = () => {}              // function（本质也是 object）
```

> **原始类型 vs 引用类型的核心区别**：原始类型赋值是"复制值"，引用类型赋值是"复制地址"。

```js
// 原始类型：复制值，互不影响
let a = 1
let b = a
b = 2
console.log(a) // 1，a 没变

// 引用类型：复制地址，指向同一个对象
let obj1 = { x: 1 }
let obj2 = obj1       // obj2 和 obj1 指向同一个对象
obj2.x = 99
console.log(obj1.x)  // 99，obj1 也变了！
```

---

### 类型检测

#### typeof

```js
typeof 'hello'      // 'string'
typeof 42           // 'number'
typeof 42n          // 'bigint'
typeof true         // 'boolean'
typeof undefined    // 'undefined'
typeof Symbol()     // 'symbol'
typeof {}           // 'object'
typeof []           // 'object'（数组也是 object）
typeof function(){} // 'function'（函数比较特殊，不是 'object'）

// ⚠️ 两个特殊情况：
typeof null         // 'object' —— 这是历史遗留 bug，null 本身不是对象
typeof undeclaredVar // 'undefined' —— 未声明的变量不报错，返回 'undefined'
```

> `typeof null === 'object'` 是 JS 最出名的 bug 之一。原因是早期 JS 用 32 位存值，`null` 的二进制全是 0，而对象的标记位也是 0，所以被误判为 `object`。现在改不了了，太多代码依赖这个行为。

#### instanceof

```js
// instanceof 检查原型链，用于判断引用类型
[] instanceof Array      // true
[] instanceof Object     // true（Array 继承自 Object）
{} instanceof Object     // true

// 不能用来判断原始类型
'hello' instanceof String  // false（原始类型不是对象）
```

#### Object.prototype.toString（最准确）

```js
// 终极类型判断方法，能区分所有类型
const type = (val) => Object.prototype.toString.call(val).slice(8, -1).toLowerCase()

type('hello')      // 'string'
type(42)           // 'number'
type(null)         // 'null'
type(undefined)    // 'undefined'
type([])           // 'array'
type({})           // 'object'
type(new Date())   // 'date'
type(/regex/)      // 'regexp'
```

---

### null 和 undefined 的区别

这是 JS 特有的现象——两个都表示"没有值"，但含义不同：

```js
// undefined：变量声明了但没赋值，或函数没有返回值
let x           // x 是 undefined
function foo() {} 
foo()           // 返回值是 undefined

// null：主动赋的"空值"，表示"这里有个位置，但现在没有值"
let user = null  // 明确表示"用户还没加载"
```

> **实践原则**：函数参数不存在用 `undefined`，主动表示"空"用 `null`。比如请求用户数据前 `user = null`，请求完成但接口没返回数据也是 `null`。

---

### 类型转换

#### 显式转换（主动调用）

```js
// 转 number
Number('42')        // 42
Number('42px')      // NaN（不是纯数字字符串）
Number('')          // 0
Number(true)        // 1
Number(false)       // 0
Number(null)        // 0
Number(undefined)   // NaN

parseInt('42px')    // 42（取前面的数字部分，Number 不行）
parseInt('0xff', 16) // 255（指定进制）
parseFloat('3.14rem') // 3.14

// 转 string
String(42)          // '42'
String(null)        // 'null'
String(undefined)   // 'undefined'
(42).toString()     // '42'
(255).toString(16)  // 'ff'（转十六进制）

// 转 boolean
Boolean(0)          // false
Boolean('')         // false
Boolean(null)       // false
Boolean(undefined)  // false
Boolean(NaN)        // false
Boolean(false)      // false
// 以上 6 个是"假值"，其余全是 true
Boolean('0')        // true（字符串 '0' 不是空字符串！）
Boolean([])         // true（空数组也是 true！）
Boolean({})         // true（空对象也是 true！）
```

#### 隐式转换（触发场景）

隐式转换是 JS 的"暗黑魔法"，很多奇怪行为都源于此：

```js
// 场景 1：+ 运算符，有字符串则做字符串拼接
1 + '2'         // '12'（number 转 string）
1 + 2 + '3'     // '33'（先算 1+2=3，再 3+'3'='33'）
'1' + 2 + 3     // '123'（从左到右，先 '1'+2='12'，再 '12'+3='123'）

// 场景 2：- * / 运算符，会把两边都转成 number
'5' - 2         // 3
'5' * '2'       // 10
'abc' - 1       // NaN

// 场景 3：== 比较（宽松相等），会做类型转换
0 == false      // true（false 转 number 是 0）
'' == false     // true（都转 number 变 0）
null == undefined // true（特殊规定）
null == 0       // false（null 不转 number）
'1' == 1        // true（'1' 转成 number 1）
[] == false     // true（[] 转 string 是 ''，'' 转 number 是 0，false 也是 0）
```

#### == 的转换规则（记住这个，避免踩坑）

```js
// == 的完整规则：
// 1. 两边类型相同：直接比较值
// 2. null == undefined：true（仅这一对特殊）
// 3. 有 number：另一边转 number
// 4. 有 boolean：先把 boolean 转 number，再重新比较
// 5. 对象 vs 原始值：对象先调用 valueOf() 或 toString() 转原始值

// 所以永远用 ===（严格相等），不做类型转换
0 === false     // false（类型不同，直接 false）
'' === false    // false
null === undefined // false

// 唯一合理用 == 的场景：同时判断 null 和 undefined
if (val == null) { ... }  // 等价于 val === null || val === undefined
```

#### 对象转原始值

```js
// 对象在需要原始值的场景下，会调用：
// 1. valueOf()：默认返回对象本身（没什么用）
// 2. toString()：默认返回 '[object Object]'

// 可以自定义这两个方法来控制转换行为
const money = {
  amount: 100,
  valueOf() { return this.amount },
  toString() { return `¥${this.amount}` }
}

money + 50    // 150（用了 valueOf）
`金额：${money}`  // '金额：¥100'（模板字符串用 toString）
```

---

### NaN 和 Infinity

```js
// NaN：Not a Number，但它的类型是 number
typeof NaN    // 'number'（没错，就是这么设计的）
NaN === NaN   // false（NaN 不等于任何值，包括自己）

// 判断是否是 NaN
isNaN('abc')     // true（先把 'abc' 转 number 变 NaN，再判断）
Number.isNaN('abc')  // false（不做转换，只判断是不是真的 NaN，更准确）
Number.isNaN(NaN)    // true

// Infinity：无穷大
1 / 0         // Infinity
-1 / 0        // -Infinity
Infinity + 1  // Infinity
isFinite(Infinity)  // false
isFinite(42)        // true
```

---

## 二、作用域与闭包

### 作用域是什么

作用域就是**变量能被访问到的范围**。JS 是词法作用域（静态作用域），意思是作用域在**写代码时**就已经确定，和函数在哪里调用无关。

```js
const x = 1

function foo() {
  console.log(x)  // 1，访问外层的 x
}

function bar() {
  const x = 99
  foo()           // 还是输出 1！foo 的作用域在定义时确定，不看 bar
}

bar()
```

> 词法作用域 = 定义时决定，而不是运行时决定。这和 `this` 完全相反（`this` 是运行时决定的）。

### var / let / const 的作用域区别

```js
// var：函数作用域（函数内有效）+ 变量提升
function example() {
  if (true) {
    var x = 1   // var 的作用域是整个函数，不是 if 块
  }
  console.log(x)  // 1（能访问到！）
}

// let / const：块级作用域（{} 内有效），ES6 引入
function example2() {
  if (true) {
    let y = 1   // 只在这个 {} 内有效
    const z = 2
  }
  console.log(y)  // ❌ ReferenceError：y 未定义
}
```

### 变量提升（Hoisting）

```js
// var 声明会被"提升"到函数顶部，但赋值不会提升
console.log(a)  // undefined（不是报错！var 声明被提升了）
var a = 1
console.log(a)  // 1

// 上面代码等价于：
var a           // 声明提升到顶部
console.log(a)  // undefined
a = 1
console.log(a)  // 1

// let / const 不提升（严格来说是有"暂时性死区"）
console.log(b)  // ❌ ReferenceError
let b = 1

// 函数声明也会提升，且整体提升（包括函数体）
hello()         // ✅ 'hello'（函数声明可以在定义前调用）
function hello() { console.log('hello') }

// 函数表达式不会提升
world()         // ❌ TypeError：world is not a function
var world = function() { console.log('world') }
```

### 作用域链

当访问一个变量时，JS 会从当前作用域开始找，找不到就往外层找，一直到全局作用域：

```js
const global = 'global'

function outer() {
  const outerVar = 'outer'

  function inner() {
    const innerVar = 'inner'
    // 访问顺序：inner 自己 → outer → global
    console.log(innerVar)  // 'inner'（自己有）
    console.log(outerVar)  // 'outer'（从 outer 找到）
    console.log(global)    // 'global'（从全局找到）
  }

  inner()
}
```

---

### 闭包

#### 什么是闭包

闭包 = **函数 + 它能访问的外部变量**。当一个函数"记住"了定义它时的外部变量，即使那个外部函数已经执行完毕，这些变量也不会消失。

```js
function makeCounter() {
  let count = 0          // 这个变量会被"记住"

  return function() {    // 返回的函数就是闭包
    count++
    return count
  }
}

const counter = makeCounter()
// makeCounter 执行完了，但 count 没有消失
counter()  // 1
counter()  // 2
counter()  // 3
```

> **为什么 count 没消失**？因为返回的函数还持有对 `count` 的引用，垃圾回收器不会回收它。

#### 闭包的实际用途

**用途 1：私有变量（封装）**

```js
function createUser(name) {
  let _balance = 0  // 外部访问不到，"私有变量"

  return {
    deposit(amount) { _balance += amount },
    withdraw(amount) { _balance -= amount },
    getBalance() { return _balance }
  }
}

const user = createUser('张三')
user.deposit(100)
user.withdraw(30)
user.getBalance()  // 70
user._balance      // undefined（外部访问不到！）
```

**用途 2：函数工厂**

```js
// 根据参数生成不同行为的函数
function multiplier(factor) {
  return (num) => num * factor  // factor 被"记住"
}

const double = multiplier(2)
const triple = multiplier(3)

double(5)   // 10
triple(5)   // 15
```

**用途 3：防抖（debounce）**

```js
function debounce(fn, delay) {
  let timer = null  // timer 被闭包持有

  return function(...args) {
    clearTimeout(timer)
    timer = setTimeout(() => {
      fn.apply(this, args)
    }, delay)
  }
}

const search = debounce((keyword) => {
  console.log('搜索：', keyword)
}, 300)

// 快速连续调用，只有最后一次会执行
search('j')
search('ja')
search('jav')
search('java')  // 只有这次会触发，300ms 后执行
```

#### 闭包的经典坑：循环里的异步

```js
// 问题：用 var 循环注册事件，点任何按钮都输出 3
for (var i = 0; i < 3; i++) {
  setTimeout(() => {
    console.log(i)  // 全是 3！因为 var 没有块级作用域
  }, 1000)
}
// 原因：3 个 setTimeout 共享同一个 i，循环结束时 i 已经是 3

// 解法 1：用 let（最简单，let 有块级作用域，每次循环产生新的 i）
for (let i = 0; i < 3; i++) {
  setTimeout(() => {
    console.log(i)  // 0、1、2
  }, 1000)
}

// 解法 2：用立即执行函数（IIFE）给每次循环创建独立作用域
for (var i = 0; i < 3; i++) {
  ;((j) => {
    setTimeout(() => {
      console.log(j)  // 0、1、2
    }, 1000)
  })(i)  // 立即把 i 的当前值传进去
}
```

---

## 三、this 与执行上下文

### this 是什么

`this` 是函数执行时的一个隐式参数，指向**调用这个函数的对象**。和作用域不同，`this` 不是在写代码时确定的，而是**运行时根据调用方式**来决定。

### 四种调用规则

#### 规则 1：普通函数调用 → this 是全局对象（或 undefined）

```js
function foo() {
  console.log(this)
}

foo()  // 浏览器：window；严格模式下：undefined
```

#### 规则 2：方法调用 → this 是调用它的对象

```js
const user = {
  name: '张三',
  greet() {
    console.log(this.name)  // this 指向 user
  }
}

user.greet()  // '张三'

// ⚠️ 把方法赋给变量再调用，this 就丢了
const fn = user.greet
fn()  // undefined（严格模式）或 window.name（非严格）
```

#### 规则 3：new 调用 → this 是新创建的对象

```js
function Person(name) {
  this.name = name  // this 指向新对象
}

const p = new Person('张三')
p.name  // '张三'

// new 做了什么：
// 1. 创建一个空对象 {}
// 2. 把 this 指向这个空对象
// 3. 执行函数体
// 4. 返回这个对象（除非函数自己返回了其他对象）
```

#### 规则 4：call / apply / bind → 手动指定 this

```js
function greet(greeting) {
  console.log(`${greeting}，${this.name}`)
}

const user = { name: '张三' }

greet.call(user, '你好')      // '你好，张三'（立即调用，参数逐个传）
greet.apply(user, ['你好'])   // '你好，张三'（立即调用，参数用数组传）

const boundGreet = greet.bind(user)  // 返回新函数，this 永久绑定 user
boundGreet('嗨')   // '嗨，张三'（之后随时调用）
```

> **优先级**：`new` > `call/apply/bind` > 方法调用 > 普通调用

### 箭头函数的 this

箭头函数**没有自己的 this**，它的 this 继承自定义它时的外层作用域，永远不变。

```js
const user = {
  name: '张三',
  // 普通函数：this 取决于调用方式
  greetNormal() {
    setTimeout(function() {
      console.log(this.name)  // undefined！setTimeout 的回调是普通函数调用
    }, 100)
  },
  // 箭头函数：this 继承外层（greetArrow 方法）的 this
  greetArrow() {
    setTimeout(() => {
      console.log(this.name)  // '张三'！箭头函数 this 是外层的 user
    }, 100)
  }
}

user.greetNormal()  // undefined
user.greetArrow()   // '张三'
```

```js
// 箭头函数不能用 call/bind 改变 this
const obj = { name: '张三' }
const arrow = () => console.log(this)  // this 已固定为定义时的外层 this

arrow.call(obj)  // 无效，this 不会变成 obj
```

> **什么时候用箭头函数**：回调函数里需要用外层 `this` 时（如 setTimeout、事件监听、Promise 链）。  
> **什么时候不用箭头函数**：对象方法、构造函数、需要自己的 `this` 的场景。

### call / apply / bind 的实现原理

理解原理有助于真正掌握 this：

```js
// 手写 call（核心：把函数挂到对象上调用，调完删掉）
Function.prototype.myCall = function(context, ...args) {
  context = context ?? globalThis    // null/undefined 时指向全局
  const key = Symbol()               // 用 Symbol 避免属性名冲突
  context[key] = this                // this 是当前函数
  const result = context[key](...args)  // 通过对象调用，this 自然指向 context
  delete context[key]
  return result
}

// 手写 bind
Function.prototype.myBind = function(context, ...outerArgs) {
  const fn = this
  return function(...innerArgs) {
    return fn.apply(context, [...outerArgs, ...innerArgs])
  }
}

// 验证
function greet(greeting) {
  return `${greeting}，${this.name}`
}
const user = { name: '张三' }
greet.myCall(user, '你好')   // '你好，张三'
```

---

## 四、原型链与继承

### 原型是什么

JS 里每个对象都有一个隐藏属性 `[[Prototype]]`（可以通过 `__proto__` 访问），指向它的**原型对象**。访问一个属性时，如果对象自身没有，就会顺着原型链向上找。

```js
const obj = { name: '张三' }

// obj 自身没有 toString，但能调用
obj.toString()  // '[object Object]'

// 查找过程：
// obj 自身 → obj.__proto__（Object.prototype）→ 找到 toString ✅

// 原型链的终点
Object.prototype.__proto__  // null
```

### 构造函数与 prototype

```js
function Person(name, age) {
  this.name = name  // 实例自己的属性
  this.age = age
}

// 方法挂在 prototype 上，所有实例共享（省内存）
Person.prototype.greet = function() {
  return `我是${this.name}`
}

const p1 = new Person('张三', 25)
const p2 = new Person('李四', 30)

p1.greet()  // '我是张三'
p2.greet()  // '我是李四'

// p1 和 p2 共享同一个 greet 函数
p1.greet === p2.greet  // true

// 关系：
// p1.__proto__ === Person.prototype  // true
// Person.prototype.constructor === Person  // true
```

> **为什么方法挂 prototype 而不写在构造函数里**？如果写在构造函数里（`this.greet = function(){...}`），每个实例都会创建一份新的函数，浪费内存。原型上的方法所有实例共享一份。

### 原型链的完整图

```
p1 实例
  ├── name: '张三'（自身属性）
  ├── age: 25（自身属性）
  └── __proto__ → Person.prototype
                    ├── greet: function（方法）
                    ├── constructor: Person
                    └── __proto__ → Object.prototype
                                      ├── toString: function
                                      ├── hasOwnProperty: function
                                      └── __proto__ → null（链的终点）
```

```js
// 判断属性是自身的还是原型上的
p1.hasOwnProperty('name')   // true（自身属性）
p1.hasOwnProperty('greet')  // false（原型上的）

// 检查原型链
p1 instanceof Person   // true
p1 instanceof Object   // true（Object 在更上层的原型链上）
```

### class 是语法糖

ES6 的 `class` 写法本质上还是原型链，只是更好看：

```js
// ES5 写法
function Animal(name) {
  this.name = name
}
Animal.prototype.speak = function() {
  return `${this.name} 发出声音`
}

// ES6 class（等价的写法，编译后一样）
class Animal {
  constructor(name) {
    this.name = name
  }

  speak() {           // 等价于 Animal.prototype.speak = function(){}
    return `${this.name} 发出声音`
  }
}
```

### 继承

```js
class Animal {
  constructor(name) {
    this.name = name
  }
  speak() {
    return `${this.name} 发出声音`
  }
}

class Dog extends Animal {
  constructor(name, breed) {
    super(name)        // 必须先调用 super，才能用 this
    this.breed = breed
  }

  // 重写父类方法
  speak() {
    return `${this.name} 汪汪叫`
  }

  // 调用父类方法
  superSpeak() {
    return super.speak()
  }
}

const dog = new Dog('旺财', '柴犬')
dog.speak()       // '旺财 汪汪叫'
dog.superSpeak()  // '旺财 发出声音'
dog instanceof Dog     // true
dog instanceof Animal  // true（继承链上）
```

### Object 常用静态方法

```js
// Object.create：用指定对象作为原型，创建新对象
const base = { greet() { return `你好，我是${this.name}` } }
const user = Object.create(base)
user.name = '张三'
user.greet()  // '你好，我是张三'

// Object.assign：浅拷贝合并对象
const target = { a: 1 }
const result = Object.assign(target, { b: 2 }, { c: 3 })
// { a: 1, b: 2, c: 3 }

// Object.keys / values / entries：遍历对象
const obj = { a: 1, b: 2, c: 3 }
Object.keys(obj)    // ['a', 'b', 'c']
Object.values(obj)  // [1, 2, 3]
Object.entries(obj) // [['a', 1], ['b', 2], ['c', 3]]

// Object.freeze：冻结对象，不能增删改属性
const frozen = Object.freeze({ x: 1 })
frozen.x = 99  // 静默失败（严格模式下报错）
frozen.x       // 1（没变）
```


---

## 五、异步编程

### 为什么 JS 是单线程的

JS 设计之初就是单线程语言，同一时间只能做一件事。原因是它主要用于操作 DOM，多线程操作 DOM 会产生竞态问题太复杂。

但单线程不代表不能处理异步操作——JS 靠**事件循环**来实现非阻塞的异步。

### 事件循环（Event Loop）

```
JS 执行环境的核心结构：

┌─────────────────────────┐
│       调用栈（Call Stack）│  ← 同步代码在这里执行
└─────────────────────────┘
         ↑
         │ 取任务
┌────────────────────────────────────────────────┐
│  任务队列                                        │
│  ┌────────────────────────────────────────┐    │
│  │  微任务队列（Microtask Queue）           │    │
│  │  Promise.then / queueMicrotask / MutationObserver │
│  └────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────┐    │
│  │  宏任务队列（Macrotask Queue）           │    │
│  │  setTimeout / setInterval / I/O / 事件  │    │
│  └────────────────────────────────────────┘    │
└────────────────────────────────────────────────┘
```

**事件循环的执行顺序：**
1. 执行同步代码（清空调用栈）
2. 清空所有微任务（微任务队列里的全部执行完）
3. 取一个宏任务执行
4. 执行过程中产生的微任务立刻全部执行
5. 回到步骤 3

```js
console.log('1')  // 同步

setTimeout(() => {
  console.log('2')  // 宏任务
}, 0)

Promise.resolve().then(() => {
  console.log('3')  // 微任务
})

console.log('4')  // 同步

// 输出顺序：1 → 4 → 3 → 2
// 同步先走，微任务在宏任务前
```

**一个复杂例子：**

```js
console.log('start')

setTimeout(() => {
  console.log('setTimeout 1')
  Promise.resolve().then(() => {
    console.log('promise in setTimeout')  // 宏任务执行时产生的微任务
  })
}, 0)

Promise.resolve()
  .then(() => {
    console.log('promise 1')
    setTimeout(() => {
      console.log('setTimeout in promise')  // 微任务执行时产生的宏任务
    }, 0)
  })
  .then(() => {
    console.log('promise 2')
  })

console.log('end')

// 输出：
// start
// end
// promise 1
// promise 2
// setTimeout 1
// promise in setTimeout
// setTimeout in promise
```

> **关键规律**：每次宏任务执行后，会立刻把当前微任务队列清空，才执行下一个宏任务。

---

### Promise

Promise 是用来处理异步操作的对象，解决了"回调地狱"问题。

#### 三种状态

```
pending（等待）→ fulfilled（成功）→ 只能转换一次，不可逆
pending（等待）→ rejected（失败）→ 只能转换一次，不可逆
```

#### 基本用法

```js
// 创建 Promise
const p = new Promise((resolve, reject) => {
  // 异步操作
  setTimeout(() => {
    const success = true
    if (success) {
      resolve('成功的数据')  // 变为 fulfilled
    } else {
      reject(new Error('失败原因'))  // 变为 rejected
    }
  }, 1000)
})

// 消费 Promise
p.then(data => {
  console.log(data)  // '成功的数据'
}).catch(err => {
  console.error(err)
}).finally(() => {
  console.log('无论成功失败都执行')
})
```

#### 链式调用（解决回调地狱）

```js
// 回调地狱（老写法）
login(user, (err, token) => {
  if (err) return handleError(err)
  fetchProfile(token, (err, profile) => {
    if (err) return handleError(err)
    fetchOrders(profile.id, (err, orders) => {
      // 继续嵌套...
    })
  })
})

// Promise 链式调用（清晰多了）
login(user)
  .then(token => fetchProfile(token))  // 返回新的 Promise
  .then(profile => fetchOrders(profile.id))
  .then(orders => {
    console.log(orders)
  })
  .catch(err => {
    // 链中任意一步的错误都会在这里被捕获
    handleError(err)
  })
```

#### Promise 静态方法

```js
// Promise.all：全部成功才成功，一个失败全失败
const [user, orders, settings] = await Promise.all([
  fetchUser(id),
  fetchOrders(id),
  fetchSettings(id)
])
// 三个请求并发，等全部完成

// Promise.allSettled：等所有都完成，不管成功还是失败
const results = await Promise.allSettled([
  fetchA(),
  fetchB(),
  fetchC()
])
results.forEach(result => {
  if (result.status === 'fulfilled') console.log(result.value)
  if (result.status === 'rejected') console.error(result.reason)
})

// Promise.race：最快的那个完成就返回（不管成功失败）
const fastest = await Promise.race([fetch(url1), fetch(url2)])

// Promise.any：最快成功的那个返回（全失败才失败）
const first = await Promise.any([fetchA(), fetchB(), fetchC()])
```

---

### async / await

`async/await` 是 Promise 的语法糖，让异步代码看起来像同步代码。

#### 基本语法

```js
// async 函数总是返回 Promise
async function fetchUser(id) {
  const res = await fetch(`/api/users/${id}`)  // 等待 Promise 完成
  const data = await res.json()
  return data  // 等价于 return Promise.resolve(data)
}

// await 只能在 async 函数内用
// await 后面跟一个 Promise，暂停执行直到 Promise 完成，然后返回结果
```

#### 错误处理

```js
// 方式 1：try/catch（推荐）
async function getUser(id) {
  try {
    const res = await fetch(`/api/users/${id}`)
    if (!res.ok) throw new Error(`HTTP 错误：${res.status}`)
    return await res.json()
  } catch (err) {
    console.error('请求失败：', err)
    return null
  }
}

// 方式 2：在调用处 .catch()
const user = await getUser(1).catch(err => null)
```

#### async/await 的本质

`async/await` 底层是 Generator + Promise 的组合。理解这个能帮助你理解执行顺序：

```js
// async/await 写法
async function main() {
  console.log('start')
  const result = await Promise.resolve(42)
  console.log(result)  // 42
  console.log('end')
}
main()
console.log('sync after main')

// 输出：
// start
// sync after main（！！main 在 await 处暂停，把控制权交还给外层）
// 42
// end

// await 相当于：把后续代码包进 .then() 里
// 所以 await 之后的代码是微任务
```

#### 常见使用模式

```js
// 模式 1：顺序执行（每个等上一个）
async function sequential() {
  const a = await fetchA()  // 等 a 完成
  const b = await fetchB(a) // 用 a 的结果请求 b
  return b
}

// 模式 2：并发执行（同时发请求，用 Promise.all 等结果）
async function concurrent() {
  const [a, b] = await Promise.all([fetchA(), fetchB()])
  return { a, b }
}

// 模式 3：循环里的异步（不要用 forEach！）
// ❌ forEach 不等待异步
const ids = [1, 2, 3]
ids.forEach(async (id) => {
  const user = await fetchUser(id)
  console.log(user)  // 顺序不确定，forEach 不等 await
})

// ✅ for...of 循环（顺序执行）
for (const id of ids) {
  const user = await fetchUser(id)
  console.log(user)
}

// ✅ Promise.all + map（并发执行）
const users = await Promise.all(ids.map(id => fetchUser(id)))
```

---

## 六、ES6+ 核心特性

### 解构赋值

```js
// 数组解构
const [a, b, c] = [1, 2, 3]
const [first, , third] = [1, 2, 3]  // 跳过第二个
const [head, ...rest] = [1, 2, 3, 4]  // head=1, rest=[2,3,4]

// 默认值
const [x = 0, y = 0] = [1]  // x=1, y=0

// 对象解构
const { name, age } = { name: '张三', age: 25 }

// 重命名
const { name: userName, age: userAge } = user

// 默认值
const { name = '匿名', role = 'user' } = user

// 嵌套解构
const { address: { city, zip } } = user

// 函数参数解构（非常常用！）
function greet({ name, age = 18 }) {
  return `${name}，${age}岁`
}
greet({ name: '张三' })  // '张三，18岁'
```

### 展开运算符（...）

```js
// 展开数组
const arr1 = [1, 2]
const arr2 = [3, 4]
const combined = [...arr1, ...arr2]  // [1, 2, 3, 4]

// 复制数组（浅拷贝）
const copy = [...arr1]

// 展开对象（合并/复制）
const base = { a: 1, b: 2 }
const extended = { ...base, c: 3 }   // { a: 1, b: 2, c: 3 }
const overrided = { ...base, b: 99 } // { a: 1, b: 99 }（后面的覆盖前面的）

// 展开作为函数参数
Math.max(...[1, 2, 3])  // 等价于 Math.max(1, 2, 3)
```

### Symbol

Symbol 是唯一值，主要用途是作为对象属性的唯一键，避免命名冲突：

```js
const id = Symbol('id')  // 描述只是调试用的，不影响唯一性
const id2 = Symbol('id')
id === id2  // false（每个 Symbol 都唯一）

// 作为对象属性键
const user = {
  name: '张三',
  [id]: 12345  // Symbol 作为键，外部不会随便访问到
}

user[id]    // 12345
user.id     // undefined（Symbol 键不能用点语法访问）

// Symbol.for：全局注册表，相同描述返回同一个 Symbol
const s1 = Symbol.for('shared')
const s2 = Symbol.for('shared')
s1 === s2  // true

// 内置 Symbol（改变对象的内置行为）
class MyArray {
  [Symbol.iterator]() {  // 让对象可以 for...of 遍历
    let i = 0
    return {
      next: () => ({ value: i++, done: i > 3 })
    }
  }
}
for (const val of new MyArray()) {
  console.log(val)  // 0, 1, 2
}
```

### Map 和 Set

```js
// Map：键值对，键可以是任意类型（区别于对象只能用字符串/Symbol 作键）
const map = new Map()
map.set('name', '张三')
map.set(42, '数字键')
map.set({ id: 1 }, '对象键')  // 对象也能做键！

map.get('name')   // '张三'
map.has('name')   // true
map.size          // 3
map.delete('name')

// 遍历
for (const [key, value] of map) {
  console.log(key, value)
}

// Set：不重复值的集合
const set = new Set([1, 2, 2, 3, 3, 3])
// Set { 1, 2, 3 }（自动去重）

set.add(4)
set.has(2)   // true
set.size     // 4
set.delete(1)

// 数组去重的常用技巧
const unique = [...new Set([1, 2, 2, 3])]  // [1, 2, 3]
```

### 可选链（?.）和 空值合并（??）

```js
// 可选链：访问可能为 null/undefined 的属性，不会报错
const user = null
user.name        // ❌ TypeError
user?.name       // undefined（安全）
user?.address?.city  // undefined（链式）
user?.greet()    // undefined（方法调用也行）
arr?.[0]         // undefined（数组访问也行）

// 空值合并：只有 null 或 undefined 才用默认值
const name = user?.name ?? '匿名'  // user.name 为 null/undefined 时用 '匿名'

// 区别于 ||（|| 对所有假值生效）
const count = 0
count || 10   // 10（因为 0 是假值，这通常不是想要的结果）
count ?? 10   // 0（0 不是 null/undefined，保留 0）
```


---

### Proxy 和 Reflect

Proxy 可以拦截对对象的各种操作，Vue 3 的响应式系统就是基于 Proxy 实现的。

```js
const handler = {
  get(target, key) {
    console.log(`读取 ${key}`)
    return Reflect.get(target, key)
  },
  set(target, key, value) {
    console.log(`设置 ${key} = ${value}`)
    return Reflect.set(target, key, value)
  },
  deleteProperty(target, key) {
    console.log(`删除 ${key}`)
    return Reflect.deleteProperty(target, key)
  }
}

const proxy = new Proxy({ name: '张三', age: 25 }, handler)
proxy.name        // 输出"读取 name"，返回 '张三'
proxy.age = 30    // 输出"设置 age = 30"
delete proxy.name // 输出"删除 name"
```

**Vue 3 响应式的简化实现：**

```js
function reactive(obj) {
  return new Proxy(obj, {
    get(target, key) {
      track(target, key)  // 收集依赖（谁在读这个属性）
      return Reflect.get(target, key)
    },
    set(target, key, value) {
      const result = Reflect.set(target, key, value)
      trigger(target, key)  // 触发更新（通知所有依赖重新执行）
      return result
    }
  })
}
```

> **为什么用 Reflect 而不直接 `target[key]`**：Reflect 方法和 Proxy 的 trap 一一对应，返回值更准确（`Reflect.set` 返回 boolean 表示是否成功），行为更规范。

---

## 七、模块系统

### CommonJS vs ESM

| | CommonJS（CJS） | ES Modules（ESM） |
|---|---|---|
| **语法** | `require` / `module.exports` | `import` / `export` |
| **环境** | Node.js 传统 | 浏览器 + 现代 Node.js |
| **加载时机** | 运行时（动态） | 编译时（静态） |
| **导出内容** | 值的拷贝 | 值的实时引用（live binding） |
| **Tree Shaking** | 不支持 | 支持 |

```js
// CommonJS
const fs = require('fs')
const { join } = require('path')
module.exports = { foo, bar }
exports.baz = 123  // exports 是 module.exports 的引用

// ES Modules（现代项目标准写法）
import fs from 'node:fs'
import { join } from 'node:path'

export const PI = 3.14
export function add(a, b) { return a + b }
export default class User {}  // 默认导出，每个文件只能有一个
```

### Tree Shaking 与动态导入

```js
// ESM 的 import 必须在文件顶层，不能放在 if 里
// 正因为静态，打包工具能分析出哪些导出被用了，没用到的删掉（Tree Shaking）

// 只用了 add，打包时 mul、div 不会进包
import { add } from './math'

// 动态 import()——返回 Promise，运行时按需加载
if (needHeavyFeature) {
  const module = await import('./heavyModule.js')
  module.default()
}

// 路由懒加载（Vue/React 常用）
const UserPage = () => import('./pages/User.vue')
const routes = [{ path: '/user', component: UserPage }]
```

### 循环依赖

```js
// a.js 导入 b.js，b.js 又导入 a.js → 循环依赖

// ESM 中导出是"引用"，循环时可能读到 undefined（对方模块还没执行完）
// a.js
import { b } from './b.js'
export const a = 'A'
console.log('b =', b)  // 可能是 undefined，取决于执行顺序

// 最佳实践：把共用的东西提取到第三个文件（constants.js / utils.js）
// a 和 b 都从它导入，避免互相依赖
```

### 导入导出的最佳实践

```js
// 1. 命名导出优于默认导出（便于 Tree Shaking 和 IDE 自动补全）
// ✅ 命名导出
export function fetchUser() {}
export function fetchOrders() {}

// ❌ 默认导出对象（全量引入，无法 Tree Shaking）
export default { fetchUser, fetchOrders }

// 2. 类型单独导入（TS 项目，纯类型不进运行时）
import type { User, Order } from './types'

// 3. 重命名解决冲突
import { format as formatDate } from 'date-fns'
import { format as formatNumber } from './utils'

// 4. 重导出（barrel 文件，统一入口）
// index.js
export { Button } from './Button'
export { Input } from './Input'
export { Modal } from './Modal'
// 使用时：import { Button, Input } from './components'
```

---

## 八、内存管理

### 垃圾回收：标记-清除算法

JS 不需要手动释放内存，垃圾回收器（GC）自动处理。现代 V8 引擎使用**标记-清除（Mark and Sweep）**算法：

```
执行步骤：
1. 从根对象出发（全局变量、当前调用栈里的变量）
2. 标记所有从根能"到达"的对象（可达对象）
3. 清除所有未被标记的对象（不可达 = 没有任何引用指向它）

结论：没有任何变量引用的对象 = 垃圾 = 等待 GC 回收
```

```js
let user = { name: '张三' }  // 对象被 user 引用
user = null                   // 引用断开，对象变成垃圾，等待 GC

// 互相引用不是问题，只要从根无法到达，GC 同样能回收
function test() {
  const a = {}
  const b = {}
  a.ref = b   // a 和 b 互相引用
  b.ref = a
}
test()  // 执行完，a 和 b 离开作用域，从根无法到达，都会被回收
```

### 常见内存泄漏场景

```js
// 泄漏 1：意外的全局变量
function leak() {
  leakedData = new Array(100000)  // 没有 let/const/var！变成全局变量，永不回收
}
// 解决：开启严格模式 'use strict'，或者用 ESM（默认严格模式）

// 泄漏 2：忘记清除的定时器
const bigData = { list: new Array(100000).fill('x') }

const timer = setInterval(() => {
  process(bigData)  // bigData 被 timer 的回调持有，一直无法回收
}, 1000)

// 正确做法：组件卸载时清理
onUnmounted(() => clearInterval(timer))

// 泄漏 3：未移除的事件监听
function addListener() {
  const handler = (e) => { /* 持有外部大对象 */ }
  document.addEventListener('scroll', handler)
  // handler 持有闭包，scroll 一直触发，handler 永不回收
  // 需要：document.removeEventListener('scroll', handler)
}

// 泄漏 4：闭包里持有不再需要的大对象
function createProcessor() {
  const rawData = new Array(1000000).fill('x')  // 大数组

  // ❌ 闭包持有整个 rawData，rawData 永远不会释放
  return () => console.log(rawData.length)

  // ✅ 只保留需要的值，rawData 可以被回收
  // const len = rawData.length
  // return () => console.log(len)
}
```

### WeakMap 和 WeakRef

```js
// WeakMap：键是弱引用，键被 GC 后对应记录自动清除
// 适合：给对象附加元数据，不影响对象被 GC

const cache = new WeakMap()

function processUser(user) {
  if (cache.has(user)) return cache.get(user)

  const result = expensiveCompute(user)
  cache.set(user, result)  // user 消失时，cache 里的记录也自动删除
  return result
}

// Vue 3 大量使用 WeakMap 存依赖关系：
// targetMap: WeakMap<对象, Map<属性, Set<副作用函数>>>
// 当响应式对象被 GC，相关依赖自动清除，零内存泄漏

// WeakSet：存弱引用对象集合（不阻止 GC）
const visited = new WeakSet()
function visit(node) {
  if (visited.has(node)) return
  visited.add(node)
  // 处理 node...
}

// WeakRef：持有弱引用，可以检测对象是否还活着
const ref = new WeakRef(someHeavyObject)

function useObject() {
  const obj = ref.deref()
  if (obj !== undefined) {
    obj.doSomething()   // 对象还存活
  } else {
    // 已经被 GC 回收了，需要重建
  }
}
```

### 性能优化：减少 GC 压力

```js
// 1. 避免在热路径里大量创建临时对象
// ❌ 每次调用都创建新数组
function getCoords(event) {
  return { x: event.clientX, y: event.clientY }  // 频繁调用会产生大量垃圾
}

// ✅ 复用对象
const coords = { x: 0, y: 0 }
function getCoords(event) {
  coords.x = event.clientX
  coords.y = event.clientY
  return coords  // 复用同一个对象
}

// 2. 大列表用虚拟滚动，不把全部 DOM 节点都创建出来
// 3. 图片/视频等大资源用完及时解除引用
let video = document.createElement('video')
video.src = url
// 用完后：
video.src = ''   // 释放媒体资源
video = null     // 解除引用
```

---

> **全文总结**：这份文档覆盖了 JS 的完整核心体系——数据类型与类型转换、作用域与闭包、this 与执行上下文、原型链与继承、异步编程（事件循环 / Promise / async-await）、ES6+ 核心特性、模块系统、内存管理。掌握这些，就掌握了这门语言真正运行的方式。

---

## 九、性能优化

### 节流（throttle）

防抖（debounce）在第二章提过：最后一次触发后才执行。节流是另一种策略：**固定时间内最多执行一次**，适合 scroll、resize、mousemove 等高频事件。

```js
function throttle(fn, interval) {
  let lastTime = 0

  return function(...args) {
    const now = Date.now()
    if (now - lastTime >= interval) {
      lastTime = now
      fn.apply(this, args)
    }
  }
}

// 用法：scroll 事件每 200ms 最多触发一次
window.addEventListener('scroll', throttle(() => {
  updateScrollIndicator()
}, 200))
```

**防抖 vs 节流选哪个：**

| 场景 | 选择 | 原因 |
|---|---|---|
| 搜索框输入 | 防抖 | 停止输入后再请求，减少请求数 |
| 按钮防重复点击 | 防抖 | 最后一次点击才生效 |
| 滚动位置更新 | 节流 | 需要持续响应，但限制频率 |
| 窗口 resize | 节流 | 持续触发但不需要每帧都处理 |
| 鼠标移动轨迹 | 节流 | 固定采样率即可 |

---

### requestAnimationFrame

`setTimeout` 的延迟不精确，不适合做动画。`requestAnimationFrame`（rAF）会在浏览器**下一次重绘前**执行，天然与屏幕刷新率同步（60fps = 每 16.67ms 一帧）。

```js
// ❌ 用 setTimeout 做动画（帧率不稳，可能撕裂）
let pos = 0
function animate() {
  pos += 2
  el.style.left = pos + 'px'
  setTimeout(animate, 16)  // 不精确
}
animate()

// ✅ 用 requestAnimationFrame
let pos = 0
let animId

function animate(timestamp) {
  pos += 2
  el.style.left = pos + 'px'

  if (pos < 500) {
    animId = requestAnimationFrame(animate)  // 下一帧继续
  }
}

animId = requestAnimationFrame(animate)

// 需要停止时：
cancelAnimationFrame(animId)
```

**rAF 做节流（最高精度）：**

```js
// 用 rAF 节流 scroll：每帧最多执行一次，比 throttle(fn, 16) 更精确
function rafThrottle(fn) {
  let pending = false
  return function(...args) {
    if (pending) return
    pending = true
    requestAnimationFrame(() => {
      fn.apply(this, args)
      pending = false
    })
  }
}

window.addEventListener('scroll', rafThrottle(() => {
  updateUI()
}))
```

---

### requestIdleCallback

`requestAnimationFrame` 是"下一帧执行"，`requestIdleCallback` 是"**浏览器空闲时执行**"，适合做低优先级的后台工作（数据上报、预计算等），不影响主线程响应。

```js
// 浏览器空闲时执行，deadline.timeRemaining() 是剩余空闲时间
requestIdleCallback((deadline) => {
  // 有空闲时间且还有任务
  while (deadline.timeRemaining() > 0 && tasks.length > 0) {
    const task = tasks.shift()
    task()  // 执行一个任务
  }

  // 还有剩余任务，等下次空闲再继续
  if (tasks.length > 0) {
    requestIdleCallback(processIdleTasks)
  }
}, { timeout: 2000 })  // 最长等 2s，超时强制执行

// 适合场景：
// - 发送日志/埋点数据
// - 预加载下一页数据
// - 非关键的 DOM 操作
```

---

### Web Workers

JS 是单线程的，但 **Web Workers** 允许在独立线程里跑 JS，不阻塞主线程。适合 CPU 密集型任务（大数据处理、图片压缩、加密等）。

```js
// worker.js（独立文件，在 Worker 线程里跑）
self.onmessage = function(e) {
  const { data, type } = e.data

  if (type === 'SORT') {
    // 大数组排序，不阻塞主线程
    const sorted = data.sort((a, b) => a - b)
    self.postMessage({ type: 'SORT_DONE', result: sorted })
  }
}

// main.js（主线程）
const worker = new Worker('./worker.js')

// 发送数据给 Worker
worker.postMessage({
  type: 'SORT',
  data: new Array(1000000).fill(0).map(() => Math.random())
})

// 接收 Worker 的结果
worker.onmessage = (e) => {
  if (e.data.type === 'SORT_DONE') {
    console.log('排序完成', e.data.result)
  }
}

// 注意：Worker 和主线程通信靠消息传递（postMessage），数据是拷贝传递的
// 大数据可以用 Transferable Objects（转移所有权，零拷贝）
worker.postMessage({ buffer: arrayBuffer }, [arrayBuffer])  // 转移 ArrayBuffer
```

---

### V8 引擎优化

了解 V8 的优化机制，能写出对引擎更友好的代码。

#### 隐藏类（Hidden Classes）

V8 对每个对象生成一个"隐藏类"来描述其结构，实现快速属性访问。**保持对象结构一致**，才能充分利用这个优化：

```js
// ✅ 结构一致：V8 可以为所有 point 共用一个隐藏类
function createPoint(x, y) {
  return { x, y }  // 始终相同的属性顺序
}

// ❌ 动态添加属性：每次添加属性都会生成新的隐藏类，退化为慢速查找
const p = {}
p.x = 1   // 隐藏类 C1
p.y = 2   // 隐藏类 C2（新的！）

// ❌ 属性顺序不一致：产生不同的隐藏类
const a = { x: 1, y: 2 }  // 隐藏类 C1
const b = { y: 2, x: 1 }  // 隐藏类 C2（不同！）
```

#### 避免 deoptimization（去优化）

```js
// V8 会对热点函数做 JIT 优化（假设参数类型固定）
// 如果突然传入不同类型，V8 会"去优化"，性能下降

function add(a, b) { return a + b }

// ✅ 始终传同一种类型，JIT 优化持续有效
add(1, 2)
add(3, 4)
add(5, 6)

// ❌ 混用类型，触发去优化
add(1, 2)
add('a', 'b')  // 触发去优化！之后的调用变慢

// 实际建议：数组里存同一类型的元素（不要混放 number 和 string）
const nums = [1, 2, 3]      // V8 优化为 SMI Array（小整数数组）
nums.push('四')              // 退化为通用数组，速度变慢
```

---

### DOM 操作优化

#### 批量 DOM 操作：DocumentFragment

```js
// ❌ 每次 append 都触发一次重排
const list = document.getElementById('list')
for (let i = 0; i < 1000; i++) {
  const li = document.createElement('li')
  li.textContent = `item ${i}`
  list.appendChild(li)  // 每次都触发重排！
}

// ✅ 用 DocumentFragment 批量操作，只触发一次重排
const fragment = document.createDocumentFragment()
for (let i = 0; i < 1000; i++) {
  const li = document.createElement('li')
  li.textContent = `item ${i}`
  fragment.appendChild(li)  // 操作 fragment，不触发重排
}
list.appendChild(fragment)  // 一次性插入，只触发一次重排
```

#### 读写分离，避免强制同步布局

```js
// 浏览器会把 DOM 写操作批量延迟，但如果写后立刻读，会强制立刻重排

// ❌ 读写交替：每次 offsetWidth 都强制重排
boxes.forEach(box => {
  const width = box.offsetWidth   // 读（强制重排）
  box.style.width = width + 10 + 'px'  // 写
})

// ✅ 先统一读，再统一写
const widths = boxes.map(box => box.offsetWidth)  // 统一读
boxes.forEach((box, i) => {
  box.style.width = widths[i] + 10 + 'px'  // 统一写，只触发一次重排
})
```


---

### 函数性能优化

#### 记忆化（Memoization）

缓存函数的计算结果，相同输入直接返回缓存，避免重复计算：

```js
// 通用 memoize 函数
function memoize(fn) {
  const cache = new Map()
  return function(...args) {
    const key = JSON.stringify(args)
    if (cache.has(key)) return cache.get(key)
    const result = fn.apply(this, args)
    cache.set(key, result)
    return result
  }
}

// 斐波那契（没有缓存：指数级复杂度；有缓存：线性复杂度）
const fib = memoize(function(n) {
  if (n <= 1) return n
  return fib(n - 1) + fib(n - 2)
})

fib(40)  // 瞬间完成
fib(40)  // 直接返回缓存

// 实际项目场景：缓存格式化函数、复杂计算
const formatPrice = memoize((price, currency) => {
  return new Intl.NumberFormat('zh-CN', { style: 'currency', currency }).format(price)
})

formatPrice(1234.5, 'CNY')  // '¥1,234.50'（计算）
formatPrice(1234.5, 'CNY')  // 直接返回缓存
```

#### 函数柯里化（Currying）

把多参数函数转换成一系列单参数函数，实现参数复用：

```js
// 手写 curry
function curry(fn) {
  return function curried(...args) {
    if (args.length >= fn.length) {
      return fn.apply(this, args)  // 参数够了，直接执行
    }
    return function(...moreArgs) {
      return curried.apply(this, [...args, ...moreArgs])  // 继续收集参数
    }
  }
}

// 使用
const add = curry((a, b, c) => a + b + c)

add(1)(2)(3)    // 6（逐个传）
add(1, 2)(3)    // 6（混合传）
add(1)(2, 3)    // 6
add(1, 2, 3)    // 6（一次传完）

// 实际用途：参数复用
const multiply = curry((multiplier, num) => multiplier * num)
const double = multiply(2)   // 固定第一个参数
const triple = multiply(3)

[1, 2, 3].map(double)  // [2, 4, 6]
[1, 2, 3].map(triple)  // [3, 6, 9]
```

---

### 懒加载与代码分割

```js
// 图片懒加载（Intersection Observer API）
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const img = entry.target
      img.src = img.dataset.src  // 进入视口才加载真实图片
      observer.unobserve(img)    // 加载后停止观察
    }
  })
}, {
  rootMargin: '100px'  // 提前 100px 开始加载
})

// 给所有懒加载图片加上观察
document.querySelectorAll('img[data-src]').forEach(img => {
  observer.observe(img)
})

// HTML 写法：
// <img data-src="real-image.jpg" src="placeholder.jpg" />
```

```js
// 代码分割：按需加载大型模块
// 场景：编辑器、图表库、PDF 解析等

class Editor {
  constructor() {
    this.instance = null
  }

  async init() {
    // 只在用户真正需要时才加载
    const { default: MonacoEditor } = await import('./monaco-editor')
    this.instance = new MonacoEditor(document.getElementById('editor'))
  }
}

// 路由级代码分割（React/Vue）
// 每个路由单独打一个 chunk，首屏只加载当前路由的代码
const routes = [
  { path: '/', component: () => import('./pages/Home') },
  { path: '/dashboard', component: () => import('./pages/Dashboard') },
  { path: '/settings', component: () => import('./pages/Settings') },
]
```

---

### 长任务拆分（Time Slicing）

当必须在主线程做大量计算时，可以把任务分成小片，每片之间让出主线程，保持 UI 响应：

```js
// 用 setTimeout 实现任务分片
function processInChunks(items, processOne, chunkSize = 100) {
  let index = 0

  function processChunk() {
    const end = Math.min(index + chunkSize, items.length)

    // 处理一批
    while (index < end) {
      processOne(items[index])
      index++
    }

    // 还有剩余，让出主线程后继续
    if (index < items.length) {
      setTimeout(processChunk, 0)  // 放入宏任务队列，让 UI 更新插队
    }
  }

  processChunk()
}

// 用法：处理 10 万条数据，每批 100 条，不卡 UI
processInChunks(bigArray, (item) => {
  // 处理单条数据
}, 100)
```

```js
// 更现代的方式：使用 scheduler（Chrome 实验性 API）
// 或 requestIdleCallback + 任务队列

class TaskQueue {
  constructor() {
    this.queue = []
    this.running = false
  }

  add(task) {
    this.queue.push(task)
    if (!this.running) this.run()
  }

  run() {
    this.running = true
    requestIdleCallback((deadline) => {
      while (deadline.timeRemaining() > 1 && this.queue.length > 0) {
        const task = this.queue.shift()
        task()
      }
      if (this.queue.length > 0) {
        this.run()  // 还有任务，等下次空闲
      } else {
        this.running = false
      }
    })
  }
}

const queue = new TaskQueue()
bigArray.forEach(item => queue.add(() => processItem(item)))
```

---

### 性能测量

```js
// Performance API：精确测量代码执行时间
performance.mark('start')

// 要测量的操作
doSomethingExpensive()

performance.mark('end')
performance.measure('my-operation', 'start', 'end')

const [measure] = performance.getEntriesByName('my-operation')
console.log(`耗时：${measure.duration.toFixed(2)}ms`)

// console.time 的简单方式
console.time('sort')
bigArray.sort()
console.timeEnd('sort')  // 输出：sort: 45.23ms

// 内存使用（Chrome DevTools）
console.log(performance.memory)
// {
//   usedJSHeapSize: 12345678,    // 当前使用的堆内存
//   totalJSHeapSize: 23456789,   // 分配的堆内存
//   jsHeapSizeLimit: 2172649472  // 堆内存上限
// }
```

> **性能优化的原则**：不要过早优化。先用 DevTools Performance 面板找到真正的瓶颈（长任务、频繁重排、大量 GC），再针对性地优化。优化前后都要测量，用数据说话。


---

## 十、Chrome DevTools 实战

> DevTools 是前端开发的核武器。很多人只会用 console.log，但 DevTools 能做的远不止这些。

### Console 面板

#### console 的全部用法

```js
// 基础输出
console.log('普通信息')
console.info('提示信息')     // 和 log 一样，部分环境有蓝色图标
console.warn('警告')         // 黄色警告
console.error('错误')        // 红色错误，带堆栈信息

// 格式化输出
console.log('%s 有 %d 个用户', '系统', 1000)  // 字符串占位符
console.log('%c红色加粗', 'color: red; font-weight: bold')  // CSS 样式

// 对象/数组：推荐用 console.log 而不是字符串拼接
console.log({ name: '张三', age: 25 })   // 可展开查看
console.log([1, 2, 3])                   // 可展开查看
console.table([{ name: '张三' }, { name: '李四' }])  // 表格形式，非常好看

// 分组折叠（适合输出大量信息时）
console.group('用户模块')
  console.log('用户名：张三')
  console.log('权限：admin')
console.groupEnd()

console.groupCollapsed('详细日志')  // 默认折叠
  console.log('很多很多内容...')
console.groupEnd()

// 计数
console.count('点击')  // 点击: 1
console.count('点击')  // 点击: 2
console.countReset('点击')

// 断言（条件为 false 时才输出）
console.assert(user.age > 0, '年龄必须大于 0', user)

// 输出堆栈（调试用，看函数调用链）
console.trace('调用来源')

// 计时（上一章提过）
console.time('操作名')
doSomething()
console.timeEnd('操作名')  // 操作名: 12.34ms
console.timeLog('操作名')  // 中途查看已过去的时间，不停止计时
```

#### Console 面板的实用技巧

```js
// 1. $0 ~ $4：最近检查过的 DOM 元素
// 在 Elements 面板点击一个元素，然后在 Console 里：
$0         // 刚才选中的元素
$0.style.color = 'red'  // 直接操作！

// 2. $()  $$()：Console 里的 querySelector 快捷方式
$('h1')          // document.querySelector('h1')
$$('.btn')       // document.querySelectorAll('.btn')，返回数组

// 3. $_：上一个表达式的结果
2 + 2   // 4
$_ + 1  // 5

// 4. copy()：把对象复制到剪贴板
copy(JSON.parse(localStorage.getItem('userData')))  // 直接复制 JSON

// 5. monitor() / unmonitor()：监听函数调用（DevTools 内置）
monitor(someFunction)    // 每次调用都会打印参数
unmonitor(someFunction)

// 6. 实时表达式（点击 DevTools Console 面板的眼睛图标）
// 输入表达式后，它会持续实时显示当前值，不需要手动刷新
// 例：document.querySelectorAll('.item').length  →  实时显示列表数量
```

---

### Sources 面板（断点调试）

Console.log 是最原始的调试方式，断点调试效率高 10 倍。

#### 断点类型

```
1. 行断点：点击代码行号，执行到这行时暂停
2. 条件断点：右键行号 → Add conditional breakpoint
   例：i === 50（只在 i 等于 50 时才暂停）
3. logpoint：右键 → Add logpoint（不暂停，只打印，等于无侵入的 console.log）
4. 异常断点：勾选 "Pause on exceptions"（遇到错误时自动暂停）
5. DOM 断点：在 Elements 面板右键元素 → Break on（DOM 变化时暂停）
```

#### 断点调试快捷键

```
F8 / Cmd+\      →  继续执行（Resume）
F10 / Cmd+'     →  单步跳过（Step over，不进入函数内部）
F11 / Cmd+;     →  单步进入（Step into，进入函数）
Shift+F11       →  单步跳出（Step out，跳出当前函数）

暂停时可以：
- 鼠标悬停变量，查看当前值
- 在 Scope 面板查看所有作用域变量
- 在 Watch 面板添加自定义表达式
- 在 Console 里执行代码（在当前作用域下！）
```

#### debugger 语句

```js
// 在代码里写 debugger，执行到这里会自动暂停（需要 DevTools 打开）
function calculateTotal(items) {
  debugger  // ← 暂停在这里，检查 items 的值
  return items.reduce((sum, item) => sum + item.price, 0)
}

// 条件 debugger
if (someCondition) {
  debugger  // 只在特定条件下暂停
}
```

---

### Network 面板

```
常用功能：
1. 筛选请求类型：XHR/Fetch（API 请求）、JS、CSS、Img、WS（WebSocket）
2. 搜索内容：Cmd+F 搜索响应体里的关键字
3. 查看请求详情：Headers（请求头/响应头）、Payload（请求体）、Response（响应体）、Timing（各阶段耗时）

Timing 各阶段解读：
  Queueing：排队等待（受浏览器并发限制，HTTP/1.1 同域最多 6 个）
  Stalled：请求被暂停（代理、SSL 等原因）
  DNS Lookup：DNS 解析时间
  Initial connection：建立 TCP 连接
  SSL：TLS 握手
  Request sent：发送请求
  Waiting (TTFB)：等待服务器第一个字节（Time To First Byte）← 服务器性能指标
  Content Download：下载响应体

实用技巧：
  - 勾选 Preserve log：页面跳转后保留请求记录
  - 勾选 Disable cache：禁用缓存，确保每次都拿最新资源
  - 右键请求 → Copy as cURL：复制为 curl 命令，可以在终端重放请求
  - Throttling：模拟慢速网络（3G/4G）测试真实用户体验
```

---

### Performance 面板

Performance 面板用来分析页面性能，找出卡顿、长任务的根源。

```
使用流程：
1. 点击录制（圆圈按钮）
2. 执行要分析的操作（如滚动、点击、加载等）
3. 点击停止，等待分析完成
4. 查看结果
```

**面板各区域含义：**

```
Summary（汇总）：
  Scripting    → JS 执行时间（蓝色）
  Rendering    → 样式计算、布局时间（紫色）
  Painting     → 绘制时间（绿色）
  Idle         → 空闲时间

重点关注区域：
  Main Thread Timeline：主线程活动，红色三角 = 长任务（超过 50ms）
  Flame Chart（火焰图）：函数调用栈，越宽 = 耗时越长
  Bottom-Up：按耗时排序，直接找最慢的函数
  Call Tree：按调用层级展示，找哪里调用了慢函数
```

```
定位性能问题的步骤：
1. 在 Summary 里看哪类操作占比高（Scripting/Rendering？）
2. 在 Main 里找红色三角（Long Tasks > 50ms）
3. 展开长任务，在火焰图里找最宽的函数
4. 点击函数，跳到 Sources 面板看具体代码
5. 优化后重新录制，对比前后数据
```

---

### Memory 面板

用来排查内存泄漏。

```
三种快照类型：

1. Heap Snapshot（堆快照）
   - 拍一张内存快照，看当前内存里有哪些对象
   - 操作：操作页面 → 拍快照 → 再操作 → 拍快照
   - 对比两次快照，找 "Added" 里新增的对象（泄漏的对象）

2. Allocation instrumentation on timeline（分配时间线）
   - 录制一段时间的内存分配情况
   - 蓝色竖条 = 内存分配，不消失的蓝条 = 可能泄漏

3. Allocation sampling（分配采样）
   - 性能开销最小，适合长时间录制
   - 看哪些函数分配了最多内存
```

```js
// 配合 Memory 面板查内存泄漏的工作流：

// 1. 打开 Memory 面板，拍第一张快照（baseline）
// 2. 反复执行可疑操作（如打开/关闭弹窗 10 次）
// 3. 手动触发 GC（面板里有垃圾桶按钮）
// 4. 拍第二张快照
// 5. 选 "Comparison"（对比模式），看 Delta（增量）
// 6. 找 Delta 为正的对象类型（说明这些对象没被回收）
// 7. 点击展开，查看谁持有这些对象的引用 → 找到泄漏源
```

---

### Application 面板

```
主要功能：
  Storage → 查看和修改所有存储
    Local Storage    ← 永久存储，关闭浏览器不消失
    Session Storage  ← 会话存储，关闭标签页消失
    Cookies          ← 可以看到 HttpOnly 的 cookie（但值是 ***）
    IndexedDB        ← 结构化大量数据
    Cache Storage    ← Service Worker 缓存的资源

  Service Workers → 查看 SW 状态，手动触发更新、推送、同步
  Manifest → PWA 配置
  Frames → 当前页面加载的所有资源

实用技巧：
  - 双击 Local Storage 的值可以直接编辑，方便调试
  - 右键可以删除单条记录或清空所有存储
  - "Clear site data" 一键清除所有存储（包括 cookie、cache）
```

