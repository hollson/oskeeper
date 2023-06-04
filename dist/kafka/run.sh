#!/bin/bash

docker-compose -f docker-compose-kafka-cluster.yml up -d

# docker network ls
# docker network create docker_net

# https://zhuanlan.zhihu.com/p/110905106
