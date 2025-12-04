


# PostgreSQL创建表及约束

创建表

语法：

```sql
create table table_name (
     column_name type column_constraint,
     table_constraint table_constraint
) inherits existing_table_name;
```

示例：

```sql
create table account(
    user_id serial primary key,
    username varchar(50) unique not null,
    password varchar(50) not null
);
```

主键约束

　　主键是用于在表中唯一标识行的列或列组。从技术上讲，主键约束是非空约束和UNIQUE约束的组合。

　　1.使用列级约束设置主键

```sql
create table "SysUser"(      
    "UserId" serial primary key,  
    "UserName" varchar(50), 
    "Pwd" varchar(50)
);
--说明：只能设置一列作为主键，主键默认名称为tablename_pkey。
```

2.使用表级约束设置主键
```sql
create table "SysUser"(      
    "UserId" serial,   
    "UserName" varchar(50), 
    "Pwd" varchar(50),
    constraint PK_SysUser primary key("UserId")
);
--说明：使用[表]级约束设置主键，可以设置一列或多列作为主键，主键默认名称为tablename_pkey，constraint PK_SysUser可省略。
```
3.通过修改表结构设置主键

```sql
--语法：alter table table_name add [constraint constraint_name] primary key(column_1, column_2);
create table "SysUser"(      
    "UserId" serial,   
    "UserName" varchar(50), 
    "Pwd" varchar(50)
);
alter table "SysUser" add constraint PK_SysUser primary key("UserId"); 
--说明：通过修改表结构设置主键，可以设置一列或多列作为主键，可以指定主键名称。
```

4.往已有表添加自增主键

```sql
--创建没有任何主键的表。
create table "Vendors" ("Name" varchar(255));
--往表添加数据
insert into "Vendors"("Name")values('001'),('002'),('003'),('004');
--查询
select * from "Vendors";
```

　　数据输出

现在，如果我们要添加一个名为id的自增主键到vendors表。

```sql
alter table "Vendors" add column "ID" serial primary key;
```

　　数据输出
5.删除主键

```sql
alter table table_name drop constraint pk_name;
```

 

外键约束

　　外键约束维护子表和父表之间的引用完整性。

1.使用列级约束设置外键
```sql
create table "SysUserInfo"(
        "UserId" integer primary key references "SysUser"("UserId"),
        "RealName" varchar(50),
        "IdCard" varchar(50),
        "Gender" smallint
);
--说明：外键默认名称为tablename_columnname_fkey
```
2.使用表级约束设置外键
```sql
create table "SysUserInfo"(
        "UserId" integer,
        "RealName" varchar(50),
        "IdCard" varchar(50),
        "Gender" smallint,
      primary key("UserId"),
        foreign key("UserId") references "SysUser"("UserId")
);
--说明：外键默认名称为tablename_columnname_fkey
```
3.通过修改表结构设置外键
```sql
--语法：alter table table_name add [constraint constraint_name] foreign key(column_1) references TableName(ColumnName);
create table "SysUserInfo"(
        "UserId" integer,
        "RealName" varchar(50),
        "IdCard" varchar(50),
        "Gender" smallint,
      primary key("UserId")
);
alter table "SysUserInfo" add constraint SysUserInfo_UserId_fkey foreign key("UserId") references "SysUser"("UserId");
--说明：通过修改表结构设置外键，可以指定外键名称。
```

4.删除外键约束（同删除其他约束一样，使用同一语法）

```sql
alter table table_name drop constraint fk_name;
```

唯一约束

　　确保[列]或[列组]中的值在表中是唯一的。

　　1.使用列级约束设置唯一约束

```sql
create table "Ha" (
    "h1" varchar(50) unique,
    "h2" varchar(50) unique,
    "h3" varchar(50) 
);
--生成2个列的唯一约束Ha_h1_key 和 Ha_h2_key 
```

2.使用表级约束设置唯一约束（注意以下两种方式的区别）

```sql
create table "Ha" (
    "h1" varchar(50),
    "h2" varchar(50),
    "h3" varchar(50),
     unique("h1","h2")
);
--将会生成1个列组的唯一约束Ha_h1_h2_key
create table "Ha" (
    "h1" varchar(50),
    "h2" varchar(50),
    "h3" varchar(50),
    unique("h1"),
    unique("h2")
);
--将会生成2个列的唯一约束Ha_h1_key和Ha_h2_key
```
3.通过修改表结构设置唯一约束

```sql
create table "Ha" (
    "h1" varchar(50),
    "h2" varchar(50),
    "h3" varchar(50)
);
alter table "Ha" add constraint Ha_h1_h2_key unique("h1","h2")
--说明：将会生成1个列组的唯一约束Ha_h1_h2_key。如果想要2个列的唯一约束，需写两个alter table。
```
4.测试列唯一约束和列组唯一约束

　　列唯一约束
```sql
--首先创建一个具有唯一约束(列唯一约束)的表
create table "Ha" (
    "h1" varchar(50) unique
);
insert into "Ha"("h1")values('0'); --success
insert into "Ha"("h1")values('0'); --error：重复键违反唯一约束"Ha_h1_key"，键值"(h1)=(0)" 已经存在。
insert into "Ha"("h1")values(null);--success：可理解为null不等于任何一个值，因为它本身就是不确定的值，所以该条数据能添加成功。
insert into "Ha"("h1")values(null);--success：该条数据也能添加成功。
```
列组唯一约束

```sql
--删除原表，然后创建一个具有唯一约束（列组唯一约束）的表
create table "Ha" (
    "h1" varchar(50),
        "h2" varchar(50),
        unique("h1","h2")
);
insert into "Ha"("h1","h2")values('0','0');--success
insert into "Ha"("h1","h2")values('0','1');--success
insert into "Ha"("h1","h2")values('0','1');--error：重复键违反唯一约束"Ha_h1_h2_key",键值"(h1, h2)=(0, 1)" 已经存在。
insert into "Ha"("h1","h2")values(null,null);--success
insert into "Ha"("h1","h2")values(null,null);--success
```
检查约束

　　该约束基于布尔表达式约束表中列的值。

1.使用列级约束设置检查约束

```sql
create table "Ha" (income numeric CHECK(salary > 0));
```

　　2.使用表级约束设置检查约束

```sql
create table "Ha" (
    salary numeric,
        CHECK(salary > 0)
);
```

　　3.通过修改表结构设置检查约束

```sql
create table "Ha" (
    salary numeric
);
alter table "Ha" add constraint Ha_salary_check check(salary > 0);
```

 