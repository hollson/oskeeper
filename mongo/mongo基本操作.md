http://www.runoob.com/mongodb/mongodb-tutorial.html

[TOC]

# Mongo概念
| SQL术语/概念 | MongoDB术语/概念 | 解释/说明 |
| ------------ | ---------------- | ----------------------------------- |
| database | database | 数据库 |
| table | collection | 数据库表/集合 |
| row | document | 数据记录行/文档 |
| column | field | 数据字段/域 |
| index | index | 索引 |
| table joins | | 表连接,MongoDB不支持 |
| primary key | primary key | 主键,MongoDB自动将_id字段设置为主键 |



# 数据类型

| 数据类型 | 描述 |
| ------------------ | ------------------------------------------------------------ |
| String | 字符串。存储数据常用的数据类型。在 MongoDB 中，UTF-8 编码的字符串才是合法的。 |
| Integer | 整型数值。用于存储数值。根据你所采用的服务器，可分为 32 位或 64 位。 |
| Boolean | 布尔值。用于存储布尔值（真/假）。 |
| Double | 双精度浮点值。用于存储浮点值。 |
| Min/Max keys | 将一个值与 BSON（二进制的 JSON）元素的最低值和最高值相对比。 |
| Array | 用于将数组或列表或多个值存储为一个键。 |
| Timestamp | 时间戳。记录文档修改或添加的具体时间。 |
| Object | 用于内嵌文档。 |
| Null | 用于创建空值。 |
| Symbol | 符号。该数据类型基本上等同于字符串类型，但不同的是，它一般用于采用特殊符号类型的语言。 |
| Date | 日期时间。用 UNIX 时间格式来存储当前日期或时间。你可以指定自己的日期时间：创建 Date 对象，传入年月日信息。 |
| Object ID | 对象 （雪花）ID。用于创建文档的 ID。 |
| Binary Data | 二进制数据。用于存储二进制数据。 |
| Code | 代码类型。用于在文档中存储 JavaScript 代码。 |
| Regular expression | 正则表达式类型。用于存储正则表达式。 |



# 数据库

```shell
# 连接数据库
mongo mongodb://172.32.62.32:27017

# 查看数据库
$ show dbs

# 创建/选择数据库
$ use testdb

# 当前数据库
$ db

# 删除数据库
$ db.dropDatabase()

```





# 集合(表)
```shell
# 查看表
$ show collections 
$ show tables
db.mytable.find({}).limit(1);
db.mytable.count();

# 创建表
$ db.createCollection("product")
$ db.createCollection("product",{ name:"apple"})
$ db.user.insert({x:10})

# 删除表
$ db.user.drop()
```

![img](assets/50797663.png)



# 插入

```shell
# 直接插入
$ db.user.insert({name:"Jack"})

# 插入变量
$ doc=({name:"Lily"})
$ db.user.insert(doc)

# 单条插入
$ db.user.insertOne({name:"Lucy"})

# 多条插入
$ db.user.insertMany([{name: "Jim"}, {name: "Poly"}])

# 查询
$ db.user.find()
# 美化输出
$ db.user.find().pretty()

```



# 更新

定义：er

`db.col.update(<query>,<update>,{upsert: <bool>,multi: <bool>,writeConcern: <doc>})`

- query** : update的查询条件，类似sql update查询内where后面的。
- **update** : update的对象和一些更新的操作符（如$,$inc...）等，也可以理解为sql update查询内set后面的
- **upsert** : 可选，这个参数的意思是，如果不存在update的记录，是否插入objNew,true为插入，默认是false，不插入。
- **multi** : 可选，mongodb 默认是false,只更新找到的第一条记录，如果这个参数为true,就把按条件查出来多条记录全部更新。
- **writeConcern** :可选，抛出异常的级别。

```shell
# Update方法：根据查询条件修改
$ db.user.update({name:"Jack"},{$set:{name:"Jerry"}})
# 批量更新
$ db.user.update({name:"Jack"},{$set:{name:"Jerry"}},{multi:true})

# Save方法：
```



# 删除

```shell
$ db.inventory.deleteMany({})
$ db.inventory.deleteOne( { status: "D" } )
$ db.inventory.deleteMany({ status : "A" })
```



# 查询

- 条件查询
| 范例 | RDBMS中的类似语句 |
| ------------------------------------------- | ----------------------- |
| `db.col.find({"by":"菜鸟教程"}).pretty()` | `where by = '菜鸟教程'` |
| `db.col.find({"likes":{$lt:50}}).pretty()` | `where likes < 50` |
| `db.col.find({"likes":{$lte:50}}).pretty()` | `where likes <= 50` |
| `db.col.find({"likes":{$gt:50}}).pretty()` | `where likes > 50` |
| `db.col.find({"likes":{$gte:50}}).pretty()` | `where likes >= 50` |
| `db.col.find({"likes":{$ne:50}}).pretty()` | `where likes != 50` |


- 且或查询
```shell
$ db.col.findOne({key1:value1, key2:value2}).pretty()

# and
$ db.col.find({key1:value1, key2:value2}).pretty()
# or
$ db.col.find({$or:[{"by":"菜鸟教程"},{"title": "MongoDB 教程"}]}).pretty()

# 'where likes>50 AND (by = '菜鸟教程' OR title = 'MongoDB 教程')'
db.col.find({"likes": {$gt:50}, $or: [{"by": "菜鸟教程"},{"title": "MongoDB 教程"}]}).pretty()
```

- 模糊查询

```shell
#查询 title 包含"教"字的文档：
$ db.col.find({title:/教/})

#查询 title 字段以"教"字开头的文档：
$ db.col.find({title:/^教/})

#查询 titl e字段以"教"字结尾的文档：
$ db.col.find({title:/教$/})
```

- 类型查询

| **类型** | **数字** | **备注** |
| ----------------------- | -------- | ---------------- |
| Double | 1 | *** |
| String | 2 | *** |
| Object | 3 | *** |
| Array | 4 | *** |
| Binary data | 5 | |
| Undefined | 6 | 已废弃。 |
| Object id | 7 | |
| Boolean | 8 | *** |
| Date | 9 | *** |
| Null | 10 | *** |
| Regular Expression | 11 | |
| JavaScript | 13 | |
| Symbol | 14 | |
| JavaScript (with scope) | 15 | |
| 32-bit integer | 16 | *** |
| Timestamp | 17 | |
| 64-bit integer | 18 | *** |
| Min key | 255 | Query with `-1`. |
| Max key | 127 | |

```shell
# 如果想获取 "col" 集合中 title 为 String 的数据，你可以使用以下命令：
$ db.col.find({"title" : {$type : 2}})
$ db.col.find({"title" : {$type : 'string'}})
```



- 分页查询

  ```shell
  db.COLLECTION_NAME.find().limit(NUMBER).skip(NUMBER)
  ```

  

- 排序

  ```shell
  # 倒序
  db.col.find({},{"title":1,_id:0}).sort({"likes":-1})  
  ```






# 索引



# 聚合

| 表达式 | 描述 | 实例 |
| --------- | ---------------------------------------------- | ------------------------------------------------------------ |
| $sum | 计算总和。 | db.mycol.aggregate([{$group : {_id : "$by_user", num_tutorial : {$sum : "$likes"}}}]) |
| $avg | 计算平均值 | db.mycol.aggregate([{$group : {_id : "$by_user", num_tutorial : {$avg : "$likes"}}}]) |
| $min | 获取集合中所有文档对应值得最小值。 | db.mycol.aggregate([{$group : {_id : "$by_user", num_tutorial : {$min : "$likes"}}}]) |
| $max | 获取集合中所有文档对应值得最大值。 | db.mycol.aggregate([{$group : {_id : "$by_user", num_tutorial : {$max : "$likes"}}}]) |
| $push | 在结果文档中插入值到一个数组中。 | db.mycol.aggregate([{$group : {_id : "$by_user", url : {$push: "$url"}}}]) |
| $addToSet | 在结果文档中插入值到一个数组中，但不创建副本。 | db.mycol.aggregate([{$group : {_id : "$by_user", url : {$addToSet : "$url"}}}]) |
| $first | 根据资源文档的排序获取第一个文档数据。 | db.mycol.aggregate([{$group : {_id : "$by_user", first_url : {$first : "$url"}}}]) |
| $last | 根据资源文档的排序获取最后一个文档数据 | db.mycol.aggregate([{$group : {_id : "$by_user", last_url : {$last : "$url"}}}]) |



# 管道

管道在Unix和Linux中一般用于将当前命令的输出结果作为下一个命令的参数。



# 复制

复制是将数据同步在多个服务器的过程。



# 分片

在Mongodb里面存在另一种集群，就是分片技术,可以满足MongoDB数据量大量增长的需求。



# 备份还原

```sh
mongoexport mongodb://Mongouser:Password@172.21.48.121:27017 -d dbname --type=csv -f key1,key2,key3,val --collection GameData_109751597927497988 --out GameData_109751597927497988.csv
mongorestore mongodb://Mongouser:Password@172.21.48.121:27017,172.21.48.89:27017 -d dbname --drop dbname

mongoexport --host 172.31.9.213:27017 -d mgo_main --type=csv -f key1,key2,key3,val --collection GameData_134455749282628097 --out GameData_134455749282628097.csv
```

# MongoDB 监控

在你已经安装部署并允许MongoDB服务后，你必须要了解MongoDB的运行情况，并查看MongoDB的性能。这样在大流量得情况下可以很好的应对并保证MongoDB正常运作。

MongoDB中提供了mongostat 和 mongotop 两个命令来监控MongoDB的运行情况。





