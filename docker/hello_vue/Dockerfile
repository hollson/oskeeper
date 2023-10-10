# 第一阶段：构建Web项目，输出dist包
FROM node:18.18.0 as builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build  


# 第二阶段：构建最终镜像
# https://hub.docker.com/_/nginx
# dockerfile 一定要写daemon off 否则，docker run 会起不起来
FROM nginx:alpine-slim
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


# 构建镜像，运行容器
# docker build -t hello_vue:1.0 .
# docker run -p 8080:80 --name hello_vue  -d  hello_vue:1.0
# curl http://localhost:8080