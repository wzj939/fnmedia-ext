# fnmedia-ext 定制版功能说明与运维指南（Custom Fork Guide）

- **仓库地址**：https://github.com
- **本地目录**：`/path/to/fnmedia-ext`

---

## 一、已定制功能总览（保留原项目 VERSION 版本号）

1. **独立媒体播放流代理 & 服务端切片预读缓存**
   - `proxy/config.py`：新增 `stream_proxy`、`stream_proxy_mode` 与 `stream_prefetch_segs` 配置项。
   - `proxy/hls_race.py`：m3u8 清单与 100% ts 分片独立代理池、智能切换（`auto`）及有界内存环形预读缓存（上限 120MB，修复元组解包与字节统计）。
   - `proxy/admin_api.py`：新增 `/v/api/ext/stream-proxy` 保存与连通性测试接口。
   - `proxy/admin_ui.py`：管理页新增「🎬 媒体播放流代理」设置面板（支持 `智能` / `始终走代理` / `NAS直连` 及切片预读缓存档位）。

2. **MoonTV-SUB / LunaTV 订阅解析 & 合并独立库**
   - `proxy/tvbox.py`：新增 Base58 密文解码与 MoonTV/LunaTV `api_site` 格式适配。
   - `proxy/admin_ui.py`：添加栏支持直填订阅 URL 或 Base58 密文，新增「合并库」与「🔞隔离」显式复选框及操作指南。
   - `proxy/admin_api.py`：支持按自定义名称合并成单个独立媒体库（`lib_group`）并支持限制级隔离标记。
   - `proxy/config.py`：新增 `set_source_group` 持久化库分组与限制级隔离属性。
   - `proxy/catalog.py`：支持 `group:<库名>` 作用域路由汇聚与福利分类自动开放。
   - `proxy/app.py`：媒体库首页将同组独立源合并渲染为单张独立媒体库卡片。
   - `proxy/subscriptions.py`：URL 订阅自动定时刷新时自动继承当时的「合并库」与「🔞隔离」属性。

3. **全链路性能调度与零 504 优先级保护**
   - **焦点库满血提速**：点开任意片库时自动激活 60 秒加速窗口（最高 16 并发 + 16 源）；未点开的库与后台预热自动降为低功耗节流模式（2~3 并发 / 前 4~6 源）。
   - **CPU 负载感知自适应**：实时监测 `os.getloadavg()`，高负载时自动收紧并发数与活跃源上限。
   - **零 504 优先级保护**：扩展进程自动降低系统调度优先级（`nice=10`）礼让飞牛影视主程序；前台请求触发时后台预热与探测自动让路 5 秒，单次并发拉取严格封顶 `8.5s` 超时熔断。
   - **慢源沉底动态排序与探活限流**：合并库成员源自动按健康度与响应延迟动态排序（最快源优先、坏源自动沉底）；外站封面海报代理限制最多 6 并发下载，后台验活限制最多 2 个队列（每批最多 6 部影片）。

4. **专属云端自更新源**
   - `proxy/updater.py`：`REPO_SLUG` 已指向 `"wzj939/fnmedia-ext"`。

---

## 二、前置一次性设置（GitHub 网页开启云端自动打包权限）

1. 打开 https://github.com
2. 点击顶部 **Actions** 标签 -> 如有提示点击绿色按钮启用 Workflows。
3. 点击 **Settings** -> 左侧 **Actions** -> **General** -> 底部 **Workflow permissions**：
   选择 **"Read and write permissions"** -> 点击 **Save** 保存。

---

## 三、日常同步上游作者更新 & 打包安装（保留原作者版本号）

### 第 1 步：网页同步原作者新代码
打开 https://github.com ，在 `main` 分支点击 **"Sync fork"** -> **"Update branch"**。

### 第 2 步：NAS 终端拉取更新（保留原项目 VERSION 版本号）
```bash
cd /path/to/fnmedia-ext
git checkout main
git pull origin main

# 保留原项目 VERSION 文件版本号，直接本地打包生成最新 .fpk
bash packaging/fpk/build.sh
# 产物路径：dist/fnmedia-ext-\$(cat VERSION).fpk
# 安装方式：飞牛 OS「应用中心 -> 手动安装」上传覆盖安装（所有配置均会保留）
```

### 可选：发布到 GitHub Release 走后台一键更新
```bash
CUR_VER=\$(cat VERSION | tr -d \('\r\\)n')
git tag -f "v\${CUR_VER}"
git push origin main
git push -f origin "v\${CUR_VER}"
```

---

## 四、自己修改代码后提交与本地打包

1. **提交代码到 GitHub**：
   ```bash
   cd /path/to/fnmedia-ext
   git status
   git add .
   git commit -m "描述修改内容"
   git push origin main
   ```

2. **本地手动编译生成 `.fpk` 安装包**：
   ```bash
   cd /path/to/fnmedia-ext
   bash packaging/fpk/build.sh
   ```

---

## 五、MoonTV-SUB / LunaTV 订阅导入与「合并独立库」使用说明

1. **支持的订阅格式**（均已集成至添加框与「导入订阅」页）：
   - MoonTV / LunaTV / DecoTV 格式（`{"api_site": {...}}`）
   - Base58 编码密文、FongMi 十六进制 AES 密文、Base64 及标准 TVBox JSON

2. **添加与合并建库操作步骤**（资源站页面底部添加栏）：
   - **单个添加**：填接口地址 -> 选填名称 -> 勾「独立库」单独建库（不勾则入主库）-> 点「添加」。
   - **批量导入合并库**：在「名称」填自定义库名（如 `R18合集`）-> 接口框填入订阅 URL 或直接粘贴 Base58 密文 -> 同时勾选「独立库」+「合并库」-> 点「添加」，即可将整份订阅聚合成唯一一张独立媒体库卡片。
   - **限制级隔离（🔞）**：添加时勾选「🔞隔离」（或库名/链接含 `18+`/`r18`/`成人`/`福利`）即可强制与主库完全隔离、不进全局搜索；导入后也可在资源站列表「选项」列单独切换。

3. **自动更新机制**：
   - 通过「URL 链接」导入的订阅会自动登记到后台定时刷新任务（默认每 24 小时自动同步），且自动刷新新增的源会自动继承当时设定的「合并库（`lib_group`）」与「🔞隔离」属性。
   - 通过「直接粘贴 Base58 / JSON 文本」导入的属于静态导入，不会自动更新；如需更新，重新粘贴覆盖一次即可（自动去重）。

---

## 六、媒体播放流代理与性能防卡顿建议

1. **播放流代理模式**（管理后台「🎬 媒体播放流代理」卡片）：
   - **🪄 智能（`auto`）**：NAS 优先直连 CDN，遇到 403/超时的锁区 CDN 自动切到 `stream_proxy` 代理。
   - **始终走代理（`on`）**：所有 m3u8 清单与 100% 的 ts 分片均强制经 NAS 代理出口中转（海外网络看国内资源站推荐）。
   - **NAS直连（`off`）**：忽略代理地址，全部由 NAS 直连转发。
2. **日常使用与防 504 黄金法则**：
   - **冷启动预热缓冲**：每次覆盖安装或重启 `fnmedia-ext` 后，稍等 **10~15 秒**让后台完成首轮索引预热，再打开 PC/TV 端播放即可秒开。
   - **精简慢源**：导入合集订阅后，在「资源站」点击「全部测速」，删除/停用测速失败或延迟 > 3000ms 的慢源，只保留响应最快的 4~6 个主力源。
   - **切片预读缓存**：性能充裕时可开「3 片（推荐）」；若源站较多或 NAS 负载偏高，保持「关闭」即可获得最低 CPU 占用。

---

## 七、常用排错与服务管理命令（飞牛 NAS 终端）

- 查看扩展实时日志：`journalctl -u fnmedia-ext -n 50 --no-pager`
- 重启扩展服务：`systemctl restart fnmedia-ext`
- 查看服务运行状态：`systemctl status fnmedia-ext`
- 配置文件与备份：`/vol1/@appcenter/fnmedia-ext/repo/state/config.json`（自动保留最近 5 份备份）
