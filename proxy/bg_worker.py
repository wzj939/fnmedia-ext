#!/usr/bin/env python3
"""独立后台刮削与缓存预热 Worker（最低 CPU/IO 优先级，彻底不阻塞前台主进程）。"""
from __future__ import annotations

import asyncio
import os
import signal
import sys
from pathlib import Path

try:
    os.nice(19)
except Exception:
    pass

sys.path.insert(0, str(Path(__file__).resolve().parent))
os.environ["FNMEDIA_ROLE"] = "worker"

import app as appmod  # noqa: E402
from fnlog import get_logger  # noqa: E402

_log = get_logger("bg_worker")


async def _run() -> None:
    stop_event = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            loop.add_signal_handler(sig, stop_event.set)
        except NotImplementedError:
            pass

    appmod.app.state.stop_hot = stop_event
    _log.info("bg_worker 已启动（Nice=19 低优先级独立进程，负责榜单/路由/预热刮削）")
    t1 = asyncio.create_task(appmod.startup_prewarm_hot(), name="worker_startup_prewarm")
    t2 = asyncio.create_task(appmod._hot_worker(appmod.app), name="worker_hot_loop")
    await stop_event.wait()
    for t in (t1, t2):
        t.cancel()
    await asyncio.gather(t1, t2, return_exceptions=True)
    _log.info("bg_worker 已安全退出")


if __name__ == "__main__":
    try:
        asyncio.run(_run())
    except KeyboardInterrupt:
        pass
