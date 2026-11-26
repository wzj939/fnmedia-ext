## v1.2.9-1 更新说明

- **fix(catalog) 根治路由重探死循环**：修复 `1.2.9` `_load_route_state` 遇到子分类 `want=None` 时误判过期并无限全量重探采集源导致 `uvicorn` 事件循环卡死的 Bug，改为 `want is not None` 内存就地迁移。
- **feat(stream-proxy) 新增 LunaTV 架构双直连模式**：在管理页新增 `📱 fn客户端直连`（`fnos`）与 `🛡️ 客户端直连走代理`（`fnos_proxy`）——服务端仅负责抓取并净化 `m3u8` 清单（去广告 + 将 AES-128 密钥内嵌为 Base64 Data URI），所有 `.ts` 视频分片直出源站 CDN 绝对地址由端侧播放器直连拉流，扩展 0 视频流量转发与缓存占用，并完美规避 复杂网卡环境直连问题。
- **fix(stream-proxy) 全量代理出口封堵**：补全 `hls_race.py` 与 `app.py` 中测速探针、首片验证、重定向解析、AES 密钥、短注册表分片 `/segc`、直链 MP4 及 T4 媒体流统一走 `stream_proxy` 出口。
- **feat(detail) 点入详情页最高优先级强拉播放源**：点进任何影片详情页（榜单卡 / 文件夹卡 / 有刮削但 `lines` 为空的常规卡）时，强制清除 `_CHART_FAILED_TS` 失败冷却黑名单并优先插队全网聚合拉源（榜单详情等待窗提至 `5.5s`、文件夹卡优先 `4.5s` 绑定 + 后台全源补齐）。
- **perf(worker) 极致狂暴刮削与后台自动预绑**：`bg_worker` 独立进程将海量库预热并发提至 `12` 路、单类深度扩至 `320` 条，并新增每轮 `6` 路并发自动预绑前 `40` 部未绑定热门榜单片源；前台 `frontend` 改为 `5s` 极速同步并预灌首屏 `80` 条内存缓存（选片竞速 `2.2s`、盘搜熔断 `10.0s`）。
- **fix(catalog) 独立订阅源站分类硬隔离**：在 `classify_source_class` 顶部加装硬隔离铁律（`if 独立订阅源站: return 独立订阅源站`）并清洗历史 `catalog_routes.json` 中泄露进公共分类的 49 条子目录，实现公共海量库与 `adult` 独立库 100% 零串库。
- **fix(poster) 修复安卓 App 与安卓 TV 在线资源无海报**：在 `inject.detail_item` 与 `client.normalize_cards`/`normalize_detail` 出口植入 `poster` / `posters` / `backdrops` 三字段互兜底，补全安卓与 TV 原生界面读取的单数 `poster` 字段，全端海报恢复秒出。
