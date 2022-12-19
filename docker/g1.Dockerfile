FROM golang:1.13-alpine3.10 AS builder
RUN  apk --update --no-cache add git mercurial subversion bzr ca-certificates 
ENV  GOPROXY=https://[YOUR-USER]:[YOUR-PASSWORD]@proxy.yourcompany.com,direct
WORKDIR /app
COPY . .
RUN go build -o main

FROM alpine:3.10
WORKDIR /app
COPY --from=builder /app/main /usr/local/bin
ENTRYPOINT [ "main" ]