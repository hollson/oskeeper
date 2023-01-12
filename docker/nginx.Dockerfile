FROM alpine
MAINTAINER will 

## 将alpine-linux:apk的安装源改为国内镜像
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

## 安装需要编译nginx扩展
## 安装正则表达式pcre模块，nginx正则匹配URL
RUN apk add wget gcc g++ make && \ 
    cd /home && \
    wget "https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz" && \
    tar xvf pcre-8.44.tar.gz && \
    wget "http://nginx.org/download/nginx-1.18.0.tar.gz" && \
    tar xvf nginx-1.18.0.tar.gz

## 编译nginx
RUN cd /home/nginx-1.18.0 && \
    ./configure --prefix=/usr/local/nginx --with-pcre=/home/pcre-8.44 --without-http_gzip_module && \
    make && make install && \
    ln -s /usr/local/nginx/sbin/nginx /usr/sbin/ && \
    mkdir -p /usr/local/nginx/conf/vhost/
    rm -rf /home/*

## 设置工作目录
WORKDIR /var/www

## 启动nginx
CMD ["nginx","-g","daemon off;"]

EXPOSE 80