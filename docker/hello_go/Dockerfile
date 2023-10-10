# 第一阶段：构建Go项目
FROM golang:1.21 as builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o hello .

# 第二阶段：将Go项目打包进apline
FROM alpine:latest  
WORKDIR /app
COPY --from=builder /app/hello .
CMD ["./hello"]

# 构建镜像，运行容器,验证服务
# docker build -t hello_go:1.0 .
# docker run -d --name hello_go -p 1080:80 hello_go:1.0
# curl http://localhost:1080