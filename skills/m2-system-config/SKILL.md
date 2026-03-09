---
name: m2-system-config
description: >
  Generate Magento 2 system configuration including system.xml tabs, sections,
  groups and fields, config.xml defaults, custom source models, backend models,
  frontend models, encrypted fields, and ScopeConfigInterface config readers.
  Use this skill whenever the user asks to create admin configuration, store
  settings, or system configuration fields.
  Trigger on: "system.xml", "system configuration", "admin config", "store config",
  "config.xml", "source model", "backend model", "frontend model", "encrypted field",
  "config field", "ScopeConfigInterface", "admin settings", "store settings",
  "configuration section", "config reader", "depends", "field dependency",
  "config tab", "config group", "select field", "multiselect field", "obscure field",
  "feature flag", "toggle", "setting".
---

# Magento 2 System Configuration

You are a Magento 2 system configuration specialist. Generate system.xml, config.xml, custom source/backend/frontend models, and config reader services under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- You need admin-editable configuration (API keys, feature toggles, limits, thresholds)
- You need encrypted storage for sensitive data (API secrets, passwords)
- You need scope-specific config (different per store view/website)
- You need field dependencies (show field B only when field A = yes)

**Do NOT use this skill when:**
- The data is per-entity — use `/m2-db-schema` or `/m2-eav-attributes`
- The config is developer-only and not admin-editable — use `env.php`
- You need complex data structures — use a custom table via `/m2-db-schema`

**Boundary:** `/m2-module` has a minimal system.xml/config.xml stub. This skill provides the FULL system.xml feature set including custom models, encryption, dependencies, and typed config readers.

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Section ID** — e.g., `acme_shipping`
- **Fields** — name + type for each (e.g., `enabled:select`, `api_key:text`, `api_secret:obscure`)

**Optional (use defaults if not specified):**
- **Custom tab?** — default: use existing `general` tab
- **Scope** — default: `showInDefault="1" showInWebsite="1" showInStore="1"`
- **Encrypted fields?** — default: no
- **Field dependencies?** — default: none
- **Custom source models?** — default: use built-in when possible

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Section ID | `{vendor_lower}_{module_lower}` | `acme_shipping` |
| Group ID | descriptive snake_case | `api_settings` |
| Field ID | descriptive snake_case | `api_key` |
| Config path | `{section}/{group}/{field}` | `acme_shipping/api_settings/api_key` |
| Tab ID | `{vendor_lower}` | `acme` |
| Source model class | `Model\Config\Source\{Name}` | `Model\Config\Source\ShippingMethod` |
| Backend model class | `Model\Config\Backend\{Name}` | `Model\Config\Backend\ApiKey` |
| Config reader class | `Model\Config` or `Model\{Feature}Config` | `Model\ShippingConfig` |

## 4. Templates

### 4.1 system.xml — Full Section with Groups and Fields

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
        <section id="{section_id}" translate="label" sortOrder="100"
                 showInDefault="1" showInWebsite="1" showInStore="1">
            <label>{Section Label}</label>
            <tab>general</tab>
            <resource>{Vendor}_{ModuleName}::config</resource>
            <group id="{group_id}" translate="label" sortOrder="10"
                   showInDefault="1" showInWebsite="1" showInStore="1">
                <label>{Group Label}</label>
                <field id="enabled" translate="label" type="select" sortOrder="10"
                       showInDefault="1" showInWebsite="1" showInStore="1">
                    <label>Enabled</label>
                    <source_model>Magento\Config\Model\Config\Source\Yesno</source_model>
                </field>
                <field id="{field_id}" translate="label comment" type="text" sortOrder="20"
                       showInDefault="1" showInWebsite="1" showInStore="0">
                    <label>{Field Label}</label>
                    <comment>{Help text}</comment>
                    <depends>
                        <field id="enabled">1</field>
                    </depends>
                </field>
            </group>
        </section>
    </system>
</config>
```

### 4.2 system.xml — Custom Tab

Only create a custom tab when the vendor has multiple modules that should be grouped together. Most modules use existing tabs (`general`, `catalog`, `customer`, `sales`, `services`, `advanced`).

```xml
<system>
    <tab id="{tab_id}" translate="label" sortOrder="200">
        <label>{Tab Label}</label>
    </tab>
    <section id="{section_id}" ...>
        <tab>{tab_id}</tab>
        ...
    </section>
</system>
```

### 4.3 config.xml — Default Values

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <{section_id}>
            <{group_id}>
                <enabled>0</enabled>
                <{field_id}>{default_value}</{field_id}>
            </{group_id}>
        </{section_id}>
    </default>
</config>
```

### 4.4 Encrypted Field (API Keys, Passwords)

```xml
<field id="api_secret" translate="label" type="obscure" sortOrder="30"
       showInDefault="1" showInWebsite="1" showInStore="0">
    <label>API Secret</label>
    <backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>
</field>
```

Values are encrypted in the database. When reading via `ScopeConfigInterface`, values are automatically decrypted.

### 4.5 Field with Dependency

```xml
<field id="api_endpoint" translate="label" type="text" sortOrder="40"
       showInDefault="1" showInWebsite="1" showInStore="0">
    <label>API Endpoint</label>
    <depends>
        <field id="enabled">1</field>
    </depends>
</field>
```

Multiple dependencies are ANDed. For complex logic, use a `<frontend_model>` with custom JavaScript.

### 4.6 Select Field with Custom Source Model

```xml
<field id="shipping_method" translate="label" type="select" sortOrder="20"
       showInDefault="1" showInWebsite="1" showInStore="0">
    <label>Shipping Method</label>
    <source_model>{Vendor}\{ModuleName}\Model\Config\Source\{SourceName}</source_model>
</field>
```

### 4.7 Custom Source Model — `Model/Config/Source/{SourceName}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Config\Source;

use Magento\Framework\Data\OptionSourceInterface;

final class {SourceName} implements OptionSourceInterface
{
    public function toOptionArray(): array
    {
        return [
            ['value' => '', 'label' => __('-- Please Select --')],
            ['value' => 'option1', 'label' => __('Option One')],
            ['value' => 'option2', 'label' => __('Option Two')],
        ];
    }
}
```

### 4.8 Custom Backend Model (Validation on Save) — `Model/Config/Backend/{Name}.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Config\Backend;

use Magento\Framework\App\Config\Value;
use Magento\Framework\Exception\LocalizedException;

class {BackendName} extends Value
{
    public function beforeSave(): self
    {
        $value = (string) $this->getValue();

        if ($value !== '' && !$this->isValid($value)) {
            throw new LocalizedException(
                __('Invalid value for "%1".', $this->getFieldConfig()['label'])
            );
        }

        return parent::beforeSave();
    }

    private function isValid(string $value): bool
    {
        // Validation logic here
        return true;
    }
}
```

### 4.9 Config Reader Service — `Model/Config.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model;

use Magento\Framework\App\Config\ScopeConfigInterface;
use Magento\Store\Model\ScopeInterface;

final class Config
{
    private const XML_PATH_ENABLED = '{section_id}/{group_id}/enabled';
    private const XML_PATH_API_KEY = '{section_id}/{group_id}/api_key';
    private const XML_PATH_API_SECRET = '{section_id}/{group_id}/api_secret';

    public function __construct(
        private readonly ScopeConfigInterface $scopeConfig
    ) {
    }

    public function isEnabled(?int $storeId = null): bool
    {
        return $this->scopeConfig->isSetFlag(
            self::XML_PATH_ENABLED,
            ScopeInterface::SCOPE_STORE,
            $storeId
        );
    }

    public function getApiKey(?int $storeId = null): string
    {
        return (string) $this->scopeConfig->getValue(
            self::XML_PATH_API_KEY,
            ScopeInterface::SCOPE_STORE,
            $storeId
        );
    }

    public function getApiSecret(?int $storeId = null): string
    {
        return (string) $this->scopeConfig->getValue(
            self::XML_PATH_API_SECRET,
            ScopeInterface::SCOPE_STORE,
            $storeId
        );
    }
}
```

For the complete field type reference and built-in source/backend model list, see `.claude/skills/m2-system-config/references/field-types.md`.

## 5. Generation Rules

Follow this sequence when generating system configuration:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct user to run `/m2-module`.

2. **Create or update `etc/adminhtml/system.xml`** — add section/groups/fields. If the file exists, merge new groups/fields into the existing section.

3. **Create or update `etc/config.xml`** — add default values for every field defined in system.xml.

4. **Create or update `etc/acl.xml`** — ensure `{Vendor}_{ModuleName}::config` resource exists under `Magento_Backend::admin`.

5. **If select/multiselect fields need custom options:** create source model classes. Use built-in source models when they match (see references/field-types.md).

6. **If encrypted fields:** add `<backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>` — no custom class needed.

7. **If custom validation on save:** create backend model class.

8. **Create a Config reader service** — `Model/Config.php` with constants and typed methods for every field.

9. **Remind the user** to run post-generation commands.

## 6. Anti-Patterns

**Hardcoding config paths as strings everywhere.**
Create a Config reader class with constants. This centralizes paths and provides typed access. Other classes inject the Config reader, never `ScopeConfigInterface` directly.

**Using `getValue()` for boolean fields.**
Use `isSetFlag()` which correctly handles `0`/`1`/`true`/`false`/`null`. `getValue()` returns a string, which is always truthy for `"0"`.

**Missing config.xml defaults.**
Every field in system.xml should have a default in config.xml. Without defaults, `getValue()` returns null on fresh installs before admin saves config.

**Wrong scope visibility.**
`showInStore="1"` means per-store-view editing. API keys usually should be `showInStore="0"` (website or default only). Display/locale settings should be per-store-view.

**Not encrypting sensitive data.**
API keys, passwords, and secrets MUST use `type="obscure"` + `Encrypted` backend model. Plain text storage of secrets is a security vulnerability. See `/m2-security` for comprehensive security guidance.

**Forgetting ACL resource.**
Without `<resource>` in the section element, any admin user can see/edit the config. Always reference an ACL resource.

**Duplicating source model options across fields.**
If multiple fields share the same options, use a single source model class.

## 7. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: layout XML / templates / config changes, new module enable.

**Verification:** Fields appear under: **Stores > Configuration > {Tab} > {Section}**
