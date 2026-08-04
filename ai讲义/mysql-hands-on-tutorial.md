# MySQL 零基础逐行带练教程（全本）

> 💡 **学习方法**：
> 每一个章节都包含三个部分：
> 1. **【本节目标】**：告诉你这一节要演示什么、教会你解决什么问题。
> 2. **【实操代码】**：直接复制框内的 SQL 语句到 MySQL 终端运行。
> 3. **【逐行解析】**：对上面代码的每一行、每一个关键字进行深度拆解，告诉你“为什么这么写”以及“返回结果怎么看”。

---

## 第一章：连接 MySQL 与数据库管理

### 1.1 登录 MySQL 与查看服务器信息

#### 🎯 【本节目标】
教会你如何登录 MySQL 控制台、查看当前 MySQL 的版本以及当前登录的用户身份，确保你的 MySQL 服务正常运行。

#### 💻 【实操代码】

```bash
# 步骤 1：在 macOS / Linux 终端输入以下命令登录（提示输入密码时输入你的 root 密码）
mysql -u root -p
```

登录成功看到 `mysql>` 提示符后，依次输入并运行以下 SQL：

```sql
-- 查看 MySQL 的版本
SELECT VERSION();

-- 查看当前登录的用户及允许连接的主机
SELECT USER();
```

#### 🔍 【逐行解析】

* **`mysql -u root -p`**
  * `-u root`：`-u` 代表 User（用户），`root` 是 MySQL 的最高管理员账号。
  * `-p`：`-p` 代表 Password（密码），执行后系统会安全地等待你输入密码（输入的密码不会在屏幕上显示）。
* **`SELECT VERSION();`**
  * `SELECT`：MySQL 中用于查询数据的核心关键字，相当于“请告诉我...”。
  * `VERSION()`：MySQL 内置函数，用于获取当前数据库引擎的版本号（例如 `8.0.35`）。
  * `;`：**分号是 SQL 语句的结束标记**！如果不敲分号回车，MySQL 会认为你的命令还没输完，会一直等待。
  * *运行结果解析*：你会看到一个表格，列名为 `VERSION()`，下方显示具体的版本号。
* **`SELECT USER();`**
  * `USER()`：内置函数，返回 `用户名@主机名`。
  * *运行结果解析*：通常返回 `root@localhost`，表示你正以 `root` 用户身份从本机（`localhost`）登录。

---

### 1.2 创建并切换数据库

#### 🎯 【本节目标】
演示如何安全地创建一个数据库（避免因为数据库已存在而报错），设置支持中文和 Emoji 的字符集，并切换到该数据库中。

#### 💻 【实操代码】

```sql
-- 1. 创建数据库（带有安全防护和字符集设置）
CREATE DATABASE IF NOT EXISTS shop_db 
  DEFAULT CHARACTER SET utf8mb4 
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- 2. 查看当前 MySQL 中所有的数据库
SHOW DATABASES;

-- 3. 切换/选择 shop_db 数据库
USE shop_db;

-- 4. 确认当前正在使用的是哪个数据库
SELECT DATABASE();
```

#### 🔍 【逐行解析】

* **`CREATE DATABASE IF NOT EXISTS shop_db`**
  * `CREATE DATABASE`：数据定义指令，意思是“新建一个数据库”。
  * `IF NOT EXISTS`：**防错机制**！意思是“如果这个库还不存在才创建”。如果库已经存在了，MySQL 只会给一个 Warning（警告），而不会直接中断报错。
  * `shop_db`：我们要创建的数据库名称。
* **`DEFAULT CHARACTER SET utf8mb4`**
  * `DEFAULT CHARACTER SET`：指定数据库默认的字符编码格式。
  * `utf8mb4`：**极其重要**！MySQL 历史遗留的 `utf8` 实际上只能存最多 3 字节字符。而 `utf8mb4` 才是真正的 UTF-8（支持 4 字节），能够完整支持中文汉字、特殊符号以及表情包（Emoji 😊）。
* **`DEFAULT COLLATE utf8mb4_unicode_ci`**
  * `COLLATE`：字符排序规则。
  * `utf8mb4_unicode_ci`：`ci` 代表 `Case Insensitive`（大小写不敏感），在进行字符串比较和排序时更准确且标准。
* **`SHOW DATABASES;`**
  * 显示当前 MySQL 服务器上所有的数据库列表。
  * *运行结果解析*：你会看到列表里除了你刚刚创建的 `shop_db`，还有 `information_schema`、`mysql`、`sys` 等系统自带的数据库。
* **`USE shop_db;`**
  * `USE`：切换当前工作环境。告诉 MySQL：“接下来的所有表操作，都在 `shop_db` 里面搞”。
  * *运行结果解析*：终端会返回 `Database changed`（数据库已切换）。
* **`SELECT DATABASE();`**
  * `DATABASE()`：内置函数，返回当前激活的数据库名称。
  * *运行结果解析*：表格中会清晰地显示 `shop_db`。

---

## 第二章：数据表定义与数据类型（DDL）

#### 🎯 【本节目标】
教会你如何设计一个电商系统的核心表——用户表 `users`。掌握常见数据类型（整数、变长字符串、精准小数、时间类型）的挑选原则，以及各种约束（主键、自增、非空、唯一、默认值、注释）的书写规范。

#### 💻 【实操代码】

```sql
-- 创建用户表 users
CREATE TABLE IF NOT EXISTS users (
    id          INT PRIMARY KEY AUTO_INCREMENT COMMENT '用户唯一标识ID',
    username    VARCHAR(50) NOT NULL COMMENT '用户名',
    email       VARCHAR(100) UNIQUE COMMENT '邮箱',
    age         TINYINT UNSIGNED COMMENT '年龄',
    balance     DECIMAL(10, 2) DEFAULT 0.00 COMMENT '账户余额（元）',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户信息表';

-- 查看当前数据库中的所有表
SHOW TABLES;

-- 查看 users 表的具体结构定义
DESC users;
```

#### 🔍 【逐行解析】

* **`CREATE TABLE IF NOT EXISTS users (`**
  * `CREATE TABLE`：告诉 MySQL“我要建一张表”，表名为 `users`。
  * `IF NOT EXISTS`：同理，如果表已存在则忽略，避免脚本重复执行报错。
* **`id INT PRIMARY KEY AUTO_INCREMENT COMMENT '用户唯一标识ID',`**
  * `id`：列名（字段名）。
  * `INT`：数据类型，占用 4 个字节，可表示 -21 亿到 +21 亿的数字。
  * `PRIMARY KEY`：**主键约束**！一张表只能有一个主键，用来唯一标识每一行数据，且主键绝不允许为 `NULL`。
  * `AUTO_INCREMENT`：**自动递增**！插入新数据时你不需要手动给 id 传值，MySQL 会自动递增（1, 2, 3...）。
  * `COMMENT '...'`：字段注释，提高代码的可读性，方便后续团队协作。
* **`username VARCHAR(50) NOT NULL COMMENT '用户名',`**
  * `VARCHAR(50)`：**可变长度字符串**，最多存 50 个字符。存 "abc" 就只占 3 个字符的空间，节省磁盘。
  * `NOT NULL`：**非空约束**，插入或更新数据时，这个字段绝对不能留空，否则拒绝写入。
* **`email VARCHAR(100) UNIQUE COMMENT '邮箱',`**
  * `UNIQUE`：**唯一约束**！表示全表所有用户的 email 绝不能重复。如果插入两个相同的邮箱，MySQL 会直接报错拦截。
* **`age TINYINT UNSIGNED COMMENT '年龄',`**
  * `TINYINT`：超小整数，只占 1 字节（范围 -128 ~ 127）。
  * `UNSIGNED`：**无符号**！去掉负数部分，范围变成 `0 ~ 255`。因为人类年龄不可能为负数，用 `TINYINT UNSIGNED` 最省空间。
* **`balance DECIMAL(10, 2) DEFAULT 0.00 COMMENT '账户余额（元）',`**
  * `DECIMAL(10, 2)`：**精确小数类型**！`10` 表示总共最多允许 10 位数字，`2` 表示保留 2 位小数。
  * ⚠️ **重要规则**：涉及金额、货币等敏感数据，**绝对不能用 FLOAT 或 DOUBLE**（因为浮点数有精度损失），必须使用 `DECIMAL`！
  * `DEFAULT 0.00`：**默认值**。插入数据如果不传余额，系统自动设为 `0.00`。
* **`created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间'`**
  * `DATETIME`：日期时间类型，格式为 `YYYY-MM-DD HH:MM:SS`。
  * `DEFAULT CURRENT_TIMESTAMP`：默认值为当前系统时间！即哪一秒插入这条数据，就自动把当时的时间填进去。
* **`) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户信息表';`**
  * `ENGINE=InnoDB`：指定存储引擎为 `InnoDB`（MySQL 5.5+ 的默认引擎，支持事务、行级锁和外键）。
* **`SHOW TABLES;`**
  * 列出当前库下的所有表。*运行结果*：输出包含 `users` 的表格。
* **`DESC users;`**
  * `DESC`（`DESCRIBE` 的缩写）：查看表的结构。
  * *运行结果解析*：你会看到一个包含 6 列的表格：
    * `Field`（字段名）
    * `Type`（数据类型）
    * `Null`（是否允许为空：YES/NO）
    * `Key`（索引情况：PRI 表示主键，UNI 表示唯一索引）
    * `Default`（默认值）
    * `Extra`（额外属性：如 auto_increment）

---

## 第三章：数据的增删改查实操（DML 基础）

#### 🎯 【本节目标】
教会你如何向表中插入单条/多条数据，如何安全地更新数据（避免误抹全表），以及如何删除数据与重置自增 ID。

#### 💻 【实操代码】

```sql
-- 1. 单条插入：指定列名插入数据
INSERT INTO users (username, email, age, balance) 
VALUES ('张三', 'zhangsan@qq.com', 25, 1000.00);

-- 2. 批量插入：一次性插入多条数据（推荐写法）
INSERT INTO users (username, email, age, balance) VALUES
('李四', 'lisi@163.com', 32, 5000.50),
('王五', 'wangwu@gmail.com', 19, 200.00),
('赵六', 'zhaoliu@qq.com', 45, 12000.00),
('钱七', 'qianqi@163.com', 28, 0.00);

-- 3. 全表查询：验证插入的数据
SELECT * FROM users;

-- 4. 更新数据：给张三账户充值 500 元
UPDATE users 
SET balance = balance + 500 
WHERE username = '张三';

-- 5. 查看更新后的张三账户余额
SELECT username, balance FROM users WHERE username = '张三';

-- 6. 条件删除：删除用户名为 '钱七' 的记录
DELETE FROM users 
WHERE username = '钱七';

-- 7. 验证删除结果
SELECT * FROM users;
```

#### 🔍 【逐行解析】

* **`INSERT INTO users (username, email, age, balance) VALUES ('张三', ...);`**
  * `INSERT INTO 表名 (列1, 列2...)`：明确指定你要往哪几列写入数据。
  * 为什么没写 `id` 和 `created_at`？
    * 因为 `id` 设了 `AUTO_INCREMENT`，MySQL 会自动生成；
    * `created_at` 设了 `DEFAULT CURRENT_TIMESTAMP`，MySQL 会自动取当前时间。
  * `VALUES (...)`：括号内填入具体的数值，字符串和日期必须用单引号 `'` 包裹！
* **`INSERT INTO users ... VALUES (...), (...), (...);`**
  * 批量插入语法：用逗号 `,` 分隔多组小括号。
  * 💡 **性能优势**：在真实开发中，1 次批量插入 1000 条数据，比用循环执行 1000 次单条插入快 **20 ~ 50 倍**（大幅减少了网络往返和磁盘开销）！
* **`SELECT * FROM users;`**
  * `*`：通配符，代表“查出表中的所有列”。
  * *运行结果解析*：展示包含 5 行记录的表，你可以看到 `id` 自动填成了 `1, 2, 3, 4, 5`，`created_at` 也填入了现在的精确时间。
* **`UPDATE users SET balance = balance + 500 WHERE username = '张三';`**
  * `UPDATE 表名`：表明要执行修改数据操作。
  * `SET balance = balance + 500`：要修改的列及运算逻辑，把原本的余额加上 500。
  * `WHERE username = '张三'`：**条件过滤**！声明只更新用户名是张三的那一行。
  * ⚠️ **血泪警告**：**写 UPDATE 语句时，永远先写 WHERE 条件！** 如果漏掉了 `WHERE`，整个表中所有人的余额都会被改成 `+500`，造成生产环境重大事故！
* **`SELECT username, balance FROM users WHERE username = '张三';`**
  * 只查询 `username` 和 `balance` 两个字段。
  * *运行结果解析*：张三的余额成功从 `1000.00` 变成了 `1500.00`。
* **`DELETE FROM users WHERE username = '钱七';`**
  * `DELETE FROM 表名`：删除符合条件的数据行。
  * `WHERE username = '钱七'`：同样地，`DELETE` **必须加 WHERE 条件**，否则会把全表数据清空！
  * *运行结果解析*：返回 `Query OK, 1 row affected`（影响了 1 行数据）。再次运行 `SELECT * FROM users` 时，钱七那一行记录已经不存在了。

---

## 第四章：高级查询与条件过滤（WHERE / ORDER BY / LIMIT）

#### 🎯 【本节目标】
教会你如何使用比较运算符（`>`、`<`）、范围匹配（`BETWEEN`）、模糊搜索（`LIKE`）精确筛选目标数据，以及如何对查询结果按单列/多列进行排序，并使用 `LIMIT` 实现翻页功能。

#### 💻 【实操代码】

```sql
-- 1. 范围筛选：查找年龄在 20 到 35 岁之间的用户
SELECT username, age, balance 
FROM users 
WHERE age BETWEEN 20 AND 35;

-- 2. 模糊查询：查找邮箱以 '@qq.com' 结尾的用户
SELECT username, email 
FROM users 
WHERE email LIKE '%@qq.com';

-- 3. 组合条件：查找账户余额大于 1000 元 且 年龄小于 40 岁的用户
SELECT username, balance, age 
FROM users 
WHERE balance > 1000 AND age < 40;

-- 4. 排序：按账户余额从高到低降序排列
SELECT username, balance 
FROM users 
ORDER BY balance DESC;

-- 5. 分页查询：取余额最高的前 2 名用户（第一页）
SELECT username, balance 
FROM users 
ORDER BY balance DESC 
LIMIT 2;

-- 6. 分页查询：跳过前 2 名，取接下来 2 名用户（第二页）
SELECT username, balance 
FROM users 
ORDER BY balance DESC 
LIMIT 2 OFFSET 2;
```

#### 🔍 【逐行解析】

* **`WHERE age BETWEEN 20 AND 35;`**
  * `BETWEEN A AND B`：等价于 `age >= 20 AND age <= 35`（包含 20 和 35 边界值）。
  * *运行结果解析*：筛选出张三（25岁）、李四（32岁）。
* **`WHERE email LIKE '%@qq.com';`**
  * `LIKE`：模糊匹配关键字。
  * `%`：通配符，匹配**零个或任意多个字符**。`'%@qq.com'` 表示“不管前面是什么，只要以 `@qq.com` 结尾就行”。
  * `_`（下划线）：另一个通配符，恰好匹配**一个**字符（如 `'张_'` 只能匹配“张三”，不能匹配“张三丰”）。
* **`WHERE balance > 1000 AND age < 40;`**
  * `AND`：逻辑与，要求两个条件同时为真。
  * `OR`：逻辑或，满足其中一个条件即可。
  * ⚠️ **优先级规则**：`AND` 的优先级高于 `OR`。如果混合使用 `AND` 和 `OR`，务必使用英文括号 `()` 把优先级明确扩起来！
* **`ORDER BY balance DESC;`**
  * `ORDER BY 列名`：对结果集进行排序。
  * `DESC`（Descending）：**降序**（从大到小、从高到低）。
  * `ASC`（Ascending）：**升序**（从小到大，不写 `DESC/ASC` 默认就是升序）。
* **`LIMIT 2;`**
  * 限制只返回结果集的前 2 条记录。
* **`LIMIT 2 OFFSET 2;`**
  * `LIMIT 数量 OFFSET 偏移量`：
    * `OFFSET 2` 意思是“跳过前 2 条记录”；
    * `LIMIT 2` 意思是“接着往下取 2 条记录”。
  * 💡 **公式**：在做前端翻页组件时，`第 n 页`，每页 `size` 条数据的写法为：
    `LIMIT size OFFSET (n - 1) * size`。

---

## 第五章：聚合统计与分组（GROUP BY & HAVING）

#### 🎯 【本节目标】
教会你使用内置聚合函数（求和、求平均、计数、极值），以及如何使用 `GROUP BY` 把数据分组汇总，并彻底区分 `WHERE` 与 `HAVING` 的用法。

#### 💻 【实操代码】

```sql
-- 1. 全表基础聚合：统计用户总数、最高余额、平均年龄
SELECT 
    COUNT(*) AS 用户总数,
    MAX(balance) AS 最高余额,
    MIN(balance) AS 最低余额,
    ROUND(AVG(age), 1) AS 平均年龄
FROM users;

-- 2. 分组统计：按年龄段把用户分组，统计每组人数
SELECT 
    CASE 
        WHEN age < 30 THEN '青年(30岁以下)'
        ELSE '中老年(30岁及以上)'
    END AS 年龄分组,
    COUNT(*) AS 人数,
    AVG(balance) AS 平均余额
FROM users
GROUP BY 年龄分组;

-- 3. 分组后过滤（HAVING）：只查看人数大于等于 2 人的分组
SELECT 
    CASE 
        WHEN age < 30 THEN '青年(30岁以下)'
        ELSE '中老年(30岁及以上)'
    END AS 年龄分组,
    COUNT(*) AS 人数
FROM users
GROUP BY 年龄分组
HAVING 人数 >= 2;
```

#### 🔍 【逐行解析】

* **`COUNT(*) AS 用户总数`**
  * `COUNT(*)`：统计总行数（包含 NULL 值）。
  * `COUNT(age)`：只统计 `age` 这一列不为 `NULL` 的行数。
  * `AS 别名`：给计算出来的结果列起一个好看的中文名，方便前端或报表展示。
* **`ROUND(AVG(age), 1)`**
  * `AVG(age)`：计算年龄的平均值。
  * `ROUND(..., 1)`：保留 1 位小数（四舍五入）。
* **`GROUP BY 年龄分组`**
  * `GROUP BY`：将表中的所有行按照某个标准“切成几块/打成包”，对每一块独立做聚合计算。
  * ⚠️ **硬性语法规则**：在写 `GROUP BY` 时，`SELECT` 后面的列必须要么是**被分组的字段/表达式**，要么必须包裹在**聚合函数**（如 COUNT/SUM）内部！绝不能在 SELECT 中随便放一个普通的未分组列，否则结果是不可控的。
* **`HAVING 人数 >= 2;`**
  * `HAVING`：专门用来**过滤分组后的计算结果**。
  * 🌟 **WHERE vs HAVING 核心区别**：
    * `WHERE` 在分组**前**执行，不能在里面使用聚合函数（如 `WHERE COUNT(*) > 1` 是错的！）；
    * `HAVING` 在分组**后**执行，专门对聚合出来的结果进行条件过滤。

---

## 第六章：攻克多表连接（JOIN 详解）

#### 🎯 【本节目标】
演示如何通过 `INNER JOIN` 和 `LEFT JOIN` 将分散在多个表（用户表、商品表、订单表）中的数据关联拼凑成完整视图，并学会利用 `LEFT JOIN` 寻找“未产生关联”的缺失数据。

#### 💻 【实操代码】

```sql
-- 准备工作 1：建商品表 products
CREATE TABLE IF NOT EXISTS products (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    price        DECIMAL(10, 2) NOT NULL,
    category     VARCHAR(50)
);

-- 准备工作 2：建订单表 orders
CREATE TABLE IF NOT EXISTS orders (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    user_id      INT NOT NULL,
    product_id   INT NOT NULL,
    quantity     INT DEFAULT 1,
    total_price  DECIMAL(10, 2) NOT NULL
);

-- 插入商品与订单测试数据
INSERT INTO products (name, price, category) VALUES
('iPhone 15', 5999.00, '数码'),
('MacBook Pro', 12999.00, '数码'),
('蓝牙耳机', 299.00, '配件');

INSERT INTO orders (user_id, product_id, quantity, total_price) VALUES
(1, 1, 1, 5999.00),   -- 张三买了 iPhone
(1, 3, 2, 598.00),    -- 张三买了 2 个耳机
(2, 2, 1, 12999.00);  -- 李四买了 MacBook
-- 注意：王五(id=3)、赵六(id=4) 没有下单

-- 1. 内连接（INNER JOIN）：查询已经产生的订单详情
SELECT 
    u.username AS 买家姓名,
    p.name AS 商品名称,
    o.quantity AS 购买数量,
    o.total_price AS 订单金额
FROM orders o
INNER JOIN users u ON o.user_id = u.id
INNER JOIN products p ON o.product_id = p.id;

-- 2. 左连接（LEFT JOIN）：查出所有用户及其对应的订单（没下单的用户也列出来）
SELECT 
    u.username AS 用户名,
    u.email,
    o.id AS 订单号,
    o.total_price AS 订单金额
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

-- 3. 实战技巧：精准找出“从未下过单”的用户
SELECT 
    u.username AS 未下单用户名
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.id IS NULL;
```

#### 🔍 【逐行解析】

* **`FROM orders o INNER JOIN users u ON o.user_id = u.id`**
  * `FROM orders o`：指定主表为 `orders`，并起一个缩写别名 `o`。
  * `INNER JOIN users u`：内连接 `users` 表，别名为 `u`。
  * `ON o.user_id = u.id`：**连接条件**！声明 `orders` 表里的 `user_id` 和 `users` 表里的 `id` 是一致的。
  * *内连接特点*：**只返回两边都完全匹配上的交集数据**！因为王五没有订单，所以在内连接结果里完全看不到王五。
* **`FROM users u LEFT JOIN orders o ON u.id = o.user_id`**
  * `LEFT JOIN`：**左外连接**。以位于 `LEFT JOIN` **左边**的 `users` 表为基准，左表的所有行全部保存在结果集中！
  * 如果左表（张三、李四）在右表有订单，正常显示订单；
  * 如果左表（王五、赵六）在右表没有订单，右表对应的列全部自动填 `NULL`！
* **`WHERE o.id IS NULL;`**
  * 利用 `LEFT JOIN` 匹配不上填 `NULL` 的特性。
  * 当我们在 `WHERE` 条件里加上 `o.id IS NULL` 时，就精准地过滤出了那些“右表没有记录”的行，即从未下过单的用户！

---

## 第七章：常用实战内置函数

#### 🎯 【本节目标】
教会你如何在 SQL 查询中进行处理空值（`IFNULL`）、时间格式化（`DATE_FORMAT`）以及条件分支映射，提升业务 SQL 的处理效率。

#### 💻 【实操代码】

```sql
-- 1. 空值优雅处理：如果用户没有邮箱，显示 '未绑定邮箱'
SELECT 
    username, 
    IFNULL(email, '未绑定邮箱') AS 邮箱状态 
FROM users;

-- 2. 时间格式化：把复杂的 2024-01-15 14:30:00 转换成中文易读格式
SELECT 
    username, 
    DATE_FORMAT(created_at, '%Y年%m月%d日 %H时%i分') AS 注册时间格式化 
FROM users;

-- 3. 复杂分支逻辑：使用 CASE WHEN 给用户的余额划分等级
SELECT 
    username,
    balance,
    CASE 
        WHEN balance >= 10000 THEN '👑 尊贵 VIP'
        WHEN balance >= 1000 THEN '💎 普通会员'
        ELSE '🌱 注册用户'
    END AS 会员等级
FROM users
ORDER BY balance DESC;
```

#### 🔍 【逐行解析】

* **`IFNULL(email, '未绑定邮箱')`**
  * `IFNULL(字段, 默认值)`：MySQL 特有函数。如果第一个参数不是 NULL，返回字段原本的值；如果字段为 NULL，则返回给定的默认值。
* **`DATE_FORMAT(created_at, '%Y年%m月%d日 %H时%i分')`**
  * `DATE_FORMAT(时间字段, 格式字符串)`：格式化日期函数。
  * `%Y`：四位年份（如 2024）；`%m`：两位月份（01-12）；`%d`：两位日期（01-31）；`%H`：两位小时；`%i`：两位分钟。
* **`CASE WHEN balance >= 10000 THEN ... END`**
  * SQL 版的 `if-else` 分支结构。按从上到下的顺序匹配，一旦满足第一个 `WHEN` 条件就会返回对应的 `THEN` 值并结束判断。如果不满足任何条件，返回 `ELSE` 后的值。

---

## 第八章：索引原理与 EXPLAIN 性能加速实操

#### 🎯 【本节目标】
演示什么是**全表扫描**，如何使用 `EXPLAIN` 查看 SQL 的底层执行计划，以及如何通过建立索引实现查询速度百倍提升。

#### 💻 【实操代码】

```sql
-- 1. 使用 EXPLAIN 分析查询 email 的执行计划（此时 email 没有索引）
EXPLAIN SELECT * FROM users WHERE email = 'zhangsan@qq.com';

-- 2. 给 email 字段创建唯一索引
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- 3. 再次使用 EXPLAIN 分析相同的查询
EXPLAIN SELECT * FROM users WHERE email = 'zhangsan@qq.com';

-- 4. 查看 users 表上当前生效的所有索引
SHOW INDEX FROM users;
```

#### 🔍 【逐行解析】

* **`EXPLAIN SELECT ...`**
  * 在任何 `SELECT` 语句前加上 `EXPLAIN`，MySQL 不会真正执行这条查询，而是会打印出**执行计划**（Optimized Execution Plan）。
* **第一次 `EXPLAIN` 结果解读（未建索引）：**
  * `type` 列显示为 **`ALL`**：代表**全表扫描**（Full Table Scan）！数据库必须从第 1 行逐行查找到最后一行，如果有 100 万条记录就要翻 100 万次，极慢！
  * `key` 列显示为 **`NULL`**：代表没有使用任何索引。
* **`CREATE UNIQUE INDEX idx_users_email ON users(email);`**
  * `CREATE UNIQUE INDEX`：在 `users` 表的 `email` 列上创建一个唯一索引。
  * *底层原理解析*：MySQL 会在后台为 email 字段建立一棵 **B+Tree（B+树）**。
* **第二次 `EXPLAIN` 结果解读（已建索引）：**
  * `type` 列变成了 **`const`**（或 `ref`）：代表常数级查找！
  * `key` 列显示为 **`idx_users_email`**：代表成功命中了我们创建的索引。
  * *性能差距*：原本需要扫描 100 万行的全表查询，现在通过 B+Tree 只需要 **3~4 次磁盘 I/O** 即可精准定位！

---

## 第九章：事务与数据安全实操（TRANSACTION）

#### 🎯 【本节目标】
通过模拟真实的“张三给李四转账”场景，教会你如何开启事务（`START TRANSACTION`）、提交事务（`COMMIT`）以及出现异常时撤销操作（`ROLLBACK`），保障数据的最终一致性（Atomicity & Consistency）。

#### 💻 【实操代码】

```sql
-- 场景 A：模拟成功的转账（张三转账 200 元给李四）
-- 1. 开启事务
START TRANSACTION;

-- 2. 张三余额减少 200
UPDATE users SET balance = balance - 200 WHERE username = '张三';

-- 3. 李四余额增加 200
UPDATE users SET balance = balance + 200 WHERE username = '李四';

-- 4. 确认两步均无误，提交事务（持久化保存到磁盘）
COMMIT;

-- 验证转账后的余额
SELECT username, balance FROM users WHERE username IN ('张三', '李四');

----------------------------------------------------

-- 场景 B：模拟失败并撤销的转账（转账过程中发现报错，撤销所有改动）
-- 1. 开启事务
START TRANSACTION;

-- 2. 张三余额减少 500
UPDATE users SET balance = balance - 500 WHERE username = '张三';

-- 3. 假设此时系统突然崩溃或校验发现李四账户异常！执行撤销：
ROLLBACK;

-- 验证余额（你会发现张三的余额毫发无损，恢复到了转账前的状态！）
SELECT username, balance FROM users WHERE username IN ('张三', '李四');
```

#### 🔍 【逐行解析】

* **`START TRANSACTION;`（或 `BEGIN;`）**
  * 显式开启一个事务。此时当前连接开启了一个隔离的操作空间，后续的所有修改都暂存于内存事务日志中，尚未永久生效。
* **`COMMIT;`**
  * 提交事务！通知 MySQL 将该事务中所有的 `UPDATE` / `INSERT` / `DELETE` 操作持久化写入磁盘文件，不可撤销。
* **`ROLLBACK;`**
  * 回滚事务！通知 MySQL 放弃该事务中所有未提交的修改，将数据恢复到 `START TRANSACTION` 之前的时刻。
  * 🌟 **这就是 ACID 特性中的 A（原子性，Atomicity）**：一个事务中的多步操作，要么全做，要么全不做！

---

## 第十章：实验环境清理

#### 🎯 【本节目标】
在完成所有学习与测试后，安全清理测试用数据库。

#### 💻 【实操代码】

```sql
-- 删除实验数据库 shop_db
DROP DATABASE IF EXISTS shop_db;
```

#### 🔍 【逐行解析】

* **`DROP DATABASE IF EXISTS shop_db;`**
  * `DROP DATABASE`：彻底销毁整个数据库及库下所有的表结构和数据。
  * `IF EXISTS`：存在才删除，防止重复删除时触发报错。

---

> 🎉 **恭喜你通关 MySQL 零基础带练教程！**
> 只要按照本教程把每一个示例在 MySQL 终端中跑过一遍，你就已经完整掌握了 MySQL 基础开发、数据查询、多表关联、性能调优和事务处理的全套知识！
