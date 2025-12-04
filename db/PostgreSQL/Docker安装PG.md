```shell
# 创建挂载目录
mkdir -p /home/${USER}/.local/postgres

# 安装PGSQL
docker run --name mypostgres \
  -e POSTGRES_PASSWORD=123456 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -p 5432:5432 \
  -v /home/${USER}/.local/postgres:/var/lib/postgresql \
  --restart always \
  -d postgres:latest \
  -c listen_addresses='*'

  
# 验证
docker ps -a
docker exec -it mypostgres psql -U postgres -c "SELECT version();"
docker exec -it mypostgres psql -U postgres -c "CREATE DATABASE mydb;"
docker exec -it mypostgres psql -U postgres -c "\l"
# docker rm -f mypostgres
```





## 命令别名

```shell
# vim ~/.bashrc
alias psql='docker exec -it postgres-db psql -U postgres'

# 测试
psql -c "select version();"
```

