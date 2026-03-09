---
name: m2-email-template
description: >
  Generate Magento 2 email templates including email_templates.xml registration,
  HTML template files with Magento template syntax, TransportBuilder sender
  services, and admin-configurable template selection via system.xml.
  Use this skill whenever the user asks to create email templates, send
  transactional emails, or configure email notifications.
  Trigger on: "email template", "email_templates.xml", "transactional email",
  "send email", "TransportBuilder", "email notification", "order email",
  "customer email", "email HTML", "email sender", "{{var", "{{trans",
  "{{layout", "create email", "add email template", "custom email",
  "notification email", "order confirmation", "welcome email", "mail".
---

# Magento 2 Email Template Generator

You are a Magento 2 email template specialist. Generate email templates, template registration, sender services, and admin-configurable email settings under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- You need to send transactional emails (order confirmation, account notifications, custom alerts)
- You need admin-editable email templates
- You need to register new email template types

**Do NOT use this skill when:**
- You only need system configuration — use `/m2-system-config`
- You need to modify existing Magento email behavior — use `/m2-plugin` on TransportBuilder

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Email purpose** — what the email is for (e.g., "order export notification")
- **Template variables** — data passed to the template (e.g., `customer_name`, `order_id`)

**Optional (use defaults if not specified):**
- **Admin-configurable template?** — default: yes (generates system.xml field)
- **Sender identity** — default: `general` (General Contact). Options: `general`, `sales`, `support`, `custom1`, `custom2`
- **Email area** — default: `frontend`

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Template ID | `{vendor}_{modulename}_{purpose_snake}` | `acme_shipping_export_notification` |
| Template file | `view/{area}/email/{template_name}.html` | `view/frontend/email/export_notification.html` |
| Sender service | `Service\Email\{Purpose}Sender` | `Service\Email\ExportNotificationSender` |
| Config path (template) | `{section}/{group}/{template_id}` | `acme_shipping/email/export_notification_template` |
| Config path (enabled) | `{section}/{group}/enabled` | `acme_shipping/email/enabled` |

## 4. Templates

### 4.1 email_templates.xml — `etc/email_templates.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Email:etc/email_templates.xsd">
    <template id="{template_id}"
              label="{Template Label}"
              file="{template_name}.html"
              type="html"
              module="{Vendor}_{ModuleName}"
              area="frontend"/>
</config>
```

The `file` is relative to `view/{area}/email/`. The `id` is used in `config.xml` and `system.xml`.

### 4.2 Email HTML Template — `view/{area}/email/{template_name}.html`

```html
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<!--@subject {{trans "Your {Purpose} Notification"}} @-->
<!--@vars {
"var customer_name":"Customer Name",
"var order_increment_id":"Order #",
"var this.getUrl($store, 'customer/account/')":"Customer Account URL"
} @-->

{{template config_path="design/email/header_template"}}

<table>
    <tr class="email-intro">
        <td>
            <p class="greeting">{{trans "Hello %customer_name," customer_name=$customer_name}}</p>
            <p>
                {{trans "Your order #%order_id has been processed."
                    order_id=$order_increment_id}}
            </p>
        </td>
    </tr>
</table>

{{template config_path="design/email/footer_template"}}
```

**Template syntax reference:**
- `{{trans "text"}}` — translatable string
- `{{trans "text %1" param=$var}}` — translatable with positional params
- `{{trans "text %name" name=$var}}` — translatable with named params
- `{{var variable_name}}` — output a variable
- `{{var order.getIncrementId()}}` — call method on object variable
- `{{template config_path="..."}}` — include another template
- `{{layout handle="..."}}` — include a layout handle
- `{{if condition}}...{{/if}}` — conditional
- `{{depend variable}}...{{/depend}}` — show block if variable is truthy
- `<!--@subject ... @-->` — email subject line (required)
- `<!--@vars {...} @-->` — variable declarations for admin preview

### 4.3 config.xml — Default Template and Sender

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <{section_id}>
            <email>
                <enabled>1</enabled>
                <{template_field_id}>{template_id}</{template_field_id}>
                <sender>general</sender>
            </email>
        </{section_id}>
    </default>
</config>
```

### 4.4 system.xml — Admin-Configurable Template Selection

```xml
<group id="email" translate="label" sortOrder="30"
       showInDefault="1" showInWebsite="1" showInStore="1">
    <label>Email Notifications</label>
    <field id="enabled" translate="label" type="select" sortOrder="10"
           showInDefault="1" showInWebsite="1" showInStore="1">
        <label>Enable Email Notifications</label>
        <source_model>Magento\Config\Model\Config\Source\Yesno</source_model>
    </field>
    <field id="{template_field_id}" translate="label" type="select" sortOrder="20"
           showInDefault="1" showInWebsite="1" showInStore="1">
        <label>{Template Label}</label>
        <source_model>Magento\Config\Model\Config\Source\Email\Template</source_model>
        <depends>
            <field id="enabled">1</field>
        </depends>
    </field>
    <field id="sender" translate="label" type="select" sortOrder="30"
           showInDefault="1" showInWebsite="1" showInStore="1">
        <label>Email Sender</label>
        <source_model>Magento\Config\Model\Config\Source\Email\Identity</source_model>
        <depends>
            <field id="enabled">1</field>
        </depends>
    </field>
</group>
```

The `Email\Template` source model automatically shows the registered template plus any admin-created overrides.

### 4.5 Email Sender Service — `Service/Email/{Purpose}Sender.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Service\Email;

use Magento\Framework\App\Config\ScopeConfigInterface;
use Magento\Framework\Mail\Template\TransportBuilder;
use Magento\Store\Model\ScopeInterface;
use Magento\Store\Model\StoreManagerInterface;
use Psr\Log\LoggerInterface;

final class {Purpose}Sender
{
    private const XML_PATH_ENABLED = '{section_id}/email/enabled';
    private const XML_PATH_TEMPLATE = '{section_id}/email/{template_field_id}';
    private const XML_PATH_SENDER = '{section_id}/email/sender';

    public function __construct(
        private readonly TransportBuilder $transportBuilder,
        private readonly ScopeConfigInterface $scopeConfig,
        private readonly StoreManagerInterface $storeManager,
        private readonly LoggerInterface $logger
    ) {
    }

    public function send(string $recipientEmail, string $recipientName, array $templateVars, ?int $storeId = null): void
    {
        $storeId = $storeId ?? (int) $this->storeManager->getStore()->getId();

        if (!$this->isEnabled($storeId)) {
            return;
        }

        try {
            $transport = $this->transportBuilder
                ->setTemplateIdentifier($this->getTemplateId($storeId))
                ->setTemplateOptions([
                    'area' => \Magento\Framework\App\Area::AREA_FRONTEND,
                    'store' => $storeId,
                ])
                ->setTemplateVars($templateVars)
                ->setFromByScope($this->getSender($storeId), $storeId)
                ->addTo($recipientEmail, $recipientName)
                ->getTransport();

            $transport->sendMessage();
        } catch (\Throwable $e) {
            $this->logger->error('Failed to send email: ' . $e->getMessage(), [
                'exception' => $e,
                'recipient' => $recipientEmail,
            ]);
        }
    }

    private function isEnabled(int $storeId): bool
    {
        return $this->scopeConfig->isSetFlag(
            self::XML_PATH_ENABLED,
            ScopeInterface::SCOPE_STORE,
            $storeId
        );
    }

    private function getTemplateId(int $storeId): string
    {
        return (string) $this->scopeConfig->getValue(
            self::XML_PATH_TEMPLATE,
            ScopeInterface::SCOPE_STORE,
            $storeId
        );
    }

    private function getSender(int $storeId): string
    {
        return (string) $this->scopeConfig->getValue(
            self::XML_PATH_SENDER,
            ScopeInterface::SCOPE_STORE,
            $storeId
        );
    }
}
```

## 5. Generation Rules

Follow this sequence when generating email template code:

1. **Verify the module exists** — check `registration.php`.

2. **Create `etc/email_templates.xml`** — register the template ID.

3. **Create the HTML template file** — `view/{area}/email/{template_name}.html`.

4. **Create or update `etc/config.xml`** — set default template ID and sender.

5. **If admin-configurable:** create or update `etc/adminhtml/system.xml` with template selection field. For detailed system.xml patterns, see `/m2-system-config`.

6. **Create the sender service** — `Service/Email/{Purpose}Sender.php`.

7. **Remind the user** to run post-generation commands.

## 6. Anti-Patterns

**Using `TransportBuilder` directly in controllers/observers.**
Extract email sending into a dedicated sender service class. This makes the logic reusable and testable.

**Hardcoding template IDs.**
Always use config paths so admins can override templates from the admin panel.

**Missing `<!--@subject @-->` directive.**
Every email template MUST have a subject line directive. Without it, emails are sent with an empty subject.

**Missing `<!--@vars @-->` directive.**
Without the vars declaration, the admin template editor cannot show available variables for customization.

**Not checking if email is enabled before sending.**
Always check the enabled flag. This lets admins disable emails without removing code.

**Sending emails inside database transactions.**
Email sending should happen AFTER the transaction commits. Use an `after` plugin on the repository save or a message queue for decoupling.

**Not handling TransportBuilder exceptions.**
Always wrap in try/catch and log errors. Failed emails should not crash the main operation.

**Inline CSS requirement:** Magento's email system does not inline CSS automatically. All styles in email templates must be written as inline `style=""` attributes on HTML elements. External stylesheets and `<style>` blocks are stripped by most email clients.

**Email preview:** To preview emails during development, use the Magento admin: Marketing > Communications > Email Templates > "Preview Template" button. Alternatively, temporarily send to a test address using the TransportBuilder pattern.

**Attachments:** Magento's core TransportBuilder does not natively support attachments. To add attachments, you must extend the transport builder or use a third-party module. This is a known Magento limitation.

## 7. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: layout XML / templates / config changes.

To verify: check the template appears in **Marketing > Email Templates > Add New Template > Load Template** dropdown. The admin-configurable field should appear under **Stores > Configuration > {Section} > Email Notifications**.
