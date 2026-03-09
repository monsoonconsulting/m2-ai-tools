---
name: m2-security
description: >
  Review and audit Magento 2 code for security vulnerabilities including input
  validation, output escaping, SQL injection, CSRF protection, ACL patterns,
  file upload safety, and encrypted data handling. Use this skill as a security
  review/audit checklist for Magento 2 custom code.
  Trigger on: "security review", "security audit", "XSS", "SQL injection",
  "CSRF", "input validation", "output escaping", "ACL", "access control",
  "permission", "file upload security", "encryption", "EncryptorInterface",
  "secure code", "vulnerability", "OWASP", "sanitize", "form key",
  "admin permission", "role permission", "security check", "pen test",
  "code review", "security best practices", "pentest", "vulnerability scan".
---

# Magento 2 Security Review & Audit

You are a Magento 2 security specialist. Review custom code for security vulnerabilities, apply fixes, and ensure compliance with Magento security best practices.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

This is primarily a **review/audit skill** — it focuses on identifying and fixing security issues rather than generating new modules. For code generation, use the specialized skills which already embed security patterns.

## 1. Decision Tree

**Use this skill when:**
- Reviewing existing custom code for security vulnerabilities
- Implementing comprehensive ACL (access control) for a module
- Auditing file upload handling
- Checking input validation and output escaping
- Setting up encrypted data storage

**Cross-references (these skills already embed security patterns):**
- Output escaping in templates — see `/m2-frontend-layout` (escaping table)
- CSRF protection in controllers — see `/m2-controller` (CSRF section)
- Encrypted config fields — see `/m2-system-config` (obscure field type)
- API ACL resources — see `/m2-api-builder` (acl.xml section)
- Admin ACL — see `/m2-admin-ui` (acl.xml section)

## 2. Input Validation

### 2.1 Validate at System Boundaries

Validate all input from: HTTP requests, API calls, file uploads, admin config saves, cron job parameters.

```php
// Controller — validate request parameters
$entityId = (int) $this->getRequest()->getParam('entity_id');
if ($entityId <= 0) {
    throw new LocalizedException(__('Invalid entity ID.'));
}

// Validate string length
$title = (string) $this->getRequest()->getParam('title');
if (mb_strlen($title) > 255) {
    throw new LocalizedException(__('Title must not exceed 255 characters.'));
}

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    throw new LocalizedException(__('Invalid email address.'));
}
```

### 2.2 Type Casting

Always cast request parameters to expected types:
- `(int)` for IDs, quantities, page numbers
- `(string)` for text fields
- `(bool)` for flags
- `(float)` for prices, weights

### 2.3 Allow-Lists over Deny-Lists

```php
// Good — allow-list
$allowedStatuses = ['pending', 'processing', 'complete'];
if (!in_array($status, $allowedStatuses, true)) {
    throw new LocalizedException(__('Invalid status.'));
}

// Bad — deny-list (incomplete by definition)
$blockedStatuses = ['canceled', 'fraud'];
```

## 3. Output Escaping (XSS Prevention)

All output in phtml templates MUST use `$escaper` methods. For the complete escaping reference, see `/m2-frontend-layout` templates section.

| Method | Use For |
|--------|---------|
| `$escaper->escapeHtml($value)` | HTML content (default — use when unsure) |
| `$escaper->escapeHtmlAttr($value)` | HTML attribute values |
| `$escaper->escapeUrl($value)` | URLs in `href`/`src` attributes |
| `$escaper->escapeJs($value)` | Values embedded in JavaScript |
| `$escaper->escapeCss($value)` | Values embedded in CSS |

**Never output unescaped user data:**
```php
// WRONG — XSS vulnerability
<?= $block->getCustomerName() ?>

// CORRECT
<?= $escaper->escapeHtml($block->getCustomerName()) ?>
```

## 4. SQL Injection Prevention

### 4.1 Use Magento's Query Builder

```php
// CORRECT — parameterized query
$select = $connection->select()
    ->from('catalog_product_entity')
    ->where('entity_id = ?', $entityId);

// CORRECT — IN clause
$select->where('entity_id IN (?)', $ids);

// WRONG — string concatenation = SQL injection
$select->where('entity_id = ' . $entityId);  // NEVER DO THIS
```

### 4.2 Collection Filters

```php
// CORRECT — uses parameterized queries internally
$collection->addFieldToFilter('status', ['eq' => $status]);
$collection->addFieldToFilter('entity_id', ['in' => $ids]);

// CORRECT — LIKE with escaping
$collection->addFieldToFilter('title', ['like' => '%' . $searchTerm . '%']);
// Magento escapes the value internally
```

### 4.3 Raw SQL (Last Resort)

If you must use raw SQL, always use bound parameters:
```php
$connection->query('SELECT * FROM table WHERE id = :id', ['id' => $entityId]);
```

## 5. CSRF Protection

For comprehensive controller CSRF patterns, see `/m2-controller`.

**Frontend forms:** Always include the form key:
```html
<input name="form_key" type="hidden" value="<?= $escaper->escapeHtmlAttr($block->getFormKey()) ?>"/>
```

**Admin controllers:** CSRF protection is automatic via `Magento\Backend\App\Action` session validation.

**Webhooks/external callbacks:** Implement `CsrfAwareActionInterface`:
```php
use Magento\Framework\App\CsrfAwareActionInterface;
use Magento\Framework\App\Request\InvalidRequestException;
use Magento\Framework\App\RequestInterface;

final class Webhook extends Action implements CsrfAwareActionInterface
{
    public function createCsrfValidationException(RequestInterface $request): ?InvalidRequestException
    {
        return null;
    }

    public function validateForCsrf(RequestInterface $request): ?bool
    {
        // Validate webhook signature instead
        return $this->isValidSignature($request);
    }
}
```

## 6. ACL (Access Control) — Comprehensive Reference

This skill owns the comprehensive ACL topic. Other skills (`/m2-admin-ui`, `/m2-api-builder`) include minimal ACL examples.

### 6.1 acl.xml Structure

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:Acl/etc/acl.xsd">
    <acl>
        <resources>
            <resource id="Magento_Backend::admin">
                <resource id="{Vendor}_{ModuleName}::config" title="{ModuleName}" sortOrder="100">
                    <resource id="{Vendor}_{ModuleName}::{entity_snake}" title="Manage {Entity}" sortOrder="10">
                        <resource id="{Vendor}_{ModuleName}::{entity_snake}_view" title="View" sortOrder="10"/>
                        <resource id="{Vendor}_{ModuleName}::{entity_snake}_save" title="Save" sortOrder="20"/>
                        <resource id="{Vendor}_{ModuleName}::{entity_snake}_delete" title="Delete" sortOrder="30"/>
                    </resource>
                </resource>
            </resource>
        </resources>
    </acl>
</config>
```

### 6.2 ACL in Admin Controllers

```php
final class Index extends \Magento\Backend\App\Action
{
    const ADMIN_RESOURCE = '{Vendor}_{ModuleName}::{entity_snake}_view';
}
```

### 6.3 ACL in webapi.xml

```xml
<!-- Standard XML header — see _shared/conventions.md -->
<route url="/V1/custom/entity/:id" method="GET">
    <service class="..." method="getById"/>
    <resources>
        <resource ref="{Vendor}_{ModuleName}::{entity_snake}_view"/>
    </resources>
</route>
```

### 6.4 ACL Options for API Resources

| Resource | Access Level |
|----------|-------------|
| Custom ACL ID | Admin/integration token required |
| `self` | Customer accessing own data (customer token) |
| `anonymous` | Public — no authentication needed |

### 6.5 Programmatic ACL Check

```php
use Magento\Framework\AuthorizationInterface;

public function __construct(
    private readonly AuthorizationInterface $authorization
) {
}

public function canDelete(): bool
{
    return $this->authorization->isAllowed('{Vendor}_{ModuleName}::{entity_snake}_delete');
}
```

## 7. File Upload Safety

```php
use Magento\Framework\App\Filesystem\DirectoryList;
use Magento\MediaStorage\Model\File\UploaderFactory;

// Restrict allowed extensions
$uploader = $this->uploaderFactory->create(['fileId' => 'file_field']);
$uploader->setAllowedExtensions(['jpg', 'jpeg', 'png', 'pdf']);
$uploader->setAllowRenameFiles(true);
$uploader->setFilesDispersion(false);

// Save to media directory (never to code or root directories)
$mediaDir = $this->filesystem->getDirectoryRead(DirectoryList::MEDIA)->getAbsolutePath();
$result = $uploader->save($mediaDir . '{Vendor}/{ModuleName}/');
```

**Rules:**
- Always restrict file extensions with an allow-list
- Save uploads to `pub/media/` only — never to `app/`, `var/`, or project root
- Enable `setAllowRenameFiles(true)` to prevent overwrites
- Validate MIME types in addition to extensions for sensitive uploads

## 8. Encrypted Data Handling

```php
use Magento\Framework\Encryption\EncryptorInterface;

public function __construct(
    private readonly EncryptorInterface $encryptor
) {
}

// Encrypt before saving to database
$encrypted = $this->encryptor->encrypt($sensitiveValue);

// Decrypt when reading
$decrypted = $this->encryptor->decrypt($encrypted);
```

For system config encrypted fields, use `type="obscure"` + `Encrypted` backend model — see `/m2-system-config`.

For the full security audit checklist, see `.claude/skills/m2-security/references/security-checklist.md`.

## 9. CSP (Content Security Policy)

Magento 2.4+ enforces Content Security Policy. To whitelist external domains for scripts, styles, fonts, or images, add a `csp_whitelist.xml`:

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<csp_whitelist xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Csp:etc/csp_whitelist.xsd">
    <policies>
        <policy id="script-src">
            <values>
                <value id="example_cdn" type="host">https://cdn.example.com</value>
            </values>
        </policy>
        <policy id="style-src">
            <values>
                <value id="example_fonts" type="host">https://fonts.googleapis.com</value>
            </values>
        </policy>
    </policies>
</csp_whitelist>
```

Place in `etc/csp_whitelist.xml` within your module. Never use `'unsafe-inline'` or `'unsafe-eval'` — refactor code to avoid inline scripts/styles instead.

## 10. Anti-Patterns

**Disabling CSRF validation without replacement.**
Never implement `CsrfAwareActionInterface` with `return true` in `validateForCsrf` just to make things work. Always implement proper validation (form key, webhook signature, API token).

**Using `$_GET`, `$_POST`, `$_REQUEST` directly.**
Always use `$this->getRequest()->getParam()` or typed request classes. Direct superglobal access bypasses Magento's request validation.

**Storing secrets in plain text.**
API keys, passwords, and tokens must be encrypted. Use `EncryptorInterface` for database storage or `Encrypted` backend model for system config.

**Trusting client-side validation alone.**
Always re-validate on the server side. Client-side validation is for UX only.

**Over-permissive ACL.**
Use granular ACL resources (view/save/delete) instead of a single catch-all permission. This lets admins create restricted roles.

**Mass assignment protection:** Never pass raw request data directly to `$model->setData($request->getParams())`. Always whitelist allowed fields:
```php
$allowed = ['title', 'status', 'content'];
$data = array_intersect_key($request->getParams(), array_flip($allowed));
$model->setData($data);
```

## 11. Audit Workflow

When reviewing custom module code for security:

1. **Check controllers** — HTTP verb interface, CSRF protection, input validation
2. **Check templates** — all variables use `$escaper` methods
3. **Check SQL** — no string concatenation in queries, all parameterized
4. **Check ACL** — all admin controllers have `ADMIN_RESOURCE`, all API routes have `<resource>`
5. **Check config** — sensitive fields use `type="obscure"` + `Encrypted` backend
6. **Check file uploads** — extension allow-list, media directory only
7. **Check logging** — no sensitive data in log messages
8. **Check DI** — no `ObjectManager::getInstance()` calls
