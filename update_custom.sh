#!/usr/bin/env bash
set -e

cd /vol1/1000/system/Dockerfile/fnmedia-ext

echo "=== 1. 拉取原项目 (upstream) 最新代码 ==="
git fetch upstream --no-tags
git fetch origin --tags --force

echo "=== 2. 同步纯净 main 分支 ==="
git checkout main
git reset --hard upstream/main
git push -f origin refs/heads/main

echo "=== 3. 将定制分支重放到最新原项目代码之上 ==="
git checkout custom
# 放弃旧的自定义 VERSION 改动，避免 rebase 时发生 VERSION 冲突
git checkout HEAD~1 -- VERSION 2>/dev/null || git checkout upstream/main -- VERSION
if ! git diff --quiet VERSION; then
    git commit -m "chore: reset VERSION before rebase" VERSION
fi

if ! git rebase upstream/main; then
    echo "⚠️ 遇到极少数文件冲突！请编辑提示冲突的文件后，执行："
    echo "   git add . && git rebase --continue"
    echo "   然后重新运行 bash update_custom.sh"
    exit 1
fi

echo "=== 4. 严格以原项目当前最新 VERSION 为基准递增后缀 ==="
UPSTREAM_VER=$(git show upstream/main:VERSION | head -n1 | tr -d '[:space:]')
MAX_REV=$(git tag -l "v${UPSTREAM_VER}-*-fpk" | sed -E "s/^v${UPSTREAM_VER}-([0-9]+)-fpk$/\1/" | sort -n | tail -n1)
NEXT_REV=$(( ${MAX_REV:-0} + 1 ))
NEW_VER="${UPSTREAM_VER}-${NEXT_REV}"

echo "${NEW_VER}" > VERSION
git add VERSION
git commit -m "chore(release): bump custom version to ${NEW_VER}"
echo "🔖 已对齐原项目版本 (${UPSTREAM_VER})，生成定制版本号: ${NEW_VER}"

echo "=== 5. 推送 custom 分支与 v${NEW_VER}-fpk 标签触发云端 Release ==="
git push -f origin custom
git tag -f "v${NEW_VER}-fpk" custom
git push -f origin "refs/tags/v${NEW_VER}-fpk"

echo "=== 6. 本地编译打包最新全功能完整版 .fpk ==="
bash packaging/fpk/build.sh

echo "- [$(date "+%Y-%m-%d %H:%M")] 自动同步上游 (${UPSTREAM_VER}) 并打包发布定制版 **${NEW_VER}**" >> PRIVATE_NOTES.md
cp -r proxy/* /vol1/@appcenter/fnmedia-ext/repo/proxy/
cp VERSION /vol1/@appcenter/fnmedia-ext/repo/VERSION
systemctl restart fnmedia-ext
echo "✅ 全部完成！当前定制版本号: ${NEW_VER}"
echo "📦 本地安装包: dist/fnmedia-ext-${NEW_VER}.fpk"
