all:help

## build@编译
.PHONY:build
build:
	@echo "=> 🚀 编译Go应用"
	@mkdir -p /tmp/deploy
	@GOOS=linux GOARCH=amd64 go build -o /tmp/deploy/hello-server
	@tar -zcvf deploy.tar.gz -C /tmp/deploy ./
	@echo "🚀 构建docker镜像"
	@docker build -f Dockerfile -t hello:1.0 .
	@echo "\033[31m 🚀  编译完毕\033[0m"


## clean@清理编译、日志和缓存等
.PHONY:clean
clean:
	@docker images|grep none|awk '{print $3}'|xargs docker rmi -f
	@rm -rf ./logs;
	@rm -rf ./log;
	@rm -rf ./cache;
	@rm -rf ./pid;
	@rm -rf ./release;
	@rm -rf ./debug;
	@rm -rf ./vendor/*;
	@rm -rf /tmp/deploy/*
	@echo "\033[31m ✅  清理完毕\033[0m";


## commit <msg>@Git提交，如:make push [msg=<message>]
.PHONY:commit
message:=$(if $(msg),$(msg),"rebuilded at $$(date '+%Y/%m/%d %H:%M:%S')")
commit:
	@echo "\033[0;34mPush to remote...\033[0m"
	@git add .
	@git commit -m $(message)
	@echo "\033[0;31m 💿 Commit完毕\033[0m"


## push <msg>@Git提交并推送，如:make push [msg=<message>]
.PHONY:push
push:commit
	@git push #origin master
	@echo "\033[0;31m ⬆️ Push完毕\033[0m"


## exec@执行docker exec
.PHONY:exec
exec:
	@docker exec -ti hello  #origin master


## run@docker运行hello
.PHONY:run
run:
	@docker rm -f hello
	@docker run -d --name hello -p 8080:8080 hello:1.0
	@docker ps


## my@我的一键式操作
.PHONY:my
my: build run


## help@查看make帮助
.PHONY:help
help:Makefile
	@echo "Usage: \n  make [command]"
	@echo
	@echo "Available Commands:"
	@sed -n "s/^##//p" $< | column -t -s '@' |grep --color=auto "^[[:space:]][a-z]\+[[:space:]]"
	@echo "For more to https://github.com/hollson\n"