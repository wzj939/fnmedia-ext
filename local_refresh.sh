#!/usr/bin/env bash
set -e
cd /vol1/1000/system/Dockerfile/fnmedia-ext
CUR_VER=$(cat VERSION | tr -d '\r\n')
echo "=== 1. 本地重新编译打包当前版本 (${CUR_VER}) ==="
bash packaging/fpk/build.sh
echo "=== 2. 同步最新源码至运行目录并热重启服务 ==="
cp -r proxy/* /vol1/@appcenter/fnmedia-ext/repo/proxy/
cp VERSION /vol1/@appcenter/fnmedia-ext/repo/VERSION
systemctl restart fnmedia-ext
echo "✅ 本地同版本 (${CUR_VER}) 编译并直接更新完成！"
