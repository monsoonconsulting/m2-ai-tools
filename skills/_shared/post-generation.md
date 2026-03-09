# Post-Generation Commands

After generating code, remind the user to run the appropriate commands based on what was created or modified.

## Command Reference by Artifact Type

| Artifact | Commands |
|----------|----------|
| New module | `bin/magento module:enable Vendor_ModuleName`, `bin/magento setup:upgrade`, `bin/magento cache:flush` |
| di.xml / extension_attributes.xml | `bin/magento setup:di:compile`, `bin/magento cache:flush` |
| db_schema.xml | `bin/magento setup:upgrade`, `bin/magento setup:db-declaration:generate-whitelist --module-name=Vendor_ModuleName`, `bin/magento cache:flush` |
| Data/Schema patches | `bin/magento setup:upgrade`, `bin/magento cache:flush` |
| Layout XML / templates / config changes | `bin/magento cache:flush` |
| Static assets (JS/CSS/RequireJS) | `bin/magento setup:static-content:deploy -f`, `bin/magento cache:flush` |
| cache.xml / cache type | `bin/magento setup:di:compile`, `bin/magento cache:flush`, `bin/magento cache:status` |
| Cron jobs | `bin/magento cache:flush`, `bin/magento cron:run --group={group_id}` (to test) |

## Module Enable Pattern

If the module was not yet enabled:

```bash
bin/magento module:enable {Vendor}_{ModuleName}
bin/magento setup:upgrade
bin/magento setup:di:compile    # If di.xml or extension_attributes.xml was created
bin/magento cache:flush
```

## Combining Commands

When multiple artifact types are generated together (common), combine:

```bash
bin/magento setup:upgrade && bin/magento setup:di:compile && bin/magento cache:flush
```

## Verification Steps

Each skill should add its own verification instructions after referencing this file. Common patterns:

- **Admin UI:** Navigate to the admin panel URL to verify the grid/form loads
- **API:** `curl` command to test the endpoint
- **Cron:** Query `cron_schedule` table for execution history
- **Attributes:** Check `eav_attribute` table or admin attribute manager
- **Email:** Check Marketing > Email Templates in admin
- **Cache:** `bin/magento cache:status` to verify new cache type appears
