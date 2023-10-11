# 第一阶段：构建Go项目
# docker run -ti --rm golang:alpine go version
# -s:去掉符号表,-w:去掉调试信息(不能gdb调试)
FROM golang:alpine as builder
WORKDIR /app
LABEL Maintainer=ShongSheng
ENV GOPROXY https://goproxy.cn,direct
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o hello .

# 第二阶段：将Go项目打包进apline
FROM scratch
WORKDIR /app
ADD ./zoneinfo/Shanghai /usr/share/zoneinfo/Asia/Shanghai
ENV TZ Asia/Shanghai
# 最后一次版本提交记录
ENV COMMIT $(git rev-parse --short HEAD)
COPY --from=builder /app/hello .
EXPOSE 80 443
CMD ["./hello"]