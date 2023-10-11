# 第一阶段：构建Go项目
# docker run -ti --rm golang:alpine go version
# -s:去掉符号表,-w:去掉调试信息(不能gdb调试)
FROM golang:alpine as builder
WORKDIR /app
LABEL Maintainer=ShongSheng
ENV GOPROXY https://goproxy.cn,direct
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o hello .

# 第二阶段：将Go项目打包进apline
FROM scratch
WORKDIR /app
ADD ./zoneinfo/Shanghai /usr/share/zoneinfo/Asia/Shanghai
ENV TZ Asia/Shanghai
COPY --from=builder /app/hello .
EXPOSE 80
CMD ["./hello"]

# 构建镜像，运行容器,验证服务
# docker build -t hello_go:1.0 .
# docker run -d --name hello_go -p 1080:80 hello_go:1.0
# curl http://localhost:1080