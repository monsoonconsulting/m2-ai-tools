# Cron Expression Reference

## Cron Expression Syntax

Magento cron expressions use the standard 5-field format:

```
┌───────────── minute (0-59)
│ ┌───────────── hour (0-23)
│ │ ┌───────────── day of month (1-31)
│ │ │ ┌───────────── month (1-12)
│ │ │ │ ┌───────────── day of week (0-7, 0 and 7 = Sunday)
│ │ │ │ │
* * * * *
```

### Special Characters

| Character | Meaning | Example |
|-----------|---------|---------|
| `*` | Any value | `* * * * *` = every minute |
| `,` | List separator | `0,30 * * * *` = at minute 0 and 30 |
| `-` | Range | `0 9-17 * * *` = every hour from 9 AM to 5 PM |
| `/` | Step/interval | `*/5 * * * *` = every 5 minutes |

## Common Schedule Expressions

| Expression | Description |
|-----------|-------------|
| `* * * * *` | Every minute |
| `*/5 * * * *` | Every 5 minutes |
| `*/10 * * * *` | Every 10 minutes |
| `*/15 * * * *` | Every 15 minutes |
| `*/30 * * * *` | Every 30 minutes |
| `0 * * * *` | Every hour (at minute 0) |
| `0 */2 * * *` | Every 2 hours |
| `0 */4 * * *` | Every 4 hours |
| `0 */6 * * *` | Every 6 hours |
| `0 0,12 * * *` | Twice a day (midnight and noon) |
| `0 0 * * *` | Daily at midnight |
| `0 2 * * *` | Daily at 2:00 AM |
| `0 3 * * *` | Daily at 3:00 AM |
| `30 1 * * *` | Daily at 1:30 AM |
| `0 0 * * 0` | Weekly on Sunday at midnight |
| `0 2 * * 1` | Weekly on Monday at 2:00 AM |
| `0 0 1 * *` | Monthly on the 1st at midnight |
| `0 3 1 * *` | Monthly on the 1st at 3:00 AM |
| `0 0 1,15 * *` | Twice a month (1st and 15th) |

## Schedule Recommendations by Job Type

| Job Type | Recommended Schedule | Rationale |
|----------|---------------------|-----------|
| Cache warming | `0 */4 * * *` (every 4 hours) | Balance freshness vs resource usage |
| Log/record cleanup | `0 2 * * *` (daily 2 AM) | Off-peak, once daily is sufficient |
| External data sync (inventory, prices) | `*/15 * * * *` to `0 * * * *` | Depends on SLA; 15 min to hourly is typical |
| Report generation | `0 1 * * *` (daily 1 AM) | Off-peak, data completeness for prior day |
| Email digest / notifications | `0 8 * * *` (daily 8 AM) | Business hours, once daily |
| Expired token/session cleanup | `0 3 * * *` (daily 3 AM) | Off-peak, daily is sufficient |
| Index-related sync | `*/5 * * * *` (every 5 min) | Near-real-time but not every minute |
| Health check / monitoring | `*/10 * * * *` (every 10 min) | Frequent enough to catch issues quickly |
| Heavy imports/exports | `0 2 * * 0` (weekly Sunday 2 AM) | Lowest traffic period, weekly batch |
| Cart/quote abandonment | `0 */6 * * *` (every 6 hours) | Multiple times daily but not excessive |

## config_path Convention

When using `<config_path>` in crontab.xml, the path must follow this exact format:

```
crontab/{group_id}/jobs/{job_name}/schedule/cron_expr
```

The matching config.xml structure:

```xml
<default>
    <crontab>
        <{group_id}>
            <jobs>
                <{job_name}>
                    <schedule>
                        <cron_expr>{expression}</cron_expr>
                    </schedule>
                </{job_name}>
            </jobs>
        </{group_id}>
    </crontab>
</default>
```

The `{group_id}` in the config path must match the `<group id="">` in crontab.xml. The `{job_name}` must match the `<job name="">` attribute.

## Group Configuration Defaults

| Setting | `default` | `index` | `consumers` |
|---------|-----------|---------|-------------|
| `schedule_generate_every` | 1 | 1 | 1 |
| `schedule_ahead_for` | 4 | 4 | 4 |
| `schedule_lifetime` | 2 | 2 | 2 |
| `history_cleanup_every` | 10 | 10 | 10 |
| `history_success_lifetime` | 60 | 60 | 60 |
| `history_failure_lifetime` | 600 | 600 | 600 |
| `use_separate_process` | 0 | 1 | 1 |

Note: The `default` group uses `use_separate_process=0` (runs in the main cron process), while `index` and `consumers` use `1` (separate PHP process).
