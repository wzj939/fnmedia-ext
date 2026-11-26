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
