FROM golang as build
ENV GOPROXY=https://goproxy.cn,direct
ADD . /app
WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o go_server
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone


FROM alpine:3.16
RUN echo "http://mirrors.aliyun.com/alpine/v3.16/main/" > /etc/apk/repositories
RUN apk update
RUN apk add ca-certificates
RUN echo "hosts: files dns" > /etc/nsswitch.conf
RUN mkdir -p /app/conf /app/runtime/
WORKDIR /app
COPY --from=build /app/go_server /usr/bin/go_server
ADD ./conf /app/conf
RUN chmod +x /usr/bin/go_server
ENTRYPOINT ["go_server"]