```shell
# 安装Mysql8.0
$ wget https://dev.mysql.com/get/Downloads/MySQL-8.3/mysql-8.3.0-linux-glibc2.28-x86_64.tar.xz
$ tar -xvf mysql-8.3.0-linux-glibc2.28-x86_64.tar.xz
$ sudo cp -R mysql-8.3.0-linux-glibc2.28-x86_64 /usr/local/mysql
$ export PATH=/usr/local/mysql/bin:$PATH
$ mysql -V


# 安装Mysql5.7
$ sudo apt install -y libncurses5
$ sudo ldconfig
$ wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz
$ tar -zxvf mysql-5.7.28-linux-glibc2.12-x86_64.tar.gz
$ sudo cp -R mysql-5.7.28-linux-glibc2.12-x86_64 /usr/local/mysql
$ export PATH=/usr/local/mysql/bin:$PATH
$ mysql -V


# 配置服务
mkdir /opt/mysql/data
chmod -R 750 /opt/mysql/data

./bin/mysqld --initialize --datadir=/opt/mysql/data
./bin/mysqld --datadir=/opt/mysql/data --socket=/opt/mysql/mysql.sock
./bin/mysql -S /opt/mysql/mysql.sock



cd /usr/local/mysql
sudo bin/mysqld --initialize   # JJ/vHRg,k123
sudo bin/mysqld --user=root 
sudo chown -R mysql .
sudo chgrp -R mysql .
sudo bin/mysqld_safe --user=mysql &

/usr/local/mysql/bin/mysql -u root -p
```





##  参考链接

> http://www.yanjun.pro/?p=4

