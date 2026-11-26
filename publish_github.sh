#!/usr/bin/env bash
set -e
cd /vol1/1000/system/Dockerfile/fnmedia-ext

CUR_VER=$(head -n1 VERSION | tr -d '[:space:]')
NOTE_FILE=$(ls -1 *PRIVATE_NOTES*.md 2>/dev/null | head -n 1)

echo "=== 1. 自动提取私有笔记最新变更并脱敏简化生成 RELEASE_NOTES.md & CHANGELOG.md ==="
python3 - "$CUR_VER" "$NOTE_FILE" <<'PY'
import re
import sys
from pathlib import Path

ver = sys.argv[1]
note_path = Path(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else None

def sanitize(line: str) -> str:
    # 1) 去除内网/本机敏感路径、IP、代理端口、Commit Hash、书签标签、时间戳
    s = re.sub(r"/vol1/[^\s`\"'）)]+", "[路径]", line)
    s = re.sub(r"\b\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?\b", "[内网地址]", s)
    s = re.sub(r"（黄金还原点[^）]*）", "", s)
    s = re.sub(r"`safe-[^`]+`", "", s)
    s = re.sub(r"Commit\s*`[0-9a-f]+`", "", s)
    # 2) 敏感关键词泛化（避免在公开 Release 页面出现敏感词）
    s = re.sub(r"限制级源站|成人向|福利库|黄漫|里番|伦理片|adult=True|ADULT_CAT|adult_allowed", "独立订阅源站", s, flags=re.I)
    s = re.sub(r"OVS\s*网卡", "复杂网卡环境", s, flags=re.I)
    s = re.sub(r"\s{2,}", " ", s).strip()
    return s

bullets = []
if note_path and note_path.exists():
    lines = note_path.read_text(encoding="utf-8").splitlines()
    # 找到“三、日常自动同步发版流水日志”之后的最后一条版本记录块
    in_log = False
    last_block = []
    cur_block = []
    for ln in lines:
        if "日常自动同步发版流水日志" in ln:
            in_log = True
            continue
        if not in_log:
            continue
        if ln.startswith("* ["):
            if cur_block:
                last_block = cur_block
            cur_block = [ln]
        elif cur_block:
            cur_block.append(ln)
    if cur_block:
        last_block = cur_block

    for raw in last_block[1:]:
        s = raw.strip()
        if s.startswith("- "):
            clean = sanitize(s[2:])
            if clean:
                bullets.append(f"- {clean}")

if not bullets:
    bullets = [
        "- 优化播放流转发架构与客户端直连体验，大幅降低服务端资源占用。",
        "- 提升后台元数据刮削与缓存预热并发速度，优化详情页起播响应。",
        "- 修复已知分类路由与多端海报兼容问题，提升整体运行稳定性。",
    ]

# 简化提炼（最多保留 8 条核心要点）
bullets = bullets[:8]
release_md = f"## v{ver} 更新说明\n\n" + "\n".join(bullets) + "\n"
Path("RELEASE_NOTES.md").write_text(release_md, encoding="utf-8")

# 同步写入 CHANGELOG.md 顶部（若该版本尚未写入或需刷新）
cl_p = Path("CHANGELOG.md")
if cl_p.exists():
    cl_txt = cl_p.read_text(encoding="utf-8")
    # 替换或插入当前版本段落
    pattern = re.compile(rf"## v{re.escape(ver)}[^\n]*\n(?:.*?\n)(?=## v|\Z)", re.S)
    if pattern.search(cl_txt):
        cl_txt = pattern.sub(release_md + "\n", cl_txt, count=1)
    else:
        marker = "## v"
        idx = cl_txt.find(marker)
        if idx != -1:
            cl_txt = cl_txt[:idx] + release_md + "\n" + cl_txt[idx:]
        else:
            cl_txt = cl_txt.rstrip() + "\n\n" + release_md
    cl_p.write_text(cl_txt, encoding="utf-8")

print("✅ 已自动脱敏并生成简洁版 RELEASE_NOTES.md：")
print(release_md)
PY

echo "=== 2. 提交脱敏更新日志并推送到 GitHub 触发云端 Release ==="
git add RELEASE_NOTES.md CHANGELOG.md publish_github.sh 2>/dev/null || true
git commit -m "docs(release): auto-generate sanitized release notes for v${CUR_VER}" 2>/dev/null || true
git tag -f safe-1.2.9-1 2>/dev/null || true

git push -f origin main
git push -f origin custom
git tag -f "v${CUR_VER}-fpk" custom
git push -f origin "refs/tags/v${CUR_VER}-fpk"

if [ -n "$NOTE_FILE" ]; then
  echo "* [$(date '+%Y-%m-%d %H:%M')] 已将稳定版 **${CUR_VER}** 正式发布至 GitHub Releases (\`v${CUR_VER}-fpk\`)" >> "$NOTE_FILE"
fi
/vol1/1000/system/Dockerfile/sync-private-note || true
echo "✅ 已完成脱敏说明生成并推送至 GitHub！云端 Workflows 将在 1~2 分钟内自动生成 Release: v${CUR_VER}-fpk"
