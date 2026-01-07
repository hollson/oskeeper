# Pandas DataFrame实操指南
### 概念介绍
Pandas DataFrame 是 Pandas 库中用于存储和处理二维表格型数据的核心数据结构，可类比为带行/列索引的 Excel 表格，支持异构数据存储和灵活的数据分析操作。

### 前置准备
```bash
pip install pandas openpyxl  # openpyxl用于读写Excel文件
```

### 1. 创建 DataFrame
```python
import pandas as pd
import numpy as np

# 方式1：字典创建（最常用）
data_dict = {
    "姓名": ["张三", "李四", "王五", "赵六"],
    "年龄": [20, 25, 22, 28],
    "城市": ["北京", "上海", "广州", "深圳"],
    "成绩": [85.5, 90.0, 78.5, np.nan],  # 含缺失值
    "班级": ["一班", "一班", "二班", "二班"]
}
df = pd.DataFrame(data_dict)

# 方式2：列表嵌套列表创建
data_list = [[1, "A"], [2, "B"], [3, "C"]]
df_list = pd.DataFrame(data_list, columns=["序号", "等级"])

# 方式3：读取外部文件
# df_csv = pd.read_csv("data.csv", encoding="utf-8")  # 读取CSV
# df_excel = pd.read_excel("data.xlsx", sheet_name="Sheet1")  # 读取Excel
# df_sql = pd.read_sql("SELECT * FROM table", conn)  # 读取数据库（需数据库连接）
```

### 2. 数据查看与基础信息
```python
# 预览数据
print(df.head(2))  # 前2行
print(df.tail(1))  # 最后1行

# 基础信息
print(df.info())  # 行数、列数、数据类型、缺失值
print(df.describe())  # 数值列统计（均值、标准差、最值等）
print(df.columns.tolist())  # 列名
print(df.shape)  # 维度（行数, 列数）
print(df.isnull().sum())  # 各列缺失值数量
```

### 3. 数据选择与筛选
```python
# 列选择
col_single = df["姓名"]  # 单列
col_multi = df[["姓名", "成绩"]]  # 多列

# 行选择
row_loc = df.loc[1]  # 按索引标签选行
row_iloc = df.iloc[0:2]  # 按位置选前2行
row_cond = df[df["年龄"] > 20]  # 条件筛选
row_multi_cond = df[(df["年龄"] > 20) & (df["班级"] == "二班")]  # 多条件筛选

# 单元格选择
cell = df.loc[df["姓名"] == "张三", "成绩"].values[0]  # 张三的成绩
```

### 4. 数据修改与清洗
```python
# 新增列
df["是否及格"] = df["成绩"].fillna(0) >= 60  # 填充缺失值后判断及格
df["成绩等级"] = pd.cut(df["成绩"].fillna(0), bins=[0, 60, 80, 100], labels=["不及格", "及格", "优秀"])

# 修改值
df.loc[df["姓名"] == "赵六", "成绩"] = df["成绩"].mean()  # 缺失值用均值填充
df["城市"] = df["城市"].str.replace("京", "北京")  # 字符串替换

# 删除操作
df_drop_col = df.drop(columns=["是否及格"])  # 删除列
df_drop_row = df.drop(index=df[df["年龄"] < 20].index)  # 删除年龄<20的行
df_drop_na = df.dropna(subset=["成绩"])  # 删除成绩列缺失的行

# 去重与重置索引
df_dup = df.drop_duplicates(subset=["班级"])  # 按班级去重
df_reset = df.reset_index(drop=True)  # 重置索引（丢弃原索引）
```

### 5. 数据聚合与统计
```python
# 基础统计
mean_score = df["成绩"].mean()  # 均值
max_age = df["年龄"].max()  # 最大值
sum_age = df["年龄"].sum()  # 求和
count_city = df["城市"].nunique()  # 城市唯一值数量

# 分组聚合
group_mean = df.groupby("班级")["成绩"].mean()  # 按班级求平均成绩
group_agg = df.groupby("班级").agg({"成绩": ["mean", "max"], "年龄": "count"})  # 多维度聚合

# 排序
df_sort_asc = df.sort_values(by="成绩", ascending=True)  # 升序
df_sort_desc = df.sort_values(by=["班级", "成绩"], ascending=[True, False])  # 多列排序

# 透视表
pivot_table = df.pivot_table(values="成绩", index="班级", columns="城市", aggfunc="mean")
```

### 6. 数据合并与拼接
```python
# 纵向拼接
df1 = df[["姓名", "年龄"]]
df2 = pd.DataFrame({"姓名": ["钱七"], "年龄": [23]})
df_concat = pd.concat([df1, df2], ignore_index=True)

# 横向合并（关联）
df_left = df[["姓名", "成绩"]]
df_right = pd.DataFrame({"姓名": ["张三", "李四"], "性别": ["男", "女"]})
df_merge = pd.merge(df_left, df_right, on="姓名", how="left")  # 左连接
```

### 7. 时间序列处理（常用）
```python
# 创建时间列
df["日期"] = pd.date_range(start="2026-01-01", periods=len(df))
# 提取时间特征
df["年"] = df["日期"].dt.year
df["月"] = df["日期"].dt.month
df["星期"] = df["日期"].dt.dayofweek
# 按时间筛选
df_time_filter = df[df["日期"] >= "2026-01-02"]
# 时间重采样
df_resample = df.set_index("日期").resample("M")["成绩"].mean()  # 按月聚合
```

### 8. 数据导出
```python
# 导出CSV
df.to_csv("student_data.csv", index=False, encoding="utf-8")

# 导出Excel
df.to_excel("student_data.xlsx", index=False, sheet_name="学生信息")

# 导出为JSON
df.to_json("student_data.json", orient="records", force_ascii=False)
```

### 总结
1. DataFrame 是 Pandas 二维表格数据结构，支持从字典、列表、外部文件等多方式创建；
2. 核心操作覆盖数据查看、筛选、修改、聚合、合并、时间处理、导出等全流程；
3. 高频方法：`loc/iloc`（数据选择）、`groupby()`（分组）、`fillna()`（缺失值）、`merge()`（合并）是日常分析的核心。