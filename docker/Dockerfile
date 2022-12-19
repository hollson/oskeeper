FROM alpine

# 工作目录
WORKDIR /app

# 拷贝添加
COPY ./deploy .

# 开放端口
EXPOSE 8080 1443

# 环境变量
ENV APP_NAME=Awesome
ENV APP_VERSION "1.0.0"
ENV GIT_COMMIT $(git rev-parse HEAD)

# 安装软件
#RUN apk add --update --no-cache curl

# 添加时区
ENV TZ=Asia/Shanghai
ADD ./asset/Shanghai /usr/share/zoneinfo/Asia/Shanghai
RUN echo ${TZ} > /etc/timezone

# 运行时命令
CMD ./hello-server
