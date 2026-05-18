# Java 全栈精讲（前端转后端版）

> 你已经会 JavaScript/TypeScript 和 Vue，这份文档用你已有的知识做锚点，帮你最快理解 Java 后端开发。

---

## 一、从前端到 Java：思维转换

### 两个世界的对比

| | JavaScript / 前端 | Java / 后端 |
|---|---|---|
| 类型系统 | 动态类型（运行时才知道类型） | **静态类型**（编译时就检查类型） |
| 执行方式 | 解释执行（V8 引擎边解析边跑） | **先编译再执行**（.java → .class → JVM 运行） |
| 线程模型 | 单线程 + 事件循环（异步不阻塞） | **多线程**（每个请求一个线程） |
| 包管理 | npm / pnpm + package.json | **Maven** + pom.xml |
| 运行环境 | Node.js / 浏览器 | **JVM**（Java 虚拟机） |
| 入口文件 | index.js / main.ts | **main 方法**（public static void main） |
| 模块系统 | import/export（ESM） | **import + 包名**（com.example.xxx） |
| 空值 | null / undefined | **只有 null**（没有 undefined） |
| 代码组织 | 文件随便放 | **一个文件一个类，类名 = 文件名** |

### 最大的思维差异

**前端**：数据流过函数，函数是一等公民，写法灵活

```js
// JS：函数可以赋值给变量、作为参数传递
const greet = (name) => `你好，${name}`
const users = ['张三', '李四']
const result = users.map(greet)
```

**后端**：一切皆对象，代码必须写在类里面

```java
// Java：函数不能独立存在，必须属于某个类
public class UserService {
    public String greet(String name) {
        return "你好，" + name;
    }
}

// 使用
UserService service = new UserService();
service.greet("张三");
```

> **Java 没有独立的函数，所有代码都必须写在 class 里。这是 Java 和 JS 最大的区别。**

### 编译 vs 解释

```
JavaScript：
  hello.js → Node.js / 浏览器 直接执行（解释执行）
  写完就能跑，报错在运行时才发现

Java：
  Hello.java → javac 编译 → Hello.class（字节码）→ JVM 执行
  编译阶段就能发现类型错误、语法错误
  类似于 TypeScript 的 tsc 编译，但更严格
```

### 类型系统对比

```js
// JS：变量可以随便换类型
let a = 1
a = '字符串'    // ✅ 没问题
a = [1, 2, 3]   // ✅ 没问题
```

```java
// Java：变量声明时就确定类型，不能变
int a = 1;
a = "字符串";    // ❌ 编译报错！int 类型不能赋字符串
String b = "hello";
b = 123;         // ❌ 编译报错！

// 类似 TypeScript 的严格模式，但比 TS 更严（TS 还有 any）
```

> **Java 没有 any 类型。每个变量、每个参数、每个返回值都必须明确类型。一开始觉得烦，但写多了会发现编译器帮你挡掉了 90% 的 bug。**

### 异步模型对比

```js
// JS：单线程 + 异步（Promise / async-await）
// 一个线程处理所有请求，I/O 操作交给事件循环
async function getUser(id) {
    const res = await fetch(`/api/users/${id}`)
    return res.json()
}
```

```java
// Java：多线程 + 同步阻塞
// 每个 HTTP 请求分配一个线程，线程内部是同步的
public User getUser(Long id) {
    // 这行代码会阻塞当前线程，等数据库返回
    // 但不影响其他请求，因为它们在别的线程
    return userMapper.selectById(id);
}
```

> **你写 Java 后端不需要写 async/await**。每个请求一个线程，代码从上往下同步执行就行。Spring Boot 帮你管理线程池。

---

## 二、开发环境搭建

### 安装 JDK

```bash
# macOS（Homebrew）
brew install openjdk@17

# 验证
java -version    # java version "17.x.x"
javac -version   # javac 17.x.x
```

> **用 JDK 17**（LTS 长期支持版），不要用 JDK 8（太老）也不要用最新版（不稳定）。

### 安装 IntelliJ IDEA

- **下载**：https://www.jetbrains.com/idea/（Community 免费版就够用）
- **必装插件**：Lombok（减少样板代码）
- IDEA 之于 Java = VSCode 之于前端，但 IDEA 更重（因为 Java 项目更复杂）

### 第一个项目：Spring Initializr

```
打开 https://start.spring.io/

选择：
  - Project: Maven
  - Language: Java
  - Spring Boot: 3.2.x（最新稳定版）
  - Java: 17
  - Dependencies: Spring Web

点击 Generate → 下载 zip → 解压 → IDEA 打开
```

### Hello World

```java
// src/main/java/com/example/demo/DemoApplication.java
// 这个文件项目创建时自动生成

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

```java
// 新建文件：src/main/java/com/example/demo/controller/HelloController.java

@RestController    // 告诉 Spring：这个类处理 HTTP 请求
public class HelloController {

    @GetMapping("/hello")    // GET /hello
    public String hello() {
        return "Hello, Java!";
    }
}
```

```bash
# 运行（在 IDEA 中点绿色三角，或命令行）
./mvnw spring-boot:run

# 浏览器访问
http://localhost:8080/hello
# 输出：Hello, Java!
```

> **对比前端**：`npm run dev` 启动 Vite 开发服务器 = `./mvnw spring-boot:run` 启动 Spring Boot。`router.get('/hello')` = `@GetMapping("/hello")`。

---

## 三、Java 基础语法（对照 JS）

### 变量与类型

```java
// JS：let/const，不声明类型
// let name = '张三'
// const age = 25

// Java：必须声明类型
String name = "张三";        // 注意：Java 字符串用双引号，单引号是 char
int age = 25;               // 整数
long id = 10000000000L;     // 大整数（加 L 后缀）
double price = 9.99;        // 浮点数
boolean isVip = true;       // 布尔值
char grade = 'A';           // 单个字符（单引号）

// Java 10+ 有 var（类似 JS 的 let，自动推断类型）
var count = 0;               // 编译器推断为 int
var list = new ArrayList<>(); // 推断为 ArrayList
// 但只能用在局部变量，方法参数和返回值不能用 var
```

### 基本类型 vs 包装类型

```java
// Java 有两套类型系统，这是 JS 没有的概念

// 基本类型（小写开头，存值本身，性能好）
int a = 1;
double b = 1.5;
boolean c = true;

// 包装类型（大写开头，是对象，可以为 null）
Integer a2 = 1;          // int 的包装类
Double b2 = 1.5;         // double 的包装类
Boolean c2 = true;       // boolean 的包装类

// 为什么需要包装类型？
// 1. 集合只能放对象，不能放基本类型
List<Integer> list = new ArrayList<>();  // ✅
// List<int> list = new ArrayList<>();   // ❌ 编译报错

// 2. 包装类型可以为 null（表示"没有值"）
Integer score = null;    // ✅ 表示"成绩未录入"
// int score2 = null;    // ❌ 基本类型不能为 null

// 自动装箱/拆箱（Java 自动转换，不用手动）
Integer x = 10;          // 自动装箱：int → Integer
int y = x;               // 自动拆箱：Integer → int
```

> **实际开发中**：方法参数和实体类字段用**包装类型**（Integer、Long、Boolean），因为数据库字段可能为 null。局部变量用基本类型（int、long）。

### 字符串

```java
// JS: 模板字符串 `你好，${name}`
// Java: 没有模板字符串，用 + 拼接或 String.format

String name = "张三";
int age = 25;

// 拼接
String msg1 = "你好，" + name + "，你" + age + "岁";

// String.format（类似 C 的 printf）
String msg2 = String.format("你好，%s，你%d岁", name, age);

// 字符串比较——JS 用 ===，Java 用 .equals()
String a = new String("hello");
String b = new String("hello");
a == b;           // false！比较的是引用地址（类似 JS 的对象比较）
a.equals(b);      // true！比较的是内容

// 常用方法
"hello".length();            // 5
"hello".substring(1, 3);     // "el"（左闭右开）
"hello".contains("ell");     // true
"hello".replace("l", "L");   // "heLLo"
"a,b,c".split(",");          // ["a", "b", "c"]
"  hello  ".trim();          // "hello"
"hello".toUpperCase();       // "HELLO"
"hello".isEmpty();           // false
"".isEmpty();                // true
```

> **铁律：Java 字符串比较永远用 `.equals()`，永远不用 `==`**

### 数组与集合

```java
// JS 的数组 = Java 的 List（长度可变，最常用）
// JS: const list = ['张三', '李四']
// Java:
List<String> list = new ArrayList<>();
list.add("张三");
list.add("李四");
list.get(0);            // "张三"（JS 用 list[0]）
list.size();            // 2（JS 用 list.length）
list.remove(0);         // 删除第一个
list.contains("张三");   // true（JS 用 list.includes()）

// 快捷创建
List<String> names = List.of("张三", "李四", "王五");  // 不可变列表
List<String> names2 = new ArrayList<>(List.of("张三", "李四"));  // 可变列表

// JS 的对象/Map = Java 的 Map
// JS: const map = { '张三': 90, '李四': 85 }
// Java:
Map<String, Integer> scoreMap = new HashMap<>();
scoreMap.put("张三", 90);         // JS: map['张三'] = 90
scoreMap.get("张三");             // 90（JS: map['张三']）
scoreMap.getOrDefault("王五", 0); // 0（不存在返回默认值）
scoreMap.containsKey("张三");     // true
scoreMap.remove("张三");

// 遍历 Map
for (Map.Entry<String, Integer> entry : scoreMap.entrySet()) {
    System.out.println(entry.getKey() + ": " + entry.getValue());
}
// JS 等价：Object.entries(map).forEach(([key, value]) => ...)

// Set——去重（JS 也有 Set）
Set<String> set = new HashSet<>(list);
set.add("张三");
set.contains("张三");             // true
```

> **日常开发集合三件套：`ArrayList`（列表）、`HashMap`（键值对）、`HashSet`（去重）**

### 流程控制

```java
// 和 JS 几乎一样，唯一区别：Java 的 switch 支持箭头语法（Java 14+）

// if-else（完全一样）
if (score >= 90) {
    grade = 'A';
} else if (score >= 60) {
    grade = 'B';
} else {
    grade = 'C';
}

// for 循环（完全一样）
for (int i = 0; i < 10; i++) { ... }

// 增强 for（类似 JS 的 for...of）
for (String item : list) {
    System.out.println(item);
}
// JS 等价：for (const item of list) { console.log(item) }

// switch（Java 14+ 箭头语法）
switch (status) {
    case "ACTIVE" -> System.out.println("活跃");
    case "INACTIVE" -> System.out.println("停用");
    default -> System.out.println("未知");
}
```

### 方法（函数）

```java
// JS: function add(a, b) { return a + b }
// 或: const add = (a, b) => a + b

// Java: 必须声明返回类型和参数类型
public int add(int a, int b) {
    return a + b;
}

// 没有返回值用 void
public void log(String msg) {
    System.out.println(msg);
}

// 可变参数（类似 JS 的 ...args）
public int sum(int... nums) {
    int total = 0;
    for (int n : nums) total += n;
    return total;
}
sum(1, 2, 3);  // 6
```

### 异常处理

```java
// JS: try/catch/finally
// Java: 完全一样，但多了"受检异常"概念

try {
    int result = 10 / 0;
} catch (ArithmeticException e) {
    System.out.println("错误：" + e.getMessage());
} finally {
    System.out.println("一定会执行");
}

// 自定义业务异常（开发中最常用）
public class BusinessException extends RuntimeException {
    private int code;
    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }
    public int getCode() { return code; }
}

// 使用
throw new BusinessException(400, "用户不存在");
// 类似 JS 的：throw new Error('用户不存在')
```

---

## 四、面向对象——Java 的核心

> JS 的 class 只是语法糖（底层还是原型链），Java 的 class 是**真正的类**，是代码组织的基本单位。

### 类与对象

```java
// 定义类（一个文件只能有一个 public 类，类名 = 文件名）
public class User {
    // 字段（属性）——都是 private（外部不能直接访问）
    private String name;
    private int age;

    // 构造方法（JS 里叫 constructor）
    public User(String name, int age) {
        this.name = name;    // this 和 JS 一样
        this.age = age;
    }

    // Getter / Setter（Java 的约定：私有字段 + 公开方法）
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }

    // 普通方法
    public String greet() {
        return "你好，我是" + name;
    }
}

// 使用
User user = new User("张三", 25);   // new 和 JS 一样
user.getName();    // "张三"
user.greet();      // "你好，我是张三"
```

> **为什么这么啰嗦？** 实际开发中用 **Lombok**（@Data 注解）自动生成 getter/setter/构造方法，不用手写。后面会讲。

### 继承

```java
// JS: class Dog extends Animal { ... }
// Java: 完全一样的语法

public class Animal {
    protected String name;     // protected：子类可以访问

    public Animal(String name) {
        this.name = name;
    }

    public void eat() {
        System.out.println(name + "在吃东西");
    }
}

public class Dog extends Animal {
    public Dog(String name) {
        super(name);           // 调用父类构造方法（JS 也是 super()）
    }

    @Override                  // 重写标记（JS 没有这个注解，但行为一样）
    public void eat() {
        System.out.println(name + "在啃骨头");
    }
}
```

> **Java 只能单继承**（一个类只能 extends 一个父类）。但可以实现多个接口。

### 接口

```java
// 接口 = 定义"能做什么"（能力），不管"怎么做"
// 类似 TypeScript 的 interface，但 Java 的接口可以有默认实现

public interface Payable {
    boolean pay(double amount);                   // 抽象方法：只声明，不实现
    default void refund(double amount) {          // 默认方法（Java 8+）：有默认实现
        System.out.println("退款：" + amount);
    }
}

// 实现接口（implements）
public class AlipayService implements Payable {
    @Override
    public boolean pay(double amount) {
        // 调用支付宝 SDK...
        return true;
    }
    // refund 不写就用默认实现
}

// 多态：用接口类型接收不同实现
Payable payment = new AlipayService();
payment.pay(99.9);     // 调用支付宝的实现
payment.refund(99.9);  // 调用默认实现
```

> **实际开发中接口用得比继承多得多**。Spring 的 Service 层就是「接口 + 实现类」的模式：`UserService`（接口）+ `UserServiceImpl`（实现类）。

### 访问修饰符

| 修饰符 | 同类 | 同包 | 子类 | 所有 |
|---|---|---|---|---|
| private | ✅ | ❌ | ❌ | ❌ |
| (默认) | ✅ | ✅ | ❌ | ❌ |
| protected | ✅ | ✅ | ✅ | ❌ |
| public | ✅ | ✅ | ✅ | ✅ |

> **记忆**：字段 private，方法 public，子类访问用 protected。

### 枚举

```java
// JS 没有枚举（TS 有），Java 的枚举比 TS 强大得多

public enum OrderStatus {
    PENDING(0, "待支付"),
    PAID(1, "已支付"),
    SHIPPED(2, "已发货"),
    CANCELLED(4, "已取消");

    private final int code;
    private final String desc;

    OrderStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    public int getCode() { return code; }
    public String getDesc() { return desc; }
}

// 使用
OrderStatus status = OrderStatus.PAID;
status.getCode();           // 1
status.getDesc();           // "已支付"
```

### Lombok——消灭样板代码

```java
// 不用 Lombok：手写 getter/setter/构造方法/toString（几十行）
// 用 Lombok：一个注解搞定

@Data                    // 自动生成 getter/setter/toString/equals/hashCode
@AllArgsConstructor      // 全参构造
@NoArgsConstructor       // 无参构造
@Builder                 // 建造者模式
public class User {
    private Long id;
    private String username;
    private String name;
    private Integer age;
}

// 使用 Builder（类似 JS 的对象字面量）
User user = User.builder()
    .username("zhangsan")
    .name("张三")
    .age(25)
    .build();

// 日志注解
@Slf4j                   // 自动生成 log 对象
@Service
public class UserService {
    public void doSomething() {
        log.info("用户操作: {}", username);   // 类似 console.log
        log.error("出错了", exception);       // 类似 console.error
    }
}
```

> **Lombok 是 Java 开发的标配**，每个项目都会用。`@Data` + `@Slf4j` 是最常用的两个注解。

---

## 五、Java 8+ 现代语法

> Java 8 是分水岭。Lambda 和 Stream 让 Java 有了类似 JS 数组方法（map/filter/reduce）的能力。

### Lambda 表达式

```java
// JS 的箭头函数 = Java 的 Lambda

// JS: const greet = (name) => console.log('你好，' + name)
// Java:
Consumer<String> greet = (name) -> System.out.println("你好，" + name);

// 集合排序
List<User> users = getUsers();
// JS: users.sort((a, b) => a.age - b.age)
// Java:
users.sort((u1, u2) -> u1.getAge() - u2.getAge());
// 更简洁的写法（方法引用）
users.sort(Comparator.comparing(User::getAge));
```

### Stream API——集合处理神器

```java
// Stream 就是 Java 版的 JS 数组方法链

List<User> users = List.of(
    new User("张三", 25, true),
    new User("李四", 17, false),
    new User("王五", 30, true)
);

// filter = JS 的 .filter()
List<User> adults = users.stream()
    .filter(u -> u.getAge() >= 18)
    .collect(Collectors.toList());

// map = JS 的 .map()
List<String> names = users.stream()
    .map(User::getName)
    .collect(Collectors.toList());
// ["张三", "李四", "王五"]

// find = JS 的 .find()
User firstVip = users.stream()
    .filter(User::isVip)
    .findFirst()
    .orElse(null);

// some/every = JS 的 .some() / .every()
boolean hasMinor = users.stream().anyMatch(u -> u.getAge() < 18);
boolean allVip = users.stream().allMatch(User::isVip);

// 链式操作 = JS 的链式调用
List<String> result = users.stream()
    .filter(u -> u.isVip() && u.getAge() >= 18)
    .map(User::getName)
    .sorted()
    .collect(Collectors.toList());
// ["张三", "王五"]

// 转 Map（最常用：ID → 对象）
Map<Long, User> userMap = users.stream()
    .collect(Collectors.toMap(User::getId, u -> u));
// JS 等价：Object.fromEntries(users.map(u => [u.id, u]))

// 分组
Map<Boolean, List<User>> byVip = users.stream()
    .collect(Collectors.partitioningBy(User::isVip));
```

> **Stream 三步走**：`.stream()` → 中间操作（filter/map/sorted）→ 终结操作（collect/forEach/findFirst）

### Optional——防空指针

```java
// JS：obj?.profile?.city ?? '未知'
// Java：Optional 链式调用

Optional.ofNullable(user)
    .map(User::getProfile)
    .map(Profile::getCity)
    .orElse("未知城市");

// 常用方法
Optional<User> opt = Optional.ofNullable(getUser());
opt.isPresent();                    // 是否有值
opt.orElse(defaultUser);            // 为空用默认值
opt.orElseThrow(() -> new BusinessException(404, "用户不存在"));
opt.ifPresent(u -> log.info(u.getName()));  // 有值才执行
```

---

## 六、Maven——项目构建与依赖管理

> Maven 之于 Java = npm 之于 Node.js。pom.xml = package.json。

### 对照表

| npm | Maven |
|---|---|
| package.json | pom.xml |
| node_modules | ~/.m2/repository（全局缓存） |
| npm install | mvn install |
| npm run build | mvn package |
| npm run dev | mvn spring-boot:run |
| dependencies | \<dependencies\> |
| devDependencies | \<scope\>test\</scope\> |

### 项目结构

```
my-project/
├── pom.xml                          # 项目配置
├── src/
│   ├── main/
│   │   ├── java/                    # Java 源码
│   │   │   └── com/example/demo/
│   │   │       ├── DemoApplication.java
│   │   │       ├── controller/      # 控制层
│   │   │       ├── service/         # 业务层
│   │   │       ├── mapper/          # 数据访问层
│   │   │       └── entity/          # 实体类
│   │   └── resources/
│   │       ├── application.yml      # 配置文件
│   │       └── mapper/              # MyBatis XML
│   └── test/                        # 测试代码
```

### 常用命令

```bash
mvn clean              # 清理构建产物（类似 rm -rf dist）
mvn compile            # 编译
mvn test               # 运行测试
mvn package            # 打包成 jar
mvn clean package -DskipTests   # 打包跳过测试（部署时最常用）
```

### pom.xml 核心结构

```xml
<!-- 继承 Spring Boot 父项目（自动管理依赖版本，不用手动指定版本号） -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.5</version>
</parent>

<!-- 项目坐标（唯一标识） -->
<groupId>com.example</groupId>      <!-- 类似 npm 的 scope -->
<artifactId>demo</artifactId>       <!-- 类似 npm 的包名 -->
<version>1.0.0</version>

<!-- 依赖 -->
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
        <!-- 不写版本号，由 parent 自动管理 -->
    </dependency>
</dependencies>
```

> **原则：版本号交给 Spring Boot Parent 管理**，除非它没覆盖（比如 MyBatis-Plus 需要手动指定版本）。

---

## 七、MySQL 基础

> 前端不写 SQL，这块是空白。不懂 SQL 就没法写后端，先学这章再学 MyBatis-Plus。

### 建库建表

```sql
-- 创建数据库
CREATE DATABASE mydb DEFAULT CHARSET utf8mb4;
USE mydb;

-- 创建用户表
CREATE TABLE sys_user (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    username    VARCHAR(50)  NOT NULL COMMENT '用户名',
    password    VARCHAR(100) NOT NULL COMMENT '密码',
    name        VARCHAR(50)  DEFAULT NULL COMMENT '姓名',
    age         INT          DEFAULT NULL COMMENT '年龄',
    email       VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    status      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态 0禁用 1正常',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted     TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除 0未删 1已删',
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username)  -- 唯一索引
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

### CRUD

```sql
-- 插入
INSERT INTO sys_user (username, password, name, age) VALUES ('zhangsan', '123456', '张三', 25);

-- 查询
SELECT * FROM sys_user WHERE status = 1;
SELECT id, name, age FROM sys_user WHERE age >= 18 ORDER BY create_time DESC LIMIT 10;

-- 模糊查询
SELECT * FROM sys_user WHERE name LIKE '%张%';

-- 更新
UPDATE sys_user SET name = '李四', age = 30 WHERE id = 1;

-- 删除（实际开发用逻辑删除）
UPDATE sys_user SET deleted = 1 WHERE id = 1;
```

### 多表查询（JOIN）

```sql
-- 假设还有一张部门表 sys_dept
-- 查询用户及其所属部门名称
SELECT u.name, u.age, d.name AS dept_name
FROM sys_user u
LEFT JOIN sys_dept d ON u.dept_id = d.id
WHERE u.deleted = 0;

-- LEFT JOIN：左表全部保留，右表没匹配到的显示 NULL
-- INNER JOIN：只保留两边都有的
```

### 索引

```sql
-- 索引 = 书的目录，加快查询速度
-- 没索引：全表扫描（翻遍整本书）
-- 有索引：直接定位（看目录翻到指定页）

-- 创建索引
CREATE INDEX idx_name ON sys_user(name);           -- 普通索引
CREATE UNIQUE INDEX uk_email ON sys_user(email);   -- 唯一索引

-- 什么时候加索引？
-- WHERE 后面经常查的字段
-- JOIN 的关联字段
-- ORDER BY 的排序字段
-- 但不要加太多，索引占空间且影响写入速度
```

### 事务

```sql
-- 事务 = 一组操作要么全成功，要么全失败
-- 经典场景：转账

START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE user_id = 1;  -- 扣钱
UPDATE account SET balance = balance + 100 WHERE user_id = 2;  -- 加钱
COMMIT;  -- 全部成功才提交

-- 如果中间出错
ROLLBACK;  -- 全部回滚，两个操作都不生效
```

> **Spring Boot 中用 `@Transactional` 注解管理事务，不用手写 SQL 事务。**

---

## 八、Spring 核心原理

> 不懂 Spring 的 IOC 和 AOP，用 Spring Boot 就是照猫画虎。这章是理解后续所有内容的基础。

### IOC（控制反转）——Spring 最核心的概念

```java
// 没有 Spring 时：你自己创建对象
public class OrderService {
    // 自己 new 出依赖
    private UserMapper userMapper = new UserMapper();
    private RedisTemplate redis = new RedisTemplate();
}

// 有 Spring 时：Spring 帮你创建和注入
@Service
public class OrderService {
    // Spring 自动创建并注入这些对象
    private final UserMapper userMapper;
    private final RedisTemplate redis;
    
    // 构造器注入（Spring 看到参数类型，自动从容器里找到对应的对象传进来）
    public OrderService(UserMapper userMapper, RedisTemplate redis) {
        this.userMapper = userMapper;
        this.redis = redis;
    }
}
```

**用前端的话说**：Spring 的 IOC 容器就像一个**全局的依赖注入系统**。你只需要声明"我需要什么"，Spring 自动帮你创建和组装。类似 Vue 的 `provide/inject`，但是自动的。

### Bean——Spring 管理的对象

```java
// 什么是 Bean？就是 Spring 帮你创建并管理的对象
// 被以下注解标记的类，Spring 会自动创建实例并放入 IOC 容器

@Component     // 通用组件
@Service       // 业务层（语义化，功能同 @Component）
@Repository    // 数据层
@Controller    // 控制层
@Configuration // 配置类

// 默认是单例（整个应用只有一个实例），和 Vue 的 Pinia store 一样
```

### 依赖注入的三种方式

```java
// 1. 构造器注入（推荐 ✅）——配合 Lombok
@Service
@RequiredArgsConstructor    // Lombok 自动生成构造方法
public class UserServiceImpl {
    private final UserMapper userMapper;        // final = 不可变
    private final RedisTemplate<String, Object> redis;
}

// 2. 字段注入（不推荐 ❌）
@Service
public class UserServiceImpl {
    @Autowired
    private UserMapper userMapper;   // 隐藏依赖，测试困难
}

// 3. Setter 注入（极少用）
```

> **统一用构造器注入 + `@RequiredArgsConstructor`**。

### AOP（面向切面编程）

```java
// AOP = 在不修改原代码的情况下，给方法加上额外功能
// 类似前端的"拦截器"或"中间件"

// 场景：统计所有接口的耗时
@Aspect         // 声明这是一个切面
@Component
@Slf4j
public class LogAspect {

    // 切点：拦截哪些方法（所有 controller 下的方法）
    @Around("execution(* com.example.demo.controller..*.*(..))")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        String method = joinPoint.getSignature().toShortString();
        long start = System.currentTimeMillis();
        
        Object result = joinPoint.proceed();    // 执行原方法
        
        long cost = System.currentTimeMillis() - start;
        log.info("{} 耗时: {}ms", method, cost);
        return result;
    }
}

// 不用在每个 Controller 方法里写耗时统计代码
// AOP 自动帮你在每个方法前后"插入"计时逻辑
```

> **AOP 常见用途**：日志记录、权限校验、事务管理（@Transactional 就是 AOP 实现的）、接口限流。

### Spring Boot 自动装配

```
你写的代码：
  @Service、@Controller、@Mapper ...

Spring Boot 启动时：
  1. 扫描所有带注解的类 → 创建 Bean 放入 IOC 容器
  2. 根据 pom.xml 的依赖自动配置（引入了 starter-web → 自动配置 Tomcat、JSON 序列化等）
  3. 根据 application.yml 的配置覆盖默认值

这就是"约定大于配置"——你不配置就用默认的，需要时才覆盖
```

---

## 九、Spring Boot 实战

> 有了第八章的 Spring 原理基础，现在看 Spring Boot 的用法就不是死记硬背了。

### 配置文件 application.yml

```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: 123456
  data:
    redis:
      host: localhost
      port: 6379

mybatis-plus:
  configuration:
    map-underscore-to-camel-case: true   # 数据库下划线 → Java 驼峰（create_time → createTime）
```

> **类比前端**：application.yml = .env 文件 + vite.config.js 的合体。

### 分层架构

```
controller/     → 接收 HTTP 请求，调用 Service          （类似前端的路由处理函数）
service/        → 业务逻辑                              （类似前端的 composable/hook）
mapper/         → 数据库操作                            （类似前端调 API 的 request 层）
entity/         → 数据库表对应的类                       （类似前端的 interface/type）
dto/            → 接收前端传来的参数                      （类似前端的请求参数类型）
vo/             → 返回给前端的数据                        （类似前端的响应数据类型）
config/         → 配置类
common/         → 公共工具（统一响应、全局异常处理）
```

### 统一响应 + 全局异常处理

```java
// 统一响应类（前端 axios 拦截器里判断的就是这个格式）
@Data
public class Result<T> {
    private int code;
    private String message;
    private T data;

    public static <T> Result<T> success(T data) {
        Result<T> r = new Result<>();
        r.setCode(200);
        r.setMessage("success");
        r.setData(data);
        return r;
    }
    public static <T> Result<T> error(int code, String message) {
        Result<T> r = new Result<>();
        r.setCode(code);
        r.setMessage(message);
        return r;
    }
}

// 全局异常处理（一个地方兜底所有异常，不用每个接口 try-catch）
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusiness(BusinessException e) {
        return Result.error(e.getCode(), e.getMessage());
    }
    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception e) {
        return Result.error(500, "服务器内部错误");
    }
}
```

### Controller（REST API）

```java
// 类比 Express/Koa 的路由

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // GET /api/users/1
    @GetMapping("/{id}")
    public Result<UserVO> getById(@PathVariable Long id) {
        return Result.success(userService.getById(id));
    }

    // GET /api/users?page=1&size=10&name=张
    @GetMapping
    public Result<Page<UserVO>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String name) {
        return Result.success(userService.list(page, size, name));
    }

    // POST /api/users（@RequestBody = 从请求体读 JSON）
    @PostMapping
    public Result<Void> create(@RequestBody @Validated UserCreateDTO dto) {
        userService.create(dto);
        return Result.success(null);
    }

    // PUT /api/users/1
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable Long id, @RequestBody UserUpdateDTO dto) {
        userService.update(id, dto);
        return Result.success(null);
    }

    // DELETE /api/users/1
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        userService.delete(id);
        return Result.success(null);
    }
}
```

### Service（业务逻辑）

```java
// 接口
public interface UserService {
    UserVO getById(Long id);
    void create(UserCreateDTO dto);
}

// 实现类
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserMapper userMapper;

    @Override
    public UserVO getById(Long id) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(404, "用户不存在");
        }
        return BeanUtil.copyProperties(user, UserVO.class);   // Entity → VO
    }

    @Override
    @Transactional(rollbackFor = Exception.class)   // 事务：出异常就回滚
    public void create(UserCreateDTO dto) {
        User user = BeanUtil.copyProperties(dto, User.class);  // DTO → Entity
        userMapper.insert(user);
    }
}
```

> **核心原则：Controller 不写业务逻辑，Service 不写 SQL，Mapper 不写业务逻辑。各司其职。**

---

## 十、MyBatis-Plus——数据库操作

> MyBatis-Plus = ORM 框架。把 SQL 操作变成 Java 方法调用，单表 CRUD 不用写 SQL。

### Entity 实体类

```java
@Data
@TableName("sys_user")       // 对应数据库表名
public class User {
    @TableId(type = IdType.ASSIGN_ID)   // 主键策略：雪花算法
    private Long id;

    private String username;
    private String password;
    private String name;
    private Integer age;
    private Integer status;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;    // 自动填充创建时间

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;    // 自动填充更新时间

    @TableLogic
    private Integer deleted;             // 逻辑删除（delete 时不真删，改为 deleted=1）
}
```

### Mapper 接口

```java
@Mapper
public interface UserMapper extends BaseMapper<User> {
    // 继承 BaseMapper 就有了全套单表 CRUD：
    // insert / deleteById / updateById / selectById / selectList ...
    // 零 SQL！
}
```

### 单表 CRUD

```java
// 插入
User user = new User();
user.setUsername("zhangsan");
user.setName("张三");
userMapper.insert(user);          // 自动生成 ID

// 查询
User user = userMapper.selectById(1L);

// 更新
user.setName("李四");
userMapper.updateById(user);      // 只更新非 null 字段

// 删除
userMapper.deleteById(1L);        // 逻辑删除（有 @TableLogic 时）
```

### 条件查询——LambdaQueryWrapper

```java
// 类比前端：拼查询参数 ?status=1&name=张&age_gte=18
// Java：用 Wrapper 构建查询条件

List<User> users = userMapper.selectList(
    new LambdaQueryWrapper<User>()
        .eq(User::getStatus, 1)                        // status = 1
        .like(User::getName, "张")                      // name LIKE '%张%'
        .between(User::getAge, 18, 60)                 // age BETWEEN 18 AND 60
        .orderByDesc(User::getCreateTime)              // ORDER BY create_time DESC
);

// 动态条件（参数不为空才加条件，最实用）
String name = request.getParameter("name");
Integer status = request.getParameter("status");

new LambdaQueryWrapper<User>()
    .like(StringUtils.isNotBlank(name), User::getName, name)   // name 有值才加
    .eq(status != null, User::getStatus, status);              // status 有值才加
```

### 分页查询

```java
// 1. 配置分页插件（一次配好，全局生效）
@Configuration
public class MybatisPlusConfig {
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }
}

// 2. 使用
Page<User> page = new Page<>(1, 10);       // 第 1 页，每页 10 条
userMapper.selectPage(page, wrapper);

page.getRecords();    // 当前页数据
page.getTotal();      // 总条数
page.getPages();      // 总页数
```


## 十一、Redis——缓存与分布式工具

> Redis 是内存数据库，速度极快。后端用它做缓存、分布式锁、排行榜、会话管理。

### 基础操作

```java
@Service
@RequiredArgsConstructor
public class RedisService {

    private final RedisTemplate<String, Object> redisTemplate;

    // String（最常用）
    redisTemplate.opsForValue().set("user:1", user);                          // 存
    redisTemplate.opsForValue().set("token:abc", userId, 30, TimeUnit.MINUTES);  // 存+过期
    Object value = redisTemplate.opsForValue().get("user:1");                  // 取
    redisTemplate.delete("user:1");                                            // 删

    // Hash（存对象的多个字段）
    redisTemplate.opsForHash().put("user:1", "name", "张三");
    redisTemplate.opsForHash().get("user:1", "name");    // "张三"

    // Set（去重）
    redisTemplate.opsForSet().add("tags", "Java", "Spring", "Redis");

    // ZSet（排行榜）
    redisTemplate.opsForZSet().add("rank:score", "张三", 95);
    redisTemplate.opsForZSet().reverseRangeWithScores("rank:score", 0, 9);  // Top 10
}
```

### 缓存实战

```java
// 查询用户：先查缓存，没有再查数据库
public UserVO getById(Long id) {
    String key = "user:" + id;

    // 1. 查缓存
    Object cached = redisTemplate.opsForValue().get(key);
    if (cached != null) return (UserVO) cached;

    // 2. 查数据库
    User user = userMapper.selectById(id);
    if (user == null) {
        // 缓存空值防穿透（避免恶意请求打穿数据库）
        redisTemplate.opsForValue().set(key, "NULL", 5, TimeUnit.MINUTES);
        return null;
    }

    UserVO vo = BeanUtil.copyProperties(user, UserVO.class);

    // 3. 写缓存（随机 TTL 防雪崩）
    long ttl = 30 + RandomUtil.randomLong(0, 5);
    redisTemplate.opsForValue().set(key, vo, ttl, TimeUnit.MINUTES);
    return vo;
}

// 更新用户：先更数据库，再删缓存
@Transactional
public void update(Long id, UserUpdateDTO dto) {
    userMapper.updateById(user);
    redisTemplate.delete("user:" + id);   // 删缓存，下次查询会重建
}
```

> **缓存三大问题**：穿透（查不存在的 → 缓存空值）、雪崩（同时过期 → 随机 TTL）、击穿（热点 key 过期 → 分布式锁）

### 分布式锁

```java
// 场景：防止重复下单
String lockKey = "lock:order:" + userId;
String requestId = UUID.randomUUID().toString();

Boolean locked = redisTemplate.opsForValue()
    .setIfAbsent(lockKey, requestId, 10, TimeUnit.SECONDS);  // 不存在才设置

if (!locked) throw new BusinessException(429, "请勿重复提交");

try {
    doCreateOrder(userId, productId);   // 业务逻辑
} finally {
    // 释放锁（只有自己加的锁才能删，用 Lua 脚本保证原子性）
    String script = "if redis.call('get',KEYS[1])==ARGV[1] then return redis.call('del',KEYS[1]) else return 0 end";
    redisTemplate.execute(new DefaultRedisScript<>(script, Long.class), List.of(lockKey), requestId);
}
```

---

## 十二、并发编程基础

> JS 是单线程 + 事件循环，Java 是多线程。这是你从前端转后端最需要理解的概念差异。

### 为什么 Java 需要多线程

```
前端（JS）：
  单线程 → 遇到 I/O（网络请求、文件读写）→ 交给事件循环异步处理
  所以 JS 需要 Promise、async/await

后端（Java）：
  Tomcat 为每个 HTTP 请求分配一个线程
  线程内部代码同步执行（阻塞式），但多个请求并行处理
  所以 Java 后端通常不需要写 async/await（除非做高性能优化）
```

### 线程基础

```java
// 方式 1：实现 Runnable（最常用）
new Thread(() -> {
    System.out.println("在新线程里执行: " + Thread.currentThread().getName());
}).start();

// 方式 2：线程池（生产环境必须用线程池，不要直接 new Thread）
ExecutorService pool = Executors.newFixedThreadPool(10);  // 10 个线程的线程池
pool.submit(() -> {
    // 异步任务
    sendEmail(user);
});
pool.shutdown();
```

### 线程安全问题

```java
// JS 不存在这个问题（单线程），Java 必须注意

// ❌ 线程不安全
int count = 0;
// 多个线程同时执行 count++，结果不确定！
// 因为 count++ 不是原子操作（读 → 改 → 写，中间可能被其他线程打断）

// ✅ 解决方案 1：synchronized（悲观锁）
synchronized (this) {
    count++;
}

// ✅ 解决方案 2：原子类（CAS 无锁）
AtomicInteger count = new AtomicInteger(0);
count.incrementAndGet();     // 线程安全的 count++

// ✅ 解决方案 3：用线程安全的集合
// ArrayList → CopyOnWriteArrayList
// HashMap → ConcurrentHashMap
```

### CompletableFuture——Java 的 Promise

```java
// JS: const result = await fetch('/api/users')
// Java: CompletableFuture 是 Java 的 Promise

// 异步执行
CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
    // 异步任务（在线程池中执行）
    return callExternalApi();
});

// 等待结果（类似 await）
String result = future.get();    // 阻塞等待

// 链式调用（类似 Promise.then）
CompletableFuture.supplyAsync(() -> getUserById(1))
    .thenApply(user -> user.getName())        // .then(user => user.name)
    .thenAccept(name -> log.info(name))       // .then(name => console.log(name))
    .exceptionally(e -> {                      // .catch(e => ...)
        log.error("出错了", e);
        return null;
    });

// 并行执行多个任务（类似 Promise.all）
CompletableFuture<User> userFuture = CompletableFuture.supplyAsync(() -> getUser(1));
CompletableFuture<Order> orderFuture = CompletableFuture.supplyAsync(() -> getOrder(1));

CompletableFuture.allOf(userFuture, orderFuture).join();   // 等全部完成
User user = userFuture.get();
Order order = orderFuture.get();
```

> **日常开发中**，大部分后端代码不需要手动处理线程——Spring Boot 的 Tomcat 帮你管理请求线程，`@Transactional` 帮你管理数据库事务，Redis 帮你做分布式锁。但理解多线程的概念是必须的。

---

## 十三、Spring Security + JWT——认证与授权

> 前后端分离项目的标准认证方案：JWT（JSON Web Token）。前端存 token，每次请求在 Header 里带上。

### 流程

```
1. 前端发登录请求 POST /api/auth/login { username, password }
2. 后端校验密码 → 生成 JWT Token → 返回给前端
3. 前端把 token 存在 localStorage
4. 之后每个请求在 Header 带上：Authorization: Bearer xxxxx
5. 后端拦截器解析 token → 获取用户信息 → 放行或拒绝
```

### JWT 工具类

```java
@Component
public class JwtUtil {
    @Value("${jwt.secret}")
    private String secret;

    // 生成 Token
    public String generateToken(Long userId, String username) {
        return Jwts.builder()
            .subject(String.valueOf(userId))
            .claim("username", username)
            .expiration(new Date(System.currentTimeMillis() + 86400000))  // 24 小时
            .signWith(Keys.hmacShaKeyFor(secret.getBytes()))
            .compact();
    }

    // 从 Token 获取用户 ID
    public Long getUserId(String token) {
        return Long.parseLong(Jwts.parser()
            .verifyWith(Keys.hmacShaKeyFor(secret.getBytes()))
            .build()
            .parseSignedClaims(token)
            .getPayload()
            .getSubject());
    }
}
```

### Security 配置

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())          // 前后端分离不需要 CSRF
            .sessionManagement(sm -> sm
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))  // 无状态
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()   // 登录注册放行
                .anyRequest().authenticated()                  // 其他需要认证
            )
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();   // 密码加密
    }
}
```

> **前端视角**：这就是你写 axios 拦截器时对应的后端逻辑。你在 `request.interceptors.request.use` 里加 token，后端在 `JwtAuthenticationFilter` 里取 token 并验证。

---

## 十四、RabbitMQ——消息队列

> 消息队列 = 异步处理 + 解耦 + 削峰。类似前端的事件总线（EventBus），但是跨服务的。

### 为什么需要消息队列

```
同步：用户注册 → 写数据库 → 发邮件（3秒）→ 发短信（2秒）→ 返回
     用户等了 5 秒才收到"注册成功"

异步：用户注册 → 写数据库 → 发消息到 MQ → 立即返回
                                ↓
                         消费者异步处理：发邮件、发短信
     用户 0.1 秒收到"注册成功"
```

### 基本用法

```java
// 生产者：发送消息
@Service
@RequiredArgsConstructor
public class OrderService {
    private final RabbitTemplate rabbitTemplate;

    public void createOrder(OrderDTO dto) {
        orderMapper.insert(order);
        // 发消息到 MQ（不等结果，异步处理）
        rabbitTemplate.convertAndSend("order.exchange", "order.create", JSON.toJSONString(order));
    }
}

// 消费者：处理消息
@Component
@Slf4j
public class OrderConsumer {

    @RabbitListener(queues = "order.queue")
    public void handleOrderCreate(String message, Channel channel,
                                   @Header(AmqpHeaders.DELIVERY_TAG) long tag) throws IOException {
        try {
            OrderMessage msg = JSON.parseObject(message, OrderMessage.class);
            sendEmail(msg);          // 发邮件
            sendSms(msg);            // 发短信
            channel.basicAck(tag, false);   // 处理成功，确认消息
        } catch (Exception e) {
            channel.basicNack(tag, false, true);   // 处理失败，重新入队
        }
    }
}
```

> **消息可靠性三板斧**：生产者确认（消息到了 MQ）→ MQ 持久化（MQ 重启不丢）→ 消费者手动确认（处理成功才删除）

---

## 十五、Spring Cloud 微服务

> 单体应用 → 微服务：每个服务独立部署、独立数据库、服务间网络调用。

### 全家桶

| 需求 | 方案 | 说明 |
|---|---|---|
| 注册中心 | Nacos | 服务注册与发现 + 配置中心 |
| 网关 | Gateway | 统一入口、路由、鉴权 |
| 远程调用 | OpenFeign | 声明式 HTTP 客户端 |
| 熔断降级 | Sentinel | 限流、熔断、降级 |

### OpenFeign——服务间调用

```java
// 订单服务要调用用户服务获取用户信息
// 像调本地方法一样调远程服务

@FeignClient(name = "user-service", path = "/api/users")
public interface UserClient {
    @GetMapping("/{id}")
    Result<UserVO> getById(@PathVariable("id") Long id);
}

// 使用（注入后直接调用，底层自动发 HTTP 请求）
@Service
@RequiredArgsConstructor
public class OrderServiceImpl {
    private final UserClient userClient;

    public OrderDetailVO getOrderDetail(Long orderId) {
        Order order = orderMapper.selectById(orderId);
        Result<UserVO> userResult = userClient.getById(order.getUserId());
        // ...
    }
}
```

### Gateway 网关

```yaml
# 所有请求先经过网关，网关根据路径转发到对应服务
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service        # lb:// 负载均衡
          predicates:
            - Path=/api/users/**
        - id: order-service
          uri: lb://order-service
          predicates:
            - Path=/api/orders/**
```

> **类比前端**：网关 = Nginx 反向代理 + 路由分发。前端请求统一发到网关，网关再转发到具体的微服务。

---

## 十六、Docker 部署

> Docker = 容器化。把应用和环境打包在一起，在哪都能跑。类似前端的"npm run build → Nginx 托管"。

### Dockerfile

```dockerfile
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Docker Compose——一键启动全套环境

```yaml
# docker-compose.yml
version: '3.8'
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: 123456
      MYSQL_DATABASE: mydb
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  app:
    build: .
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/mydb
      SPRING_DATA_REDIS_HOST: redis
    ports:
      - "8080:8080"
    depends_on:
      - mysql
      - redis
```

```bash
docker compose up -d          # 启动
docker compose logs -f app    # 看日志
docker compose down           # 停止
```

> **类比前端部署**：前端是 `npm run build` → 把 dist 扔到 Nginx。后端是 `mvn package` → 把 jar 扔到 Docker。

---

## 十七、日志与调试

> 前端用 `console.log`，Java 用日志框架（SLF4J + Logback）。

### 基本用法

```java
@Slf4j                           // Lombok 注解，自动生成 log 对象
@Service
public class UserService {

    public void createUser(UserDTO dto) {
        log.debug("收到创建用户请求: {}", dto);     // 开发调试用
        log.info("创建用户: {}", dto.getName());    // 正常日志
        log.warn("密码强度不够: {}", dto.getName()); // 警告
        log.error("创建用户失败", exception);        // 错误（会打印堆栈）
    }
}
```

### 日志级别

```
TRACE → DEBUG → INFO → WARN → ERROR
              ↑
         生产环境通常设 INFO，DEBUG 太多了
```

```yaml
# application.yml
logging:
  level:
    root: info                         # 全局 INFO
    com.example.demo.mapper: debug     # Mapper 层 DEBUG（打印 SQL）
    com.example.demo.service: debug    # Service 层 DEBUG
```

### 对比前端

| 前端 | Java |
|---|---|
| `console.log()` | `log.info()` |
| `console.warn()` | `log.warn()` |
| `console.error()` | `log.error()` |
| 浏览器 DevTools | 日志文件 / 终端输出 |
| 没有日志级别控制 | 按级别和包名精确控制 |

> **铁律**：生产环境不要用 `System.out.println()`（没时间戳、不能控制级别、不能输出到文件），一律用 `log.xxx()`。

---

## 十八、总结

### Java 后端开发核心流程

```
前端请求
  ↓
Gateway（网关）→ 路由分发、鉴权
  ↓
Controller → 接收参数、校验
  ↓
Service → 业务逻辑、事务控制
  ↓
Mapper → 数据库操作（MyBatis-Plus）
  ↓
Redis → 缓存加速
  ↓
MQ → 异步处理
  ↓
返回 JSON 给前端
```

### 技术选型速查表

| 层次 | 技术 | 说明 |
|---|---|---|
| 语言 | Java 17+ | LTS 版本 |
| 构建 | Maven | 依赖管理 + 构建 |
| 框架 | Spring Boot 3.x | 约定大于配置 |
| ORM | MyBatis-Plus | 单表零 SQL |
| 缓存 | Redis | 缓存 + 分布式锁 |
| 认证 | Security + JWT | 无状态认证 |
| 消息 | RabbitMQ | 异步解耦 |
| 微服务 | Spring Cloud Alibaba | Nacos + Gateway + OpenFeign |
| 数据库 | MySQL 8.0 | InnoDB，utf8mb4 |
| 工具 | Lombok + Hutool | 减少样板代码 |
| 部署 | Docker | 容器化 |

### 前端 → 后端 概念对照总表

| 前端概念 | Java 后端对应 |
|---|---|
| `npm install` | `mvn install` |
| `package.json` | `pom.xml` |
| `vite.config.js` + `.env` | `application.yml` |
| `npm run dev` | `mvn spring-boot:run` |
| `console.log()` | `log.info()` |
| `axios` | `RestTemplate` / `OpenFeign` |
| `Vue Router` | `@GetMapping` / `@PostMapping` |
| `Pinia / Vuex` | Spring IOC 容器（单例 Bean） |
| `composable / hook` | `@Service` 层 |
| `interface (TS)` | `interface` / `class` |
| `Promise / async-await` | `CompletableFuture` |
| `EventBus` | `RabbitMQ` |
| `localStorage` | `Redis` |
| `Nginx` | `Spring Cloud Gateway` |
| `npm run build` → `dist/` | `mvn package` → `target/xxx.jar` |

### 面试高频题

**Q：Spring 的 IOC 是什么？**
A：控制反转。对象的创建和依赖关系由 Spring 容器管理，不用自己 new。通过注解（@Service、@Autowired）声明依赖，Spring 自动注入。

**Q：AOP 是什么？有什么用？**
A：面向切面编程。在不修改原代码的情况下给方法加功能（日志、事务、权限、耗时统计）。@Transactional 就是 AOP 实现的。

**Q：@Transactional 的坑？**
A：只对 public 方法生效；同类内部调用不生效（绕过了代理）；默认只回滚 RuntimeException，建议加 `rollbackFor = Exception.class`。

**Q：Redis 缓存三大问题？**
A：穿透（查不存在的数据 → 缓存空值）、雪崩（大量缓存同时过期 → 随机 TTL）、击穿（热点 key 过期 → 分布式锁）。

**Q：微服务和单体的区别？**
A：单体全在一个 jar 里，微服务每个模块独立部署。微服务用 Nacos 做注册中心，OpenFeign 做服务间调用，Gateway 做统一入口。

---

> **Java 后端开发的核心循环：Controller 接请求 → Service 写逻辑 → Mapper 存数据 → Redis 加缓存 → MQ 做异步 → Security 管权限 → Gateway 统一入口。掌握这个循环，就能干活了。**
