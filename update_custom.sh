#!/usr/bin/env bash
set -e

cd /vol1/1000/system/Dockerfile/fnmedia-ext

echo "=== 1. 拉取原项目 (upstream) 最新代码 ==="
git fetch upstream --no-tags

echo "=== 2. 同步纯净 main 分支 ==="
git checkout main
git reset --hard upstream/main
git push -f origin refs/heads/main

echo "=== 3. 将你的个人定制修改自动重放到最新代码之上 ==="
git checkout custom
if ! git rebase upstream/main; then
    echo "⚠️ 遇到极少数文件冲突！请编辑提示冲突的文件后，执行："
    echo "   git add . && git rebase --continue"
    echo "   然后重新运行 bash update_custom.sh"
    exit 1
fi

echo "=== 4. 推送更新后的 custom 分支到你的 GitHub ==="
git push -f origin custom

echo "=== 5. 本地编译打包最新全功能完整版 .fpk ==="
bash packaging/fpk/build.sh

CUR_VER=$(cat VERSION | tr -d '\r\n')
echo "✅ 全部完成！最新安装包已生成：dist/fnmedia-ext-${CUR_VER}.fpk"

echo "=== 6. 推送 v${CUR_VER}-fpk 标签触发 GitHub 云端自动构建 Release ==="
git tag -f "v${CUR_VER}-fpk" custom
git push -f origin "refs/tags/v${CUR_VER}-fpk"
