# Admin-Configurable Cron Schedule (Approach A)

## Raw Cron Expression Text Field

This approach lets the admin enter a raw cron expression string (e.g., `*/5 * * * *`).

### config.xml — sets the default schedule:

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <crontab>
            <default>
                <jobs>
                    <{vendor}_{modulename}_{job_name}>
                        <schedule>
                            <cron_expr>{default_expression}</cron_expr>
                        </schedule>
                    </{vendor}_{modulename}_{job_name}>
                </jobs>
            </default>
        </crontab>
    </default>
</config>
```

### system.xml — adds the admin field:

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Config:etc/system_file.xsd">
    <system>
        <section id="{section_id}" translate="label" sortOrder="100" showInDefault="1" showInWebsite="0" showInStore="0">
            <label>{Module Label}</label>
            <tab>general</tab>
            <resource>{Vendor}_{ModuleName}::config</resource>
            <group id="cron" translate="label" sortOrder="20" showInDefault="1" showInWebsite="0" showInStore="0">
                <label>Cron Settings</label>
                <field id="cron_expr" translate="label comment" type="text" sortOrder="10" showInDefault="1" showInWebsite="0" showInStore="0">
                    <label>{Job Label} Schedule</label>
                    <comment><![CDATA[Cron expression (e.g., <code>*/5 * * * *</code> for every 5 minutes). Format: minute hour day-of-month month day-of-week.]]></comment>
                </field>
            </group>
        </section>
    </system>
</config>
```

### crontab.xml — uses `config_path` to read from admin config:

```xml
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Cron:etc/crontab.xsd">
    <group id="default">
        <job name="{vendor}_{modulename}_{job_name}"
             instance="{Vendor}\{ModuleName}\Cron\{ClassName}"
             method="execute">
            <config_path>crontab/default/jobs/{vendor}_{modulename}_{job_name}/schedule/cron_expr</config_path>
        </job>
    </group>
</config>
```

The `config_path` must match the XML path in config.xml: `crontab/{group}/jobs/{job_name}/schedule/cron_expr`.
