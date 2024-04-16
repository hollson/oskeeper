以下是创建成绩表的SQL语句，以及一些测试数据：

```sql
CREATE TABLE scores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    student_id INT,
    gender VARCHAR(10),
    math_score INT,
    english_score INT,
    chinese_score INT,
    sports_score INT
);

INSERT INTO scores (name, student_id, gender, math_score, english_score, chinese_score, sports_score)
VALUES 
('张三', 1001, '男', 85, 90, 78, 88),
('李四', 1002, '女', 92, 88, 95, 90),
('王五', 1003, '男', 78, 85, 80, 92),
('赵六', 1004, '女', 90, 92, 85, 85),
('钱七', 1005, '男', 88, 86, 92, 78);
```

要查找各科的最高分，你可以使用以下查询语句：

```sql
SELECT 
    MAX(math_score) AS max_math_score,
    MAX(english_score) AS max_english_score,
    MAX(chinese_score) AS max_chinese_score,
    MAX(sports_score) AS max_sports_score
FROM 
    scores;
```

这条查询会返回每个科目的最高分。







`GROUP_CONCAT` 函数用于将组内的值连接为一个字符串，并用指定的分隔符分隔。它通常与 `GROUP BY` 一起使用，以在每个分组内将值连接起来。下面是一个示例：

假设我们有一个学生表格 `students` 包含 `name` 和 `subject` 字段，我们想要为每个学生列出他们所学的科目，可以使用 `GROUP_CONCAT`。

首先，让我们创建一个简单的学生表格并插入一些数据：

```sql
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    subject VARCHAR(50)
);

INSERT INTO students (name, subject) VALUES
('张三', '数学'),
('张三', '英语'),
('张三', '物理'),
('李四', '数学'),
('李四', '化学'),
('王五', '英语'),
('王五', '物理');
```

现在，我们想要为每个学生列出他们所学的科目，可以使用 `GROUP_CONCAT` 函数：

```sql
SELECT 
    name, 
    GROUP_CONCAT(subject) AS subjects
FROM 
    students
GROUP BY 
    name;
```

这将返回每个学生的名字以及他们所学的所有科目，使用逗号分隔。