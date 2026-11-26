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

echo "=== 3. 无冲突重放你的个人定制修改到最新代码之上 ==="
git checkout custom
# 临时将 VERSION 还原为上次基准版本，防止 rebase 时发生 VERSION 冲突
git checkout upstream/main -- VERSION 2>/dev/null || true
git commit --amend --no-edit 2>/dev/null || true

if ! git rebase upstream/main; then
    echo "⚠️ 遇到极少数文件冲突！请编辑提示冲突的文件后，执行："
    echo "   git add . && git rebase --continue"
    echo "   然后重新运行 bash update_custom.sh"
    exit 1
fi

echo "=== 4. 自动计算递增定制版本号 (如 1.2.8-1) ==="
BASE_VER=$(head -n1 VERSION | tr -d '[:space:]' | sed -E 's/-[0-9]+$//')
MAX_REV=$(git tag -l "v${BASE_VER}-*-fpk" | sed -E "s/^v${BASE_VER}-([0-9]+)-fpk$/\1/" | sort -n | tail -n1)
NEXT_REV=$(( ${MAX_REV:-0} + 1 ))
NEW_VER="${BASE_VER}-${NEXT_REV}"

echo "${NEW_VER}" > VERSION
git add VERSION
git commit --amend -m "feat: custom enhancements (v${NEW_VER})"
echo "🔖 本次自动生成定制版本号: ${NEW_VER}"

echo "=== 5. 推送 custom 分支与 v${NEW_VER}-fpk 标签触发云端 Release ==="
git push -f origin custom
git tag -f "v${NEW_VER}-fpk" custom
git push -f origin "refs/tags/v${NEW_VER}-fpk"

echo "=== 6. 本地编译打包最新全功能完整版 .fpk ==="
bash packaging/fpk/build.sh

echo "✅ 全部完成！定制版本号: ${NEW_VER}"
echo "📦 本地安装包: dist/fnmedia-ext-${NEW_VER}.fpk"
echo "☁️ 云端 Release 将在 1~2 分钟内自动生成: v${NEW_VER}-fpk"
