# MySQL 订单数仓与 Kestra 调度

项目从现有 [建表文件](sytra_dw.sql) 中的 `ods_order` 读取订单。ODS 由业务侧写入。SQL 和 Kestra 调度配置随 Git 版本管理。

| Kestra 任务 | 来源 → 目标 | 数据口径 |
| --- | --- | --- |
| [dwd_order_detail](kestra/files/sql/dwd_order_detail.sql) | `ods_order` → `dwd_order_detail` | 每个有效订单一行，ODS 的 `id` 对应 `order_id` |
| [dws_user_order_day](kestra/files/sql/dws_user_order_day.sql) | `dwd_order_detail` → `dws_user_order_day` | 按用户和支付日期汇总订单数、金额 |
| [ads_user_report](kestra/files/sql/ads_user_report.sql) | `dws_user_order_day` → `ads_user_report` | 每个用户每天一行，按当日消费额划分等级 |

[业务 Flow](kestra/flows/order_warehouse.yml) 用 `Dag.dependsOn` 声明依赖。每一层成功后才执行下一层。SQL 文件和任务 ID 都按目标表命名。新增派生表时，用 `<目标表名>.sql` 保存脚本，并在 `dependsOn` 中填写上游任务的目标表名。

- 默认有效订单为 `status = 'PAID'`、用户和支付时间存在、金额大于零的记录。上线前用 `SELECT status, COUNT(*) FROM ods_order GROUP BY status;` 确认实际状态值，并按业务口径修改 SQL。
- 下游 `dt` 按 MySQL 中的 `pay_time` 取支付日期，格式为 `yyyy-MM-dd`。ODS 的 `dt` 可以记录入库日期。
- 示例等级以当日消费额计算。大于等于 1000 为 `HIGH`，100（含）至 1000（不含）为 `MEDIUM`，其余为 `LOW`。

## 连接 MySQL

在同一个 MySQL schema 中准备四张表。新建测试库时可执行 `mysql -u YOUR_USER -p YOUR_DATABASE < sytra_dw.sql`。确认 Kestra Worker 能连接 MySQL，且 Kestra 安装了 MySQL JDBC 和 Git 插件。

| Kestra Secret | 用途 |
| --- | --- |
| `DW_JDBC_URL` | 例如 `jdbc:mysql://host.docker.internal:3306/YOUR_DATABASE?allowMultiQueries=true` |
| `DW_MYSQL_USERNAME` | MySQL 账号 |
| `DW_MYSQL_PASSWORD` | MySQL 密码 |
| `GITHUB_ACCESS_TOKEN` | 私有 GitHub 仓库的只读令牌 |

示例地址适用于 Worker 在 Docker Desktop、MySQL 在宿主机的情况。Worker 直接运行在本机时可用 `127.0.0.1`，与 MySQL 同在 Docker 网络时可用 MySQL 服务名。MySQL 账号需要 ODS 的 `SELECT` 和下游表的 `SELECT`、`INSERT`、`DELETE` 权限。JDBC URL 中的 `allowMultiQueries=true` 允许同一任务执行删除与插入。 [MySQL Queries 插件](https://kestra.io/plugins/plugin-jdbc-mysql/io.kestra.plugin.jdbc.mysql.queries)

## 导入和部署

### 本地验证

在 Kestra UI 的 `syntra.dw` 命名空间中，将 `kestra/files` 下的 SQL 上传为 Namespace Files，保留路径 `sql/*.sql`。导入 [业务 Flow](kestra/flows/order_warehouse.yml) 后手动执行 `order_warehouse`。 [Namespace Files](https://kestra.io/docs/concepts/namespace-files)

### GitHub 自动同步

1. 将项目推送到 GitHub 的 `main` 分支。
2. 在 Kestra UI 中导入一次 [Git 同步 Flow](kestra/sync_from_git.yml)，替换两处 URL 和用户名。公开仓库可删除两处 `username` 和 `password`。若 Kestra API 启用了认证，为同步任务配置对应的 API 凭据。
3. 手动运行 `syntra.ops/sync_syntra_dw`，确认 SQL 出现在 `syntra.dw` 的 Namespace Files，且业务 Flow 已部署。之后同步 Flow 每两分钟检查一次 GitHub。此前部署过旧文件名的实例，确认业务 Flow 已引用新文件后，可以在 Namespace Files 中删除旧文件。
4. 手动运行 `syntra.dw/order_warehouse` 并验数。确认 ODS 到数时间后，将 Git 中 `daily_refresh` 的 `disabled` 改为 `false` 并推送，开启北京时间每天 02:00 的业务调度。 [Kestra Git 同步](https://kestra.io/docs/version-control-cicd/git/sync-from-git)

## 验数与重跑

```sql
SELECT COUNT(*) AS dwd_orders, SUM(order_amount) AS dwd_amount
FROM dwd_order_detail;

SELECT COALESCE(SUM(order_cnt), 0) AS dws_orders, SUM(total_amount) AS dws_amount
FROM dws_user_order_day;

SELECT dt, user_id, order_cnt, total_amount, user_level
FROM ads_user_report
ORDER BY dt DESC, user_id
LIMIT 20;
```

DWD 和 DWS 的订单总数、金额应一致。对相同的 ODS 重跑，报表业务指标应一致，ADS 的 `create_time` 会更新。

本版本适用于小数据量，每次全量重建三个下游表。每层的删除和插入在同一个 InnoDB 事务内执行。迟到订单、支付日期修正及状态变为退款会在下次刷新中反映出来。三层分别提交，中途失败时已经成功的层可能比下游更新。修复后从头执行 Flow。Kestra 将业务 Flow 并发限制为 1。

ODS 需要保留报表所需的完整历史。ODS 为空时下游也会刷新为空。首次运行请使用测试库，并确认下游表由本项目独占写入。DWS 和 ADS 的 `DECIMAL(10,2)` 最多存储 `99,999,999.99`，预计用户日汇总会超限时应扩容，并使用 MySQL 严格 SQL 模式。











