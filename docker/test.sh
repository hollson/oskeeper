#!/bin/bash

#while (true); do
#   date "+%Y-%m-%d %H:%M:%S"
#   sleep 1
#done

#--restart=on # 默认
#--restart=always
#--restart=on-failure:3
docker run -d --restart=always alpine:latest sh -c "echo $(date)>> a.txt;sleep 10;exit 1;"

date
docker run -d --restart=on-failure:3 alpine sh -c "sleep 10;exit 1;"

docker logs -f xxx




#--restart=on            # 默认不重启
#--restart=always        # 总是重启
#--restart=on-failure:3  # 重启3次
docker run -ti --rm alpine sh -c "while :; do date;sleep 1;done"