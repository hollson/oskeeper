#!/bin/bash
# Docker 资源清理脚本
# 功能：清理无用容器、镜像、卷、网络等资源

# 日志文件路径
LOG_FILE="./docker_cleanup_$(date +%Y%m%d_%H%M%S).log"

# 打印信息并写入日志
log() {
    echo "[$(date +%Y-%m-%d_%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "===== 开始 Docker 资源清理 ====="

# 1. 清理停止的容器
log "=== 清理停止的容器 ==="
if docker container prune -f; then
    log "停止的容器清理完成"
else
    log "容器清理失败"
fi

# 2. 清理悬空镜像（标签为<none>）
log "=== 清理悬空镜像 ==="
if docker image prune -f; then
    log "悬空镜像清理完成"
else
    log "悬空镜像清理失败"
fi

# 3. 清理无用卷（未被任何容器引用）
log "=== 清理无用卷 ==="
if docker volume prune -f; then
    log "无用卷清理完成"
else
    log "卷清理失败"
fi

# 4. 清理无用网络
log "=== 清理无用网络 ==="
if docker network prune -f; then
    log "无用网络清理完成"
else
    log "网络清理失败"
fi

# 可选：清理所有未被使用的镜像（包括有标签但未使用的）
# 注意：此操作会删除更多镜像，启用前请确认
log "=== 是否清理所有未被使用的镜像？(y/N) ==="
read -r confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    if docker image prune -a -f; then
        log "所有未使用镜像清理完成"
    else
        log "未使用镜像清理失败"
    fi
else
    log "跳过清理所有未使用镜像"
fi

log "===== Docker 资源清理完成 ====="
log "清理日志已保存至：$LOG_FILE"