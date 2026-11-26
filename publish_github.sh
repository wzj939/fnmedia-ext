#!/usr/bin/env bash
set -e
cd /vol1/1000/system/Dockerfile/fnmedia-ext

CUR_VER=$(head -n1 VERSION | tr -d '[:space:]')
echo "=== 正在将已验证稳定的 ${CUR_VER} 推送到 GitHub 并触发云端 Release ==="
git push -f origin main
git push -f origin custom
git tag -f "v${CUR_VER}-fpk" custom
git push -f origin "refs/tags/v${CUR_VER}-fpk"

echo "- [$(date '+%Y-%m-%d %H:%M')] 已将稳定版 **${CUR_VER}** 正式发布至 GitHub Releases (v${CUR_VER}-fpk)" >> PRIVATE_NOTES.md
echo "✅ 已推送至 GitHub！云端 Workflows 将在 1~2 分钟内自动生成 Release: v${CUR_VER}-fpk"
