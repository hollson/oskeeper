#!/bin/bash

docker-compose -f docker-compose-kafka-cluster.yml up -d

# docker network ls
# docker network create docker_net

# https://zhuanlan.zhihu.com/p/110905106

# Kafka可视化管理平台
# https://gitcode.net/mirrors/tchiotludo/akhq?utm_source=csdn_github_accelerator
# https://akhq.io/docs/configuration/docker.html
