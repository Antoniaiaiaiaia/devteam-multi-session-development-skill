# 预设：backend（API / 数据库 / 后台任务）

- **管**：公开 API + 管理 API、OpenAPI、数据库 schema / migration / 权限、鉴权、邮件、定时任务、第三方集成、共享类型。
- **不管**：页面和 UI。
- **约束**：schema 只由 backend 改；**migration 不自己推远端**，写好交总管审，总管先推 migration 再部署代码；生产库有"UPDATE / DELETE 必须带 WHERE"之类保护时加静态测试；密钥只走环境变量，新增变量写进 `.env.example`（只写名字和说明）；共享类型改了要同时告诉前端 / 管理后台。
- **Verify**：`npm run verify`（类型检查 + 全部测试）；涉及数据库的测试跑在真实 schema 上；附"未登录 / 无权限被拒"的测试。
- **对外动作**（发频道、发邮件、批量改数据）：先给总管 dry run 的数字和样例，批了再真跑。
- **端口段**：4330–4339。
