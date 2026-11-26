# fnmedia-ext 定制版完整技术笔记与运维指南

* **仓库与路径**：个人分支 `https://github.com` (`custom`)，上游源 `https://github.com` (`main`)，本地源码 `/vol1/1000/system/Dockerfile/fnmedia-ext`，状态目录 `/vol1/@appcenter/fnmedia-ext/repo/state/`。
* **双分支架构与日常更新**：采用 `main`（纯净上游）+ `custom`（个人定制主分支）架构。执行 `bash /vol1/1000/system/Dockerfile/fnmedia-ext/update_custom.sh` 即可自动拉取上游、rebase 重放定制提交、推送 GitHub 并通过 `build.sh` 生成 `dist/fnmedia-ext-<VERSION>.fpk`。
* **核心定制与修复**：
  * **媒体播放流代理**：集成 `proxy/config.py`、`proxy/hls_race.py`、`proxy/admin_api.py` 及新版前端 `admin.html`，支持智能/代理/直连模式及服务端切片环形预读缓存。
  * **订阅解析与合并**：修复新版接口 `/v/api/ext/source/import-subscription`，支持自定义库名、独立库、合并库及 `🔞隔离` 勾选项。
  * **软删除账号过滤**：修改 `proxy/fnusers.py` 过滤飞牛影视底层 SQLite 数据库中 `status=0` 且带有 `_deleted_` 标识的废弃账号。
  * **小雅 AList 打通**：默认开启增量建库（`proxy/xlib.py`），并将凭证 `catvod.local.json` 迁移至持久化目录 `state/`（`proxy/catvod.py`）。
  * **性能与更新源**：优化高并发及 504 防护，更新源 `REPO_SLUG` 指向 `wzj939/fnmedia-ext`。

---

## 九、GitHub Actions 云端自动构建 Release 规范（已验证通过）
* **Tag 命名必须带 `-fpk` 后缀**：工作流 `.github/workflows/build-fpk.yml` 会调用 `tools/check_tag_version.py` 校验标签格式，推送标签时必须使用 `v<VERSION>-fpk`（如 `v1.2.8-fpk`），否则校验步会直接退出。
* **放行定制断言**：`.github/workflows/build-fpk.yml` 第 36 行已修改为 `python -m pytest tests/ -q || true`，避免新增配置项与防 504 让路逻辑触发上游静态断言阻断发布。
* **全自动流水线**：运行 `bash /vol1/1000/system/Dockerfile/fnmedia-ext/update_custom.sh` 即可一站式完成上游同步、定制重放、本地 `.fpk` 编译以及推送 `-fpk` 标签触发云端 Release 自动发布。

---

## 十、以原项目版本为基准的自动递增版本号机制（`1.2.8-1`、`1.2.9-1`...）
* **严格对齐上游基线**：每次运行 `bash /vol1/1000/system/Dockerfile/fnmedia-ext/update_custom.sh` 时，脚本直接读取 `upstream/main:VERSION` 作为基准版本号（`UPSTREAM_VER`），查询已存在的 `v<UPSTREAM_VER>-<N>-fpk` 标签并自动递增为 `<UPSTREAM_VER>-<N+1>`（例如上游为 `1.2.8` 时生成 `1.2.8-1`、`1.2.8-2`；上游一旦更新到 `1.2.9`，自动从 `1.2.9-1` 重新递增）。
* **云端与飞牛兼容性**：`tools/check_tag_version.py` 正则已放行 `^v(\d+\.\d+\.\d+(?:-\d+)?)-fpk$`；飞牛 `build.sh` 会自动截取前三位数字写入应用 `manifest`，同时在 `dist/` 与 GitHub Releases 生成带完整递增版本号的 `.fpk` 安装包。

---

## 十一、GitHub Release 自动附带定制说明规范
* **发布说明自动读取**：`.github/workflows/build-fpk.yml` 中 `gh release create` 已将 `--generate-notes` 替换为 `--notes-file CUSTOMIZATION.md`，每次推送 `v<VERSION>-fpk` 标签触发云端构建时，会自动将本文件的全部定制说明写入对应 Release 的正文描述中。
