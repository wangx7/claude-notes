# MySQL 完全教程

> 从零开始，系统学习 MySQL 数据库

---

## 第一章：MySQL 基础概念

### 1.1 什么是数据库？

数据库（Database）是**按照一定的数据结构来组织、存储和管理数据的仓库**。

你可以把数据库想象成一个 Excel 文件：
- **数据库** = 整个 Excel 文件
- **表（Table）** = Excel 中的一个 Sheet
- **行（Row）** = Sheet 中的一行数据
- **列（Column）** = Sheet 中的一个字段

### 1.2 什么是 MySQL？

MySQL 是最流行的**关系型数据库管理系统（RDBMS）**之一。

**关系型**的意思是：数据以**表格（二维表）**的形式存储，表与表之间可以建立**关系（关联）**。

MySQL 的特点：
- ✅ **开源免费**（社区版）
- ✅ **性能优秀**，能处理千万级数据
- ✅ **使用广泛**，互联网公司首选
- ✅ **跨平台**，支持 Windows/Linux/macOS
- ✅ **支持标准 SQL 语法**

### 1.3 MySQL 的架构（简要了解）

```
客户端（你的程序/命令行）
        ↓
   连接层（管理连接、验证身份）
        ↓
   服务层（SQL 解析、优化、缓存）
        ↓
   存储引擎层（InnoDB / MyISAM 等）
        ↓
   文件系统（实际的数据文件）
```

**InnoDB** 是 MySQL 5.5+ 的默认存储引擎，支持：
- 事务（Transaction）
- 行级锁（Row-level Locking）
- 外键（Foreign Key）

---

## 第二章：安装与连接

### 2.1 macOS 安装（Homebrew）

```bash
# 安装 MySQL
brew install mysql

# 启动 MySQL 服务
brew services start mysql

# 设置 root 密码（首次安装后执行）
mysql_secure_installation
```

### 2.2 连接 MySQL

```bash
# 使用 root 用户连接
mysql -u root -p

# 连接后你会看到类似这样的提示符：
# mysql>
```

### 2.3 基本管理命令

```sql
-- 查看所有数据库
SHOW DATABASES;

-- 查看 MySQL 版本
SELECT VERSION();

-- 查看当前用户
SELECT USER();

-- 查看当前使用的数据库
SELECT DATABASE();

-- 退出 MySQL
EXIT;
-- 或者
QUIT;
```

---

## 第三章：数据库和表的基本操作（DDL）

> DDL = Data Definition Language（数据定义语言）

### 3.1 数据库操作

```sql
-- 创建数据库
CREATE DATABASE mydb;

-- 创建数据库（指定字符集，推荐）
CREATE DATABASE mydb
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- 如果不存在才创建（避免报错）
CREATE DATABASE IF NOT EXISTS mydb;

-- 查看所有数据库
SHOW DATABASES;

-- 切换/使用数据库（重要！操作表之前必须先选择数据库）
USE mydb;

-- 删除数据库（⚠️ 危险操作，不可恢复！）
DROP DATABASE mydb;

-- 安全删除
DROP DATABASE IF EXISTS mydb;
```

> **💡 提示：** `utf8mb4` 是 MySQL 中真正的 UTF-8 编码，支持 emoji 等4字节字符。
> MySQL 的 `utf8` 实际上是 `utf3`，最多只支持3字节，这是历史遗留问题。

### 3.2 常用数据类型

在创建表之前，你需要知道 MySQL 有哪些数据类型：

#### 整数类型

| 类型        | 字节 | 范围（有符号）                        | 常见用途         |
|-------------|------|---------------------------------------|------------------|
| `TINYINT`   | 1    | -128 ~ 127                            | 状态、布尔值     |
| `SMALLINT`  | 2    | -32768 ~ 32767                        | 小范围数字       |
| `INT`       | 4    | -21亿 ~ 21亿                          | **最常用**       |
| `BIGINT`    | 8    | -922亿亿 ~ 922亿亿                    | ID、大数字       |

> **💡 提示：** `TINYINT(1)` 常用来表示布尔值（0=false, 1=true）

#### 字符串类型

| 类型          | 最大长度     | 说明                                   |
|---------------|-------------|----------------------------------------|
| `CHAR(n)`     | 255字符     | **定长**字符串，不够补空格，查询快      |
| `VARCHAR(n)`  | 65535字符   | **变长**字符串，按实际长度存储，**最常用** |
| `TEXT`        | 65535字符   | 长文本，不能设默认值                    |
| `LONGTEXT`    | 4GB         | 超长文本                               |

> **💡 CHAR vs VARCHAR：**
> - `CHAR(10)` 存 "abc" → 占 10 字节（补7个空格）
> - `VARCHAR(10)` 存 "abc" → 占 4 字节（3字节内容 + 1字节长度）

#### 日期时间类型

| 类型         | 格式                  | 说明                        |
|--------------|----------------------|----------------------------|
| `DATE`       | `2024-01-15`         | 只有日期                    |
| `TIME`       | `14:30:00`           | 只有时间                    |
| `DATETIME`   | `2024-01-15 14:30:00`| 日期+时间，**最常用**        |
| `TIMESTAMP`  | 同上                  | 自动转UTC存储，有时区转换    |

> **💡 DATETIME vs TIMESTAMP：**
> - `DATETIME` 范围大（1000年~9999年），不受时区影响
> - `TIMESTAMP` 范围小（1970年~2038年），会自动转换时区
> - 推荐一般用 `DATETIME`，需要时区感知用 `TIMESTAMP`

#### 小数类型

| 类型              | 说明                               |
|-------------------|------------------------------------|
| `FLOAT`           | 单精度浮点，有精度损失              |
| `DOUBLE`          | 双精度浮点，有精度损失              |
| `DECIMAL(M,D)`    | **精确小数**，M=总位数，D=小数位数   |

> **💡 涉及金额一定用 `DECIMAL`！** 例如 `DECIMAL(10,2)` 表示最多10位数、2位小数。

---

### 3.3 创建表

```sql
-- 创建用户表
CREATE TABLE users (
    id          INT           NOT NULL AUTO_INCREMENT,  -- 自增主键
    username    VARCHAR(50)   NOT NULL,                  -- 用户名
    email       VARCHAR(100)  NOT NULL,                  -- 邮箱
    age         TINYINT       UNSIGNED,                  -- 年龄（无符号）
    balance     DECIMAL(10,2) DEFAULT 0.00,              -- 余额
    status      TINYINT       DEFAULT 1,                 -- 状态 1=正常
    created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP, -- 创建时间
    updated_at  DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)                                     -- 主键
);

-- 如果不存在才创建
CREATE TABLE IF NOT EXISTS users ( ... );
```

**关键字解释：**
- `NOT NULL` — 该列不允许为空
- `AUTO_INCREMENT` — 自动递增（通常用于主键 ID）
- `UNSIGNED` — 无符号（只能存正数，范围翻倍）
- `DEFAULT` — 默认值
- `PRIMARY KEY` — 主键（唯一标识每一行）
- `ON UPDATE CURRENT_TIMESTAMP` — 每次更新行时自动更新时间

### 3.4 表操作命令

```sql
-- 查看当前数据库中所有表
SHOW TABLES;

-- 查看表结构（字段信息）
DESC users;
-- 或者
DESCRIBE users;
-- 或者更详细
SHOW CREATE TABLE users;

-- 删除表
DROP TABLE users;
DROP TABLE IF EXISTS users;

-- 清空表数据（保留表结构，自增ID重置）
TRUNCATE TABLE users;
```

---

## 第四章：增删改查（CRUD）

> CRUD = Create / Read / Update / Delete
> DML = Data Manipulation Language（数据操作语言）

### 4.1 插入数据（INSERT）

```sql
-- 插入单条数据（指定列）
INSERT INTO users (username, email, age)
VALUES ('张三', 'zhangsan@example.com', 25);

-- 插入单条数据（所有列，按顺序）
INSERT INTO users
VALUES (NULL, '李四', 'lisi@example.com', 30, 100.00, 1, NOW(), NOW());
-- ⚠️ 自增ID传NULL即可

-- 批量插入（推荐，效率远高于多条单插入）
INSERT INTO users (username, email, age) VALUES
    ('王五', 'wangwu@example.com', 28),
    ('赵六', 'zhaoliu@example.com', 35),
    ('钱七', 'qianqi@example.com', 22);
```

> **💡 性能提示：** 批量插入比循环单条插入快 **10~50 倍**！

### 4.2 查询数据（SELECT）⭐ 最重要

```sql
-- 查询所有列
SELECT * FROM users;

-- 查询指定列（推荐，避免 SELECT *）
SELECT username, email, age FROM users;

-- 给列起别名（AS 可省略）
SELECT username AS '用户名', email AS '邮箱' FROM users;
SELECT username '用户名', email '邮箱' FROM users;  -- AS 可省略

-- 去重
SELECT DISTINCT age FROM users;

-- 限制返回行数（分页基础）
SELECT * FROM users LIMIT 10;        -- 前10条
SELECT * FROM users LIMIT 5, 10;     -- 跳过5条，取10条（偏移量, 数量）
SELECT * FROM users LIMIT 10 OFFSET 5; -- 同上，更易读
```

### 4.3 WHERE 条件过滤

```sql
-- 基本比较
SELECT * FROM users WHERE age = 25;
SELECT * FROM users WHERE age != 25;   -- 不等于
SELECT * FROM users WHERE age <> 25;   -- 不等于（同上）
SELECT * FROM users WHERE age > 18;
SELECT * FROM users WHERE age >= 18;
SELECT * FROM users WHERE age < 30;
SELECT * FROM users WHERE age <= 30;

-- BETWEEN 范围
SELECT * FROM users WHERE age BETWEEN 18 AND 30;
-- 等价于 age >= 18 AND age <= 30

-- IN 列表匹配
SELECT * FROM users WHERE age IN (20, 25, 30);
-- 等价于 age = 20 OR age = 25 OR age = 30

-- IS NULL / IS NOT NULL
SELECT * FROM users WHERE age IS NULL;
SELECT * FROM users WHERE age IS NOT NULL;
-- ⚠️ 不能用 age = NULL，这样永远返回空！

-- LIKE 模糊查询
SELECT * FROM users WHERE username LIKE '张%';    -- 以"张"开头
SELECT * FROM users WHERE username LIKE '%三';    -- 以"三"结尾
SELECT * FROM users WHERE username LIKE '%王%';   -- 包含"王"
SELECT * FROM users WHERE username LIKE '张_';    -- "张"后面跟一个字符
-- % = 任意多个字符，_ = 恰好一个字符

-- AND / OR / NOT 逻辑组合
SELECT * FROM users WHERE age > 18 AND status = 1;
SELECT * FROM users WHERE age < 18 OR age > 60;
SELECT * FROM users WHERE NOT (age > 30);
SELECT * FROM users WHERE age > 18 AND (status = 1 OR status = 2);
-- ⚠️ 注意 AND 优先级高于 OR，复杂条件务必加括号！
```

### 4.4 排序（ORDER BY）

```sql
-- 升序（默认）
SELECT * FROM users ORDER BY age ASC;
SELECT * FROM users ORDER BY age;         -- 不写默认升序

-- 降序
SELECT * FROM users ORDER BY age DESC;

-- 多字段排序（先按 age 升序，age 相同时按 id 降序）
SELECT * FROM users ORDER BY age ASC, id DESC;
```

### 4.5 更新数据（UPDATE）

```sql
-- 更新单个字段
UPDATE users SET age = 26 WHERE id = 1;

-- 更新多个字段
UPDATE users SET age = 26, email = 'new@example.com' WHERE id = 1;

-- 基于条件批量更新
UPDATE users SET status = 0 WHERE age < 18;

-- 使用表达式
UPDATE users SET balance = balance + 100 WHERE id = 1;
UPDATE users SET age = age + 1;  -- 所有人年龄加1
```

> **⚠️ 超级重要：UPDATE 一定要加 WHERE！**
> `UPDATE users SET status = 0;` — 这会把**所有用户**的 status 都改成 0！
> MySQL 有 `sql_safe_updates` 模式可以防止无 WHERE 的更新。

### 4.6 删除数据（DELETE）

```sql
-- 删除指定数据
DELETE FROM users WHERE id = 1;

-- 条件删除
DELETE FROM users WHERE status = 0 AND age < 18;

-- 删除所有数据（逐行删除，保留自增计数器）
DELETE FROM users;
```

> **⚠️ DELETE vs TRUNCATE：**
> | 对比项       | `DELETE`               | `TRUNCATE`           |
> |-------------|------------------------|----------------------|
> | 速度        | 慢（逐行删除）           | 快（直接清空）        |
> | 自增ID      | 继续递增                | 重置为1              |
> | 事务回滚    | ✅ 可以回滚              | ❌ 不可回滚           |
> | WHERE       | ✅ 支持条件删除          | ❌ 只能全部清空       |
> | 触发器      | ✅ 会触发                | ❌ 不会触发           |

---

## 第五章：修改表结构（ALTER TABLE）

```sql
-- 添加列
ALTER TABLE users ADD COLUMN phone VARCHAR(20) AFTER email;
-- AFTER 指定新列的位置，也可用 FIRST 放在第一列

-- 删除列
ALTER TABLE users DROP COLUMN phone;

-- 修改列的数据类型
ALTER TABLE users MODIFY COLUMN age SMALLINT UNSIGNED;

-- 修改列名 + 类型（重命名列）
ALTER TABLE users CHANGE COLUMN username nickname VARCHAR(60) NOT NULL;

-- 修改默认值
ALTER TABLE users ALTER COLUMN status SET DEFAULT 0;

-- 重命名表
ALTER TABLE users RENAME TO members;
-- 或者
RENAME TABLE users TO members;
```

> **💡 生产环境注意：** 对大表执行 `ALTER TABLE` 可能锁表几分钟甚至几小时！
> 推荐使用 `pt-online-schema-change` 或 `gh-ost` 工具进行在线 DDL。

---

## 第六章：聚合函数与分组

### 6.1 聚合函数

聚合函数对一组数据进行计算，返回**单个值**。

```sql
-- COUNT：计数
SELECT COUNT(*) FROM users;                -- 总行数（包含 NULL）
SELECT COUNT(age) FROM users;              -- age 非 NULL 的行数
SELECT COUNT(DISTINCT age) FROM users;     -- 去重后的 age 数量

-- SUM：求和
SELECT SUM(balance) FROM users;

-- AVG：平均值
SELECT AVG(age) FROM users;

-- MAX / MIN：最大值 / 最小值
SELECT MAX(age), MIN(age) FROM users;
SELECT MAX(created_at) FROM users;         -- 最近注册时间

-- 组合使用
SELECT
    COUNT(*) AS '总人数',
    AVG(age) AS '平均年龄',
    MAX(balance) AS '最高余额',
    SUM(balance) AS '总余额'
FROM users
WHERE status = 1;
```

### 6.2 GROUP BY 分组

`GROUP BY` 把数据按照某个列的值**分成若干组**，然后对每组分别做聚合。

```sql
-- 按 status 分组，统计每组人数
SELECT status, COUNT(*) AS cnt
FROM users
GROUP BY status;
-- 结果：
-- status | cnt
-- 0      | 15
-- 1      | 85

-- 按年龄段分组（使用表达式）
SELECT
    CASE
        WHEN age < 18 THEN '未成年'
        WHEN age BETWEEN 18 AND 30 THEN '青年'
        WHEN age BETWEEN 31 AND 50 THEN '中年'
        ELSE '老年'
    END AS '年龄段',
    COUNT(*) AS '人数'
FROM users
GROUP BY 年龄段;

-- 多列分组
SELECT status, age, COUNT(*)
FROM users
GROUP BY status, age;
```

> **⚠️ 重要规则：** `SELECT` 中出现的**非聚合列**，必须出现在 `GROUP BY` 中！
> ```sql
> -- ❌ 错误！username 没有在 GROUP BY 中
> SELECT username, status, COUNT(*) FROM users GROUP BY status;
>
> -- ✅ 正确
> SELECT status, COUNT(*) FROM users GROUP BY status;
> ```

### 6.3 HAVING —— 对分组结果过滤

`WHERE` 在分组**之前**过滤行，`HAVING` 在分组**之后**过滤组。

```sql
-- 找出人数大于10的状态
SELECT status, COUNT(*) AS cnt
FROM users
GROUP BY status
HAVING cnt > 10;

-- WHERE 和 HAVING 配合使用
SELECT status, COUNT(*) AS cnt
FROM users
WHERE age >= 18           -- 先过滤：只统计成年人
GROUP BY status           -- 然后分组
HAVING cnt > 5            -- 再过滤：只要人数>5的组
ORDER BY cnt DESC;        -- 最后排序
```

> **💡 SQL 执行顺序（非常重要！）：**
> ```
> FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
> ```
> 这就是为什么 `WHERE` 中不能用聚合函数，而 `HAVING` 可以。

---

## 第七章：子查询

子查询就是**嵌套在另一个查询中的 SELECT 语句**。

### 7.1 标量子查询（返回单个值）

```sql
-- 查找年龄大于平均年龄的用户
SELECT * FROM users
WHERE age > (SELECT AVG(age) FROM users);

-- 查找余额最高的用户
SELECT * FROM users
WHERE balance = (SELECT MAX(balance) FROM users);
```

### 7.2 列子查询（返回一列多行）

```sql
-- 查找和"张三"同龄的所有用户
SELECT * FROM users
WHERE age IN (
    SELECT age FROM users WHERE username = '张三'
);

-- 查找下过订单的用户（假设有 orders 表）
SELECT * FROM users
WHERE id IN (
    SELECT DISTINCT user_id FROM orders
);
```

### 7.3 EXISTS 子查询

```sql
-- EXISTS：只关心子查询是否有结果，不关心具体值
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);
-- 等价于上面的 IN 子查询，但大数据量时 EXISTS 通常更快

-- NOT EXISTS
SELECT * FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);
-- 找出没有下过订单的用户
```

### 7.4 FROM 子查询（派生表）

```sql
-- 把子查询结果当作临时表使用
SELECT avg_table.age_group, avg_table.avg_balance
FROM (
    SELECT
        CASE WHEN age < 30 THEN '青年' ELSE '中老年' END AS age_group,
        AVG(balance) AS avg_balance
    FROM users
    GROUP BY age_group
) AS avg_table                -- ⚠️ 派生表必须有别名
WHERE avg_table.avg_balance > 100;
```

> **💡 子查询 vs JOIN：** 很多子查询可以改写为 JOIN，通常 JOIN 性能更好。
> 下一章我们详细讲 JOIN。

---

## 第八章：JOIN 多表连接 ⭐⭐ 核心重点

### 8.0 准备示例表

为了演示 JOIN，我们先建两张表：

```sql
-- 用户表
CREATE TABLE users (
    id       INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL
);

-- 订单表
CREATE TABLE orders (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    user_id   INT,              -- 关联 users.id
    product   VARCHAR(100),
    amount    DECIMAL(10,2),
    order_date DATE
);

-- 插入示例数据
INSERT INTO users (username) VALUES ('张三'), ('李四'), ('王五'), ('赵六');

INSERT INTO orders (user_id, product, amount, order_date) VALUES
    (1, 'iPhone',   5999.00, '2024-01-15'),
    (1, 'AirPods',  1299.00, '2024-02-20'),
    (2, 'MacBook',  12999.00, '2024-01-10'),
    (2, 'iPad',     3999.00, '2024-03-05'),
    (3, 'Apple Watch', 2999.00, '2024-02-14'),
    (99, '键盘',     299.00, '2024-01-01');  -- user_id=99 不存在
-- 注意：赵六(id=4) 没有订单，user_id=99 没有对应用户
```

### 8.1 INNER JOIN（内连接）

**只返回两张表中能匹配上的行。**

```
users 表:          orders 表:
id=1 张三           user_id=1 iPhone
id=2 李四           user_id=1 AirPods
id=3 王五           user_id=2 MacBook
id=4 赵六           user_id=2 iPad
                    user_id=3 Apple Watch
                    user_id=99 键盘

INNER JOIN 结果：只有 id=1,2,3 能匹配上
赵六(id=4) 没有订单 → 被丢弃
user_id=99 没有用户 → 被丢弃
```

```sql
SELECT u.username, o.product, o.amount
FROM users u
INNER JOIN orders o ON u.id = o.user_id;
-- INNER 可以省略，直接写 JOIN 默认就是 INNER JOIN

-- 结果：
-- 张三 | iPhone      | 5999.00
-- 张三 | AirPods     | 1299.00
-- 李四 | MacBook     | 12999.00
-- 李四 | iPad        | 3999.00
-- 王五 | Apple Watch | 2999.00
```

### 8.2 LEFT JOIN（左连接）

**返回左表所有行 + 右表匹配的行。右表没匹配到的填 NULL。**

```sql
SELECT u.username, o.product, o.amount
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

-- 结果：
-- 张三 | iPhone      | 5999.00
-- 张三 | AirPods     | 1299.00
-- 李四 | MacBook     | 12999.00
-- 李四 | iPad        | 3999.00
-- 王五 | Apple Watch | 2999.00
-- 赵六 | NULL        | NULL        ← 赵六保留，但没有订单
```

```sql
-- 实用：找出没有下过订单的用户
SELECT u.username
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.id IS NULL;
-- 结果：赵六
```

### 8.3 RIGHT JOIN（右连接）

**返回右表所有行 + 左表匹配的行。左表没匹配到的填 NULL。**

```sql
SELECT u.username, o.product, o.amount
FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;

-- 结果：
-- 张三 | iPhone       | 5999.00
-- 张三 | AirPods      | 1299.00
-- 李四 | MacBook      | 12999.00
-- 李四 | iPad         | 3999.00
-- 王五 | Apple Watch  | 2999.00
-- NULL | 键盘         | 299.00      ← user_id=99 没有对应用户
```

> **💡 实际开发中 RIGHT JOIN 很少用**，通常交换表的位置用 LEFT JOIN 代替。

### 8.4 CROSS JOIN（交叉连接 / 笛卡尔积）

**每一行 × 每一行，返回所有组合。**

```sql
SELECT u.username, o.product
FROM users u
CROSS JOIN orders o;
-- 4个用户 × 6个订单 = 24行结果

-- 实际用途示例：生成日历/报表框架
SELECT d.date, s.status_name
FROM dates d
CROSS JOIN statuses s;
```

> **⚠️ 大表千万别用 CROSS JOIN！** 1万 × 1万 = 1亿行。

### 8.5 自连接（Self Join）

**表自己连接自己**，常用于有层级关系的数据（如组织架构、评论回复）。

```sql
-- 员工表（manager_id 指向同表的 id）
CREATE TABLE employees (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(50),
    manager_id INT          -- 上级的 id
);

INSERT INTO employees (name, manager_id) VALUES
    ('CEO 王总', NULL),
    ('CTO 李总', 1),
    ('开发经理 张三', 2),
    ('开发工程师 小明', 3),
    ('开发工程师 小红', 3);

-- 查询每个员工及其上级
SELECT
    e.name AS '员工',
    m.name AS '上级'
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- 结果：
-- CEO 王总         | NULL
-- CTO 李总         | CEO 王总
-- 开发经理 张三     | CTO 李总
-- 开发工程师 小明   | 开发经理 张三
-- 开发工程师 小红   | 开发经理 张三
```

### 8.6 多表 JOIN

```sql
-- 假设还有一个 products 表
-- 三表连接：用户 + 订单 + 产品
SELECT
    u.username,
    o.order_date,
    p.product_name,
    p.category,
    o.amount
FROM users u
INNER JOIN orders o ON u.id = o.user_id
INNER JOIN products p ON o.product_id = p.id
WHERE o.order_date >= '2024-01-01'
ORDER BY o.order_date DESC;
```

### 8.7 JOIN 速查图

```
┌──────────────────────────────────────────────────┐
│                   JOIN 类型速查                    │
├──────────────┬───────────────────────────────────┤
│ INNER JOIN   │  ∩ 只要两边都有的                   │
│ LEFT JOIN    │  ← 左边全要，右边匹配不上填 NULL     │
│ RIGHT JOIN   │  → 右边全要，左边匹配不上填 NULL     │
│ CROSS JOIN   │  × 笛卡尔积，所有组合               │
│ Self JOIN    │  ↻ 自己连自己                       │
└──────────────┴───────────────────────────────────┘
```

> **💡 面试高频题：** LEFT JOIN 中把条件写在 `ON` 和 `WHERE` 里有什么区别？
> - `ON` 中的条件：不影响左表的行数，右表不满足条件的填 NULL
> - `WHERE` 中的条件：会过滤掉不满足条件的行（包括左表的行）
> ```sql
> -- 这两个查询结果不同！
> SELECT * FROM users u LEFT JOIN orders o ON u.id = o.user_id AND o.amount > 5000;
> SELECT * FROM users u LEFT JOIN orders o ON u.id = o.user_id WHERE o.amount > 5000;
> ```

---

## 第九章：索引 ⭐⭐ 性能关键

### 9.1 什么是索引？

索引就像**书的目录**：没有目录，你得一页一页翻（全表扫描）；有目录，直接翻到对应页码。

```
没有索引：SELECT * FROM users WHERE email = 'xxx'
→ 从第1行扫到最后1行，100万行全扫一遍 → 慢！

有索引：给 email 列建索引
→ 通过 B+Tree 直接定位 → 只需要 3~4 次磁盘IO → 快！
```

### 9.2 索引的底层结构（B+Tree）

MySQL InnoDB 的索引采用 **B+Tree** 结构：

```
               [30]
              /    \
         [10,20]   [40,50]
         / | \      / | \
      [1..9][10..19][20..29] [30..39][40..49][50..59]
                    ↑ 叶子节点存放实际数据（或主键指针）
                    ↑ 叶子节点之间用链表连接（便于范围查询）
```

**两种索引类型：**
- **聚簇索引（Clustered Index）**：主键索引，叶子节点存储**完整行数据**
- **二级索引（Secondary Index）**：非主键索引，叶子节点存储**主键值**

> **💡 回表：** 通过二级索引找到主键 → 再通过主键索引找到完整数据，这个过程叫**回表**。

### 9.3 索引操作

```sql
-- 创建普通索引
CREATE INDEX idx_username ON users(username);
-- 或者建表时
CREATE TABLE users (
    id INT PRIMARY KEY,
    username VARCHAR(50),
    INDEX idx_username (username)
);

-- 创建唯一索引（值不能重复）
CREATE UNIQUE INDEX idx_email ON users(email);

-- 创建联合索引（多列索引）⭐ 非常重要
CREATE INDEX idx_status_age ON users(status, age);

-- 查看表的索引
SHOW INDEX FROM users;

-- 删除索引
DROP INDEX idx_username ON users;
-- 或者
ALTER TABLE users DROP INDEX idx_username;
```

### 9.4 联合索引与最左前缀原则 ⭐ 面试必考

```sql
-- 建立联合索引 (a, b, c)
CREATE INDEX idx_abc ON table1(a, b, c);
```

**最左前缀原则**：查询条件必须从索引的**最左列**开始，才能使用索引。

```sql
-- ✅ 能用索引
WHERE a = 1                          -- 用到 a
WHERE a = 1 AND b = 2                -- 用到 a, b
WHERE a = 1 AND b = 2 AND c = 3     -- 用到 a, b, c（完美）
WHERE a = 1 AND c = 3               -- 只用到 a（c 跳过了 b，无法用）

-- ❌ 不能用索引
WHERE b = 2                          -- 没有最左列 a
WHERE c = 3                          -- 没有最左列 a
WHERE b = 2 AND c = 3                -- 没有最左列 a
```

> **💡 记忆口诀：** 联合索引像电话簿，先按姓排序，再按名排序。
> 你可以按"姓"查找，按"姓+名"查找，但不能跳过"姓"直接按"名"查找。

### 9.5 EXPLAIN 分析查询 ⭐

```sql
-- 在 SELECT 前加 EXPLAIN，查看执行计划
EXPLAIN SELECT * FROM users WHERE username = '张三';
```

**重点关注的列：**

| 列名          | 含义                    | 关注点                        |
|--------------|-------------------------|------------------------------|
| `type`       | 访问类型                 | **最重要！** 从好到差见下表     |
| `key`        | 实际使用的索引            | NULL 表示没走索引              |
| `rows`       | 预估扫描行数              | 越小越好                      |
| `Extra`      | 额外信息                 | 看是否有 filesort、temporary   |

**type 从好到差：**
```
system > const > eq_ref > ref > range > index > ALL
  最好                                          全表扫描（最差）
```

- `const` — 主键或唯一索引等值查询（最快）
- `ref` — 普通索引等值查询
- `range` — 索引范围查询（BETWEEN, >, <, IN）
- `ALL` — 全表扫描（需要优化！）

### 9.6 索引使用建议

```
✅ 应该建索引的情况：
  - WHERE 条件频繁使用的列
  - JOIN 的关联列（ON 条件的列）
  - ORDER BY / GROUP BY 的列
  - 区分度高的列（如 email），而非区分度低的列（如 gender）

❌ 不应该建索引的情况：
  - 表数据量很小（几百行）
  - 频繁更新的列（索引也需要更新，有开销）
  - 大量重复值的列（如 status 只有 0/1）

⚠️ 索引失效的常见情况：
  - 对索引列使用函数：WHERE YEAR(created_at) = 2024  ← 失效
  - 对索引列做运算：WHERE age + 1 = 25               ← 失效
  - 隐式类型转换：WHERE phone = 13800138000           ← phone是VARCHAR但传了数字
  - LIKE 以 % 开头：WHERE name LIKE '%张'             ← 失效
  - OR 条件中部分列没有索引                            ← 可能失效
```

---

## 第十章：约束（Constraint）

### 10.1 五大约束

```sql
CREATE TABLE students (
    -- 1. PRIMARY KEY 主键约束（唯一 + 非空）
    id INT PRIMARY KEY AUTO_INCREMENT,

    -- 2. NOT NULL 非空约束
    name VARCHAR(50) NOT NULL,

    -- 3. UNIQUE 唯一约束（允许 NULL，但非 NULL 值不能重复）
    student_no VARCHAR(20) UNIQUE,

    -- 4. DEFAULT 默认值约束
    status TINYINT DEFAULT 1,

    -- 5. FOREIGN KEY 外键约束
    class_id INT,
    FOREIGN KEY (class_id) REFERENCES classes(id)
);
```

### 10.2 外键详解

```sql
-- 创建班级表
CREATE TABLE classes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    class_name VARCHAR(50) NOT NULL
);

-- 创建学生表（外键关联班级表）
CREATE TABLE students (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    class_id INT,
    CONSTRAINT fk_class              -- 给外键起个名字
        FOREIGN KEY (class_id)       -- 本表的列
        REFERENCES classes(id)       -- 关联到 classes 表的 id
        ON DELETE SET NULL           -- 班级删除时，学生的 class_id 设为 NULL
        ON UPDATE CASCADE            -- 班级 id 更新时，学生的 class_id 跟着更新
);
```

**外键的级联操作：**

| 选项             | 含义                                    |
|------------------|-----------------------------------------|
| `CASCADE`        | 父表删除/更新时，子表跟着删除/更新         |
| `SET NULL`       | 父表删除/更新时，子表外键设为 NULL         |
| `RESTRICT`       | 父表有关联数据时，禁止删除/更新（默认）     |
| `NO ACTION`      | 同 RESTRICT                              |

> **💡 实际开发中的争议：** 很多互联网公司**不用外键**，原因是：
> - 外键会降低写入性能（每次 INSERT/UPDATE 都要检查）
> - 分库分表后外键无法跨库
> - 用应用层代码保证数据一致性更灵活
>
> 但对于**数据一致性要求极高**的系统（如金融），外键仍然有价值。

---

## 第十一章：事务（Transaction）⭐⭐

### 11.1 什么是事务？

事务是一组 SQL 操作，**要么全部成功，要么全部失败**。

**经典例子：转账**
```sql
-- 张三给李四转500元，需要两步：
UPDATE accounts SET balance = balance - 500 WHERE user = '张三';  -- 扣钱
UPDATE accounts SET balance = balance + 500 WHERE user = '李四';  -- 加钱
-- 如果第1步成功、第2步失败 → 钱凭空消失了！
-- 所以这两步必须在一个事务中
```

### 11.2 事务的 ACID 特性

| 特性        | 英文          | 含义                                            |
|------------|---------------|------------------------------------------------|
| **原子性** | Atomicity     | 事务中的操作要么全做，要么全不做                    |
| **一致性** | Consistency   | 事务前后，数据的完整性保持一致                      |
| **隔离性** | Isolation     | 多个事务并发执行时，互不干扰                       |
| **持久性** | Durability    | 事务提交后，数据永久保存，即使宕机也不丢失           |

### 11.3 事务操作

```sql
-- 开启事务
START TRANSACTION;
-- 或者
BEGIN;

-- 执行一系列操作
UPDATE accounts SET balance = balance - 500 WHERE user = '张三';
UPDATE accounts SET balance = balance + 500 WHERE user = '李四';

-- 如果一切正常，提交事务
COMMIT;

-- 如果出现问题，回滚事务（撤销所有操作）
ROLLBACK;
```

```sql
-- 实际使用模式（伪代码）
START TRANSACTION;
    UPDATE accounts SET balance = balance - 500 WHERE user = '张三';
    -- 检查张三余额是否足够
    SELECT balance FROM accounts WHERE user = '张三';
    -- 如果余额 < 0，回滚
    -- ROLLBACK;
    UPDATE accounts SET balance = balance + 500 WHERE user = '李四';
COMMIT;
```

### 11.4 事务隔离级别 ⭐ 面试重点

| 隔离级别              | 脏读  | 不可重复读 | 幻读  | 说明                    |
|----------------------|-------|-----------|-------|------------------------|
| `READ UNCOMMITTED`   | ✅ 有 | ✅ 有     | ✅ 有 | 最低，几乎不用           |
| `READ COMMITTED`     | ❌ 无 | ✅ 有     | ✅ 有 | Oracle 默认             |
| `REPEATABLE READ`    | ❌ 无 | ❌ 无     | ✅ 有 | **MySQL 默认** ⭐       |
| `SERIALIZABLE`       | ❌ 无 | ❌ 无     | ❌ 无 | 最高，性能最差           |

**三种并发问题解释：**
- **脏读**：事务A读到事务B**未提交**的数据（B回滚后，A读到的就是脏数据）
- **不可重复读**：同一事务中两次读取**同一行**，结果不同（被别的事务修改了）
- **幻读**：同一事务中两次查询，第二次多出了**新的行**（被别的事务插入了）

```sql
-- 查看当前隔离级别
SELECT @@transaction_isolation;

-- 设置隔离级别
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

> **💡 MySQL 的 InnoDB 通过 MVCC（多版本并发控制）+ Next-Key Lock
> 在 REPEATABLE READ 级别下也能**大幅避免幻读**，这是 MySQL 的独特优化。

---

## 第十二章：常用内置函数

### 12.1 字符串函数

```sql
-- 拼接字符串
SELECT CONCAT('Hello', ' ', 'World');           -- 'Hello World'
SELECT CONCAT_WS('-', '2024', '01', '15');      -- '2024-01-15'（用分隔符拼接）

-- 长度
SELECT LENGTH('Hello');          -- 5（字节数）
SELECT CHAR_LENGTH('你好');      -- 2（字符数）
SELECT LENGTH('你好');           -- 6（UTF-8 每个中文3字节）

-- 截取
SELECT SUBSTRING('Hello World', 1, 5);   -- 'Hello'（从第1个字符开始取5个）
SELECT LEFT('Hello', 3);                  -- 'Hel'
SELECT RIGHT('Hello', 3);                 -- 'llo'

-- 去空格
SELECT TRIM('  Hello  ');       -- 'Hello'
SELECT LTRIM('  Hello');        -- 'Hello'
SELECT RTRIM('Hello  ');        -- 'Hello'

-- 大小写
SELECT UPPER('hello');          -- 'HELLO'
SELECT LOWER('HELLO');          -- 'hello'

-- 替换
SELECT REPLACE('Hello World', 'World', 'MySQL');  -- 'Hello MySQL'

-- 反转
SELECT REVERSE('Hello');        -- 'olleH'

-- 填充
SELECT LPAD('42', 5, '0');      -- '00042'（左填充到5位）
SELECT RPAD('Hi', 5, '!');      -- 'Hi!!!'（右填充到5位）

-- 查找位置
SELECT INSTR('Hello World', 'World');    -- 7（找不到返回0）
SELECT LOCATE('World', 'Hello World');   -- 7（同上）
```

### 12.2 数学函数

```sql
SELECT ABS(-10);                -- 10（绝对值）
SELECT CEIL(4.1);               -- 5（向上取整）
SELECT FLOOR(4.9);              -- 4（向下取整）
SELECT ROUND(4.567, 2);         -- 4.57（四舍五入到2位小数）
SELECT TRUNCATE(4.567, 2);      -- 4.56（截断到2位小数，不四舍五入）
SELECT MOD(10, 3);              -- 1（取余 = 10 % 3）
SELECT RAND();                  -- 0~1之间的随机数
SELECT FLOOR(RAND() * 100);     -- 0~99之间的随机整数
```

### 12.3 日期时间函数

```sql
-- 获取当前时间
SELECT NOW();                   -- 2024-01-15 14:30:00
SELECT CURDATE();               -- 2024-01-15
SELECT CURTIME();               -- 14:30:00
SELECT UNIX_TIMESTAMP();        -- 时间戳（秒）

-- 提取日期部分
SELECT YEAR('2024-01-15');      -- 2024
SELECT MONTH('2024-01-15');     -- 1
SELECT DAY('2024-01-15');       -- 15
SELECT HOUR('14:30:00');        -- 14
SELECT DAYOFWEEK('2024-01-15'); -- 2（1=周日,2=周一...7=周六）
SELECT DAYNAME('2024-01-15');   -- 'Monday'

-- 日期格式化
SELECT DATE_FORMAT(NOW(), '%Y年%m月%d日 %H:%i:%s');
-- '2024年01月15日 14:30:00'

-- 常用格式符：
-- %Y 四位年, %m 两位月, %d 两位日
-- %H 24小时, %h 12小时, %i 分钟, %s 秒

-- 日期计算
SELECT DATE_ADD(NOW(), INTERVAL 7 DAY);    -- 7天后
SELECT DATE_ADD(NOW(), INTERVAL 3 MONTH);  -- 3个月后
SELECT DATE_SUB(NOW(), INTERVAL 1 YEAR);   -- 1年前
SELECT DATEDIFF('2024-12-31', '2024-01-01');  -- 365（两个日期相差天数）
SELECT TIMESTAMPDIFF(HOUR, '2024-01-01 00:00:00', '2024-01-01 08:30:00'); -- 8

-- 字符串转日期
SELECT STR_TO_DATE('2024-01-15', '%Y-%m-%d');
```

### 12.4 条件函数

```sql
-- IF 函数
SELECT IF(age >= 18, '成年', '未成年') AS '类型' FROM users;

-- IFNULL（如果为 NULL 则返回默认值）
SELECT IFNULL(phone, '未填写') FROM users;

-- COALESCE（返回第一个非 NULL 的值）
SELECT COALESCE(phone, email, '无联系方式') FROM users;

-- CASE WHEN（最灵活）
SELECT
    username,
    CASE status
        WHEN 0 THEN '禁用'
        WHEN 1 THEN '正常'
        WHEN 2 THEN '冻结'
        ELSE '未知'
    END AS '状态说明'
FROM users;

-- CASE WHEN 也可以做范围判断
SELECT
    username,
    CASE
        WHEN age < 18 THEN '未成年'
        WHEN age BETWEEN 18 AND 35 THEN '青年'
        WHEN age BETWEEN 36 AND 55 THEN '中年'
        ELSE '老年'
    END AS '年龄段'
FROM users;
```

---

## 第十三章：视图（View）

### 13.1 什么是视图？

视图是一个**虚拟表**，本身不存储数据，只保存一条 SQL 查询。
每次查询视图时，都会执行底层的 SQL。

**用途：**
- 简化复杂查询（把常用的多表 JOIN 封装为视图）
- 控制权限（只暴露部分列给某些用户）
- 提供统一的数据接口

### 13.2 视图操作

```sql
-- 创建视图
CREATE VIEW v_user_orders AS
SELECT
    u.id AS user_id,
    u.username,
    COUNT(o.id) AS order_count,
    IFNULL(SUM(o.amount), 0) AS total_amount
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.username;

-- 使用视图（和普通表一样查）
SELECT * FROM v_user_orders;
SELECT * FROM v_user_orders WHERE total_amount > 1000;

-- 修改视图
CREATE OR REPLACE VIEW v_user_orders AS
SELECT ... ;  -- 新的查询

-- 删除视图
DROP VIEW v_user_orders;
DROP VIEW IF EXISTS v_user_orders;

-- 查看所有视图
SHOW FULL TABLES WHERE Table_type = 'VIEW';
```

> **⚠️ 视图注意事项：**
> - 视图不能提升查询性能（每次都要执行底层SQL）
> - 复杂视图（含 GROUP BY、DISTINCT、子查询等）**不能通过视图更新数据**
> - 简单视图（单表无聚合）可以通过视图执行 INSERT/UPDATE/DELETE

---

## 第十四章：存储过程与函数

### 14.1 存储过程（Stored Procedure）

存储过程是**预编译好的一段 SQL 代码**，存储在数据库中，可以反复调用。

```sql
-- 修改分隔符（因为存储过程中有多个分号）
DELIMITER //

CREATE PROCEDURE sp_get_user_by_status(IN p_status TINYINT)
BEGIN
    SELECT * FROM users WHERE status = p_status;
END //

DELIMITER ;

-- 调用存储过程
CALL sp_get_user_by_status(1);
```

**参数类型：**
- `IN` — 输入参数（默认）
- `OUT` — 输出参数
- `INOUT` — 既是输入又是输出

```sql
DELIMITER //

CREATE PROCEDURE sp_transfer(
    IN from_user INT,
    IN to_user INT,
    IN transfer_amount DECIMAL(10,2),
    OUT result VARCHAR(50)
)
BEGIN
    DECLARE from_balance DECIMAL(10,2);

    -- 开启事务
    START TRANSACTION;

    -- 查询余额
    SELECT balance INTO from_balance FROM accounts WHERE id = from_user FOR UPDATE;

    IF from_balance < transfer_amount THEN
        SET result = '余额不足';
        ROLLBACK;
    ELSE
        UPDATE accounts SET balance = balance - transfer_amount WHERE id = from_user;
        UPDATE accounts SET balance = balance + transfer_amount WHERE id = to_user;
        SET result = '转账成功';
        COMMIT;
    END IF;
END //

DELIMITER ;

-- 调用
CALL sp_transfer(1, 2, 500.00, @result);
SELECT @result;  -- '转账成功' 或 '余额不足'
```

### 14.2 存储函数（Function）

```sql
DELIMITER //

CREATE FUNCTION fn_age_group(p_age INT)
RETURNS VARCHAR(20)
DETERMINISTIC        -- 表示相同输入总是相同输出
BEGIN
    IF p_age < 18 THEN
        RETURN '未成年';
    ELSEIF p_age <= 35 THEN
        RETURN '青年';
    ELSEIF p_age <= 55 THEN
        RETURN '中年';
    ELSE
        RETURN '老年';
    END IF;
END //

DELIMITER ;

-- 在 SQL 中使用函数
SELECT username, age, fn_age_group(age) AS '年龄段' FROM users;
```

> **💡 存储过程 vs 函数：**
> | 对比项       | 存储过程 (PROCEDURE)      | 函数 (FUNCTION)          |
> |-------------|--------------------------|--------------------------|
> | 调用方式    | `CALL sp_name()`          | `SELECT fn_name()`      |
> | 返回值      | 通过 OUT 参数返回          | 必须有 RETURN 值         |
> | 在SQL中使用  | ❌ 不能直接嵌入 SQL        | ✅ 可以在 SELECT 中使用   |
> | 事务        | ✅ 可以包含事务            | ❌ 不建议包含事务         |

### 14.3 管理存储过程和函数

```sql
-- 查看
SHOW PROCEDURE STATUS WHERE Db = 'mydb';
SHOW FUNCTION STATUS WHERE Db = 'mydb';
SHOW CREATE PROCEDURE sp_transfer;

-- 删除
DROP PROCEDURE IF EXISTS sp_transfer;
DROP FUNCTION IF EXISTS fn_age_group;
```

---

## 第十五章：锁机制

### 15.1 锁的分类

```
按粒度分：
├── 全局锁 —— 锁整个数据库（备份时使用）
├── 表级锁 —— 锁整张表
│   ├── 表锁（READ LOCK / WRITE LOCK）
│   └── 元数据锁（MDL，自动加）
└── 行级锁 —— 锁某一行（InnoDB 特有）⭐
    ├── 记录锁（Record Lock）—— 锁住单行
    ├── 间隙锁（Gap Lock）—— 锁住两行之间的间隙
    └── 临键锁（Next-Key Lock）—— 记录锁 + 间隙锁

按模式分：
├── 共享锁（S锁 / 读锁）—— 多个事务可以同时读
└── 排他锁（X锁 / 写锁）—— 只有一个事务能写
```

### 15.2 行锁实践

```sql
-- 共享锁（S锁）：允许其他事务读，但不允许写
SELECT * FROM users WHERE id = 1 LOCK IN SHARE MODE;
-- MySQL 8.0+ 推荐写法：
SELECT * FROM users WHERE id = 1 FOR SHARE;

-- 排他锁（X锁）：其他事务既不能读也不能写
SELECT * FROM users WHERE id = 1 FOR UPDATE;
-- 常用于"先查再改"场景，防止并发问题
```

```sql
-- 经典场景：扣库存（防止超卖）
START TRANSACTION;

-- 加排他锁查询库存
SELECT stock FROM products WHERE id = 1 FOR UPDATE;
-- 假设 stock = 10

-- 扣减库存
UPDATE products SET stock = stock - 1 WHERE id = 1 AND stock > 0;

COMMIT;
```

### 15.3 死锁

**死锁**：两个事务互相等待对方释放锁。

```sql
-- 事务A                          -- 事务B
START TRANSACTION;                START TRANSACTION;
UPDATE users SET ... WHERE id=1;  UPDATE users SET ... WHERE id=2;
-- A 持有 id=1 的锁               -- B 持有 id=2 的锁
UPDATE users SET ... WHERE id=2;  UPDATE users SET ... WHERE id=1;
-- A 等待 id=2 的锁 ← 死锁！     -- B 等待 id=1 的锁 ← 死锁！
```

> **💡 MySQL 自动检测死锁**，会回滚其中一个事务。但我们应该尽量避免：
> - 按固定顺序访问表和行
> - 事务尽量短小
> - 使用合理的索引减少锁范围

---

## 第十六章：用户与权限管理

### 16.1 用户管理

```sql
-- 创建用户
CREATE USER 'zhangsan'@'localhost' IDENTIFIED BY 'password123';
-- 'localhost' 表示只能本地登录

-- 允许远程登录
CREATE USER 'zhangsan'@'%' IDENTIFIED BY 'password123';
-- '%' 表示任何IP都能登录

-- 修改密码
ALTER USER 'zhangsan'@'localhost' IDENTIFIED BY 'new_password';

-- 删除用户
DROP USER 'zhangsan'@'localhost';

-- 查看所有用户
SELECT User, Host FROM mysql.user;
```

### 16.2 权限管理

```sql
-- 授予权限
GRANT SELECT, INSERT ON mydb.users TO 'zhangsan'@'localhost';
-- 只给 mydb 库 users 表的查询和插入权限

-- 授予某个库的所有权限
GRANT ALL PRIVILEGES ON mydb.* TO 'zhangsan'@'localhost';

-- 授予所有库的所有权限（慎用！）
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';

-- 刷新权限（使更改生效）
FLUSH PRIVILEGES;

-- 查看用户权限
SHOW GRANTS FOR 'zhangsan'@'localhost';

-- 撤销权限
REVOKE INSERT ON mydb.users FROM 'zhangsan'@'localhost';
REVOKE ALL PRIVILEGES ON mydb.* FROM 'zhangsan'@'localhost';
```

> **💡 最小权限原则：** 只授予用户完成工作所需的最小权限。
> 应用程序用的数据库账号**绝对不要用 root**！

---

## 第十七章：性能优化实战 ⭐⭐⭐

### 17.1 慢查询日志

```sql
-- 查看是否开启
SHOW VARIABLES LIKE 'slow_query_log';

-- 开启慢查询日志
SET GLOBAL slow_query_log = ON;

-- 设置阈值（超过2秒的查询记录下来）
SET GLOBAL long_query_time = 2;

-- 查看慢查询日志位置
SHOW VARIABLES LIKE 'slow_query_log_file';
```

### 17.2 SQL 优化要点

```
1. SELECT 优化
   ❌ SELECT * FROM users;                    -- 不要用 *
   ✅ SELECT id, username, email FROM users;  -- 只查需要的列

2. 分页优化
   ❌ SELECT * FROM users LIMIT 1000000, 10;  -- 偏移量大时极慢
   ✅ SELECT * FROM users WHERE id > 1000000 LIMIT 10;  -- 用主键定位

3. COUNT 优化
   ❌ SELECT COUNT(*) FROM users WHERE status = 1;  -- 每次都全表扫
   ✅ 使用缓存（Redis）存储计数，或使用汇总表

4. JOIN 优化
   ✅ 小表驱动大表（小表放左边）
   ✅ JOIN 的关联列一定要建索引
   ✅ 避免超过3张表的 JOIN

5. WHERE 优化
   ❌ WHERE YEAR(created_at) = 2024           -- 函数导致索引失效
   ✅ WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'
   
   ❌ WHERE age + 1 = 25                      -- 运算导致索引失效
   ✅ WHERE age = 24

6. IN 优化
   ❌ WHERE id IN (SELECT ... 很多数据)       -- 子查询可能很慢
   ✅ WHERE id IN (1,2,3,...少量数据)          -- 少量 OK
   ✅ 改用 JOIN 代替大量 IN 子查询
```

### 17.3 表设计优化

```
1. 选择合适的数据类型
   ✅ 能用 TINYINT 就不用 INT
   ✅ 能用 VARCHAR(50) 就不用 VARCHAR(255)
   ✅ IP 地址用 INT UNSIGNED（INET_ATON/INET_NTOA 转换）

2. 适度反范式化
   ✅ 高频查询的冗余字段可以减少 JOIN
   例：订单表冗余存储用户名，避免每次查订单都 JOIN 用户表

3. 大表处理
   ✅ 垂直拆分：把不常用的大字段拆到扩展表
   ✅ 水平拆分（分表）：按 ID 范围 或 取模 分到多张表
   ✅ 分库：数据量极大时，分到多个数据库实例

4. 合理使用存储引擎
   ✅ InnoDB：默认选择，支持事务、行锁、外键
   ⚠️ MyISAM：只读或读多写少场景，支持全文索引
```

### 17.4 配置优化（my.cnf 关键参数）

```ini
[mysqld]
# InnoDB 缓冲池大小（建议设为物理内存的 60%~80%）
innodb_buffer_pool_size = 4G

# 日志缓冲区
innodb_log_buffer_size = 64M

# 最大连接数
max_connections = 500

# 查询缓存（MySQL 8.0 已移除）
# query_cache_size = 0  

# 排序缓冲
sort_buffer_size = 4M

# 连接超时
wait_timeout = 28800
interactive_timeout = 28800
```

---

## 第十八章：SQL 编写规范与最佳实践

### 18.1 命名规范

```
✅ 推荐的命名规范：
  - 表名：小写，下划线分隔，名词复数  → users, order_items
  - 列名：小写，下划线分隔            → created_at, user_id
  - 索引名：idx_表名_列名              → idx_users_email
  - 唯一索引：uk_表名_列名             → uk_users_email
  - 外键名：fk_表名_列名              → fk_orders_user_id
  - 主键：统一用 id
  - 外键列：关联表名单数_id            → user_id, order_id

❌ 避免：
  - 使用 MySQL 保留字作列名（如 order, select, index）
  - 使用中文列名
  - 使用驼峰命名（不是不行，但大小写可能导致跨平台问题）
```

### 18.2 SQL 编写习惯

```sql
-- ✅ 好的 SQL 风格
SELECT
    u.id,
    u.username,
    u.email,
    COUNT(o.id) AS order_count,
    IFNULL(SUM(o.amount), 0) AS total_amount
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.status = 1
  AND u.created_at >= '2024-01-01'
GROUP BY u.id, u.username, u.email
HAVING order_count > 0
ORDER BY total_amount DESC
LIMIT 20;

-- ❌ 差的 SQL 风格（一坨全挤在一行）
SELECT u.id,u.username,u.email,COUNT(o.id),SUM(o.amount) FROM users u LEFT JOIN orders o ON u.id=o.user_id WHERE u.status=1 AND u.created_at>='2024-01-01' GROUP BY u.id,u.username,u.email HAVING COUNT(o.id)>0 ORDER BY SUM(o.amount) DESC LIMIT 20;
```

### 18.3 安全规范

```
1. 永远不要拼接 SQL → 使用参数化查询防止 SQL 注入
   ❌ "SELECT * FROM users WHERE id = " + userId
   ✅ "SELECT * FROM users WHERE id = ?" + 绑定参数

2. 生产环境禁止：
   ❌ SELECT * （查所有列）
   ❌ 不带 WHERE 的 UPDATE / DELETE
   ❌ 直接用 root 账号
   ❌ 在业务高峰期执行 ALTER TABLE

3. 备份策略：
   ✅ 定期全量备份（mysqldump / xtrabackup）
   ✅ 开启 binlog 做增量备份 / 主从复制
   ✅ 测试备份的恢复流程（备份没测试恢复 = 没有备份）
```

---

## 第十九章：常用操作速查表

### 19.1 一条 SQL 的完整语法顺序

```sql
SELECT [DISTINCT] 列名, 聚合函数
FROM 表名
[JOIN 表名 ON 条件]
[WHERE 条件]
[GROUP BY 列名]
[HAVING 条件]
[ORDER BY 列名 ASC|DESC]
[LIMIT 偏移量, 数量];
```

**书写顺序 vs 执行顺序：**
```
书写顺序：SELECT → FROM → JOIN → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
执行顺序：FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
          ① ②     ③      ④       ⑤       ⑥        ⑦        ⑧
```

### 19.2 数据库备份与恢复

```bash
# 备份整个数据库
mysqldump -u root -p mydb > mydb_backup.sql

# 备份指定表
mysqldump -u root -p mydb users orders > tables_backup.sql

# 备份所有数据库
mysqldump -u root -p --all-databases > all_backup.sql

# 恢复数据库
mysql -u root -p mydb < mydb_backup.sql

# 在 MySQL 内部恢复
SOURCE /path/to/mydb_backup.sql;
```

### 19.3 日常运维命令

```sql
-- 查看正在执行的查询
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- 杀掉某个查询（ID 从 PROCESSLIST 获取）
KILL 12345;

-- 查看表占用空间
SELECT
    table_name,
    ROUND(data_length / 1024 / 1024, 2) AS '数据大小(MB)',
    ROUND(index_length / 1024 / 1024, 2) AS '索引大小(MB)',
    table_rows AS '大约行数'
FROM information_schema.tables
WHERE table_schema = 'mydb'
ORDER BY data_length DESC;

-- 查看 MySQL 状态
SHOW STATUS LIKE 'Threads_connected';   -- 当前连接数
SHOW STATUS LIKE 'Slow_queries';        -- 慢查询次数
SHOW VARIABLES LIKE 'max_connections';  -- 最大连接数

-- 优化表（回收碎片空间）
OPTIMIZE TABLE users;

-- 分析表（更新索引统计信息）
ANALYZE TABLE users;
```

---

## 🎓 学习路线总结

```
┌─────────────────────────────────────────────────────────┐
│                    MySQL 学习路线                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  第一阶段：基础入门                                       │
│  ├── 数据库/表的创建和管理（DDL）                          │
│  ├── 增删改查（INSERT/SELECT/UPDATE/DELETE）              │
│  ├── WHERE 条件、ORDER BY、LIMIT                        │
│  └── 数据类型、约束                                      │
│                                                         │
│  第二阶段：进阶查询                                       │
│  ├── 聚合函数、GROUP BY、HAVING                          │
│  ├── 子查询                                             │
│  ├── JOIN 多表连接 ⭐                                    │
│  └── 常用内置函数                                        │
│                                                         │
│  第三阶段：深入理解                                       │
│  ├── 索引原理与优化 ⭐⭐                                 │
│  ├── 事务与隔离级别 ⭐⭐                                 │
│  ├── 锁机制                                             │
│  └── 视图、存储过程                                      │
│                                                         │
│  第四阶段：实战优化                                       │
│  ├── EXPLAIN 执行计划分析                                │
│  ├── SQL 性能优化                                       │
│  ├── 表设计与范式                                        │
│  └── 备份恢复、用户权限                                   │
│                                                         │
│  第五阶段：高级架构（可选）                                │
│  ├── 主从复制                                           │
│  ├── 读写分离                                           │
│  ├── 分库分表                                           │
│  └── MySQL 集群                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

> **🎉 恭喜你！** 学完这份教程，你已经掌握了 MySQL 从入门到实战的核心知识。
> 接下来最重要的是：**多写 SQL、多练习、多踩坑**，实战是最好的老师！
