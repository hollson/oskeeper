#==================================================================
# Reference:
#	https://shields.io/
#	https://makefiletutorial.com/
#==================================================================

all: help

## clean@清理编译、日志和缓存等
.PHONY:clean
clean:
	@rm -rf ./bin;
	@rm -rf ./logs;
	@rm -rf ./log;
	@rm -rf ./cache;
	@rm -rf ./pid;
	@rm -rf ./release;
	@rm -rf ./debug;
	@rm -rf ./deploy;
	@rm -rf ./tmp;
	@rm -rf ./temp;
	@rm -rf ./vendor/*;
	@echo "\033[31m ✅  清理完毕\033[0m";

## pack@打包lib库。
.PHONY: pack
pack:
	@cd ./lib && tar -zcvf sdk.tar.gz ./*;
	@mkdir -p release && mv ./lib/sdk.tar.gz ./release;
	@echo "\033[31m ✅  打包完毕\033[0m";


## commit <msg>@提交Git(格式:make commit msg=备注内容,msg为可选参数)。
.PHONY:commit
message:=$(if $(msg),$(msg),"Rebuilded at $$(date '+%Y/%m/%d %H:%M:%S')")
commit:
	@echo "\033[0;34mPush to remote...\033[0m"
	@git add .
	@git commit -m $(message)
	@echo "\033[0;31m 💿 Commit完毕\033[0m"


## push <msg>@提交并推送到Git仓库(格式:make push msg=备注内容,msg为可选参数)。
.PHONY:push
push:commit
	@git push #origin master
	@echo "\033[0;31m ⬆️ Push完毕\033[0m"


## help@查看make帮助。
.PHONY:help
help:Makefile
	@echo "Usage:\n  make [command]"
	@echo
	@echo "Available Commands:"
	@sed -n "s/^##//p" $< | column -t -s '@' |grep --color=auto "^[[:space:]][a-zA-Z0-9_]\+[[:space:]]"
	@echo
	@echo "更多内容,请参考： https://github.com/hollson\n"
