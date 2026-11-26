#!/usr/bin/env bash
set -e
cd /vol1/1000/system/Dockerfile/fnmedia-ext

echo "=== 1. 拉取原项目 (upstream) 最新代码 ==="
git fetch upstream --no-tags
git fetch origin --tags --force

echo "=== 2. 同步本地纯净 main 分支 ==="
git checkout main
git reset --hard upstream/main

echo "=== 3. 将定制分支重放到最新原项目代码之上 ==="
git checkout custom
git checkout HEAD~1 -- VERSION 2>/dev/null || git checkout upstream/main -- VERSION
if ! git diff --quiet VERSION; then
    git commit -m "chore: reset VERSION before rebase" VERSION
fi

if ! git rebase upstream/main; then
    echo "⚠️ 遇到极少数文件冲突！请解决冲突后执行：git add . && git rebase --continue，再重新运行本脚本"
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

echo "=== 5. 本地编译打包并直接热更新到当前飞牛运行环境（暂不推送 GitHub） ==="
bash packaging/fpk/build.sh
cp -r proxy/* /vol1/@appcenter/fnmedia-ext/repo/proxy/
cp VERSION /vol1/@appcenter/fnmedia-ext/repo/VERSION
systemctl restart fnmedia-ext

echo "- [$(date '+%Y-%m-%d %H:%M')] 本地同步上游 (${UPSTREAM_VER}) 并热更新至 **${NEW_VER}**（待测试稳定后发布）" >> PRIVATE_NOTES.md
echo "✅ 本地更新完成！当前运行版本: ${NEW_VER}（未触发 GitHub Actions）"
echo "👉 测试满意后，运行 bash /vol1/1000/system/Dockerfile/fnmedia-ext/publish_github.sh 即可发布到 GitHub。"
