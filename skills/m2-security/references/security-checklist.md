# Magento 2 Security Audit Checklist

Use this checklist when reviewing custom module code. Each item should pass before code is merged.

## Input Validation

- [ ] All request parameters are type-cast (`(int)`, `(string)`, `(bool)`, `(float)`)
- [ ] String inputs have length limits enforced
- [ ] Email/URL inputs are validated with `filter_var()`
- [ ] Enum-like inputs use allow-lists (`in_array($value, $allowed, true)`)
- [ ] File upload extensions are restricted via allow-list
- [ ] No direct access to `$_GET`, `$_POST`, `$_REQUEST`, `$_FILES`

## Output Escaping (XSS)

- [ ] All phtml templates declare `$escaper` variable
- [ ] All dynamic output uses `$escaper->escapeHtml()` (default)
- [ ] HTML attributes use `$escaper->escapeHtmlAttr()`
- [ ] URLs use `$escaper->escapeUrl()`
- [ ] JavaScript values use `$escaper->escapeJs()`
- [ ] CSS values use `$escaper->escapeCss()`
- [ ] No `echo`/`<?= ?>` without escaping for user-supplied data
- [ ] `__()` translation strings do not contain unescaped HTML

## SQL Injection

- [ ] All database queries use parameterized placeholders (`?` or `:name`)
- [ ] No string concatenation in `WHERE` clauses
- [ ] Collection filters use `addFieldToFilter()` with condition arrays
- [ ] Raw SQL queries (if any) use bound parameters
- [ ] `Zend_Db_Expr` usage reviewed for user input injection

## CSRF Protection

- [ ] Frontend POST forms include `form_key` hidden field
- [ ] Frontend POST controllers validate form key
- [ ] Admin controllers extend `Magento\Backend\App\Action`
- [ ] Webhook/callback controllers implement `CsrfAwareActionInterface` with proper validation
- [ ] No CSRF exemptions without alternative authentication (signature, token)

## Access Control (ACL)

- [ ] `etc/acl.xml` defines granular resources (view/save/delete)
- [ ] Every admin controller has `const ADMIN_RESOURCE` defined
- [ ] Every webapi.xml route has `<resource>` element
- [ ] System config sections have `<resource>` element
- [ ] Menu items have `resource` attribute
- [ ] `anonymous` API access is intentional and documented
- [ ] `self` API access validates customer owns the resource

## Data Protection

- [ ] API keys and secrets use `type="obscure"` + `Encrypted` backend model in system.xml
- [ ] Database-stored secrets use `EncryptorInterface`
- [ ] No sensitive data in log files (passwords, tokens, PII)
- [ ] No sensitive data in error messages shown to users
- [ ] `env.php` is excluded from git (`.gitignore`)

## File System

- [ ] File uploads save to `pub/media/` only
- [ ] Upload extensions use allow-list (not deny-list)
- [ ] `setAllowRenameFiles(true)` prevents overwrites
- [ ] No file operations in `app/`, `vendor/`, or project root
- [ ] Directory traversal prevented (no `../` in paths from user input)

## Dependency Injection

- [ ] No `ObjectManager::getInstance()` anywhere
- [ ] All dependencies injected via constructor
- [ ] No `@escapeNotVerified` annotations
- [ ] No deprecated registry usage (`Magento\Framework\Registry`)

## HTTP Security

- [ ] Admin controllers use correct HTTP verb interface (`HttpGetActionInterface`, `HttpPostActionInterface`)
- [ ] State-changing operations require POST/PUT/DELETE (never GET)
- [ ] Redirects use `resultRedirectFactory` (no `header('Location: ...')`)
- [ ] No hardcoded URLs (use `UrlInterface` or `$block->getUrl()`)

## GraphQL Security

- [ ] Resolvers validate input arguments before processing
- [ ] GraphQL-specific exceptions used (`GraphQlInputException`, `GraphQlAuthorizationException`)
- [ ] No full entity objects returned (use `->getData()` for arrays)
- [ ] Authentication checked via `$context->getExtensionAttributes()->getIsCustomer()`
