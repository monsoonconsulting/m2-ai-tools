---
name: m2-controller
description: >
  Create and refactor Magento 2 controllers, configure routes, handle AJAX/JSON requests,
  and modernize deprecated controller patterns.
  Use this skill whenever the user asks to create a controller, add a route, build an AJAX
  endpoint, fix a deprecated controller, or handle form submissions on the frontend.
  Trigger on: "create controller", "add controller", "frontend controller", "AJAX controller",
  "JSON controller", "controller refactor", "fix controller", "deprecated controller",
  "add route", "routing", "routes.xml", "HttpGetActionInterface", "HttpPostActionInterface",
  "CSRF", "CsrfAwareActionInterface", "result page", "result json", "result redirect",
  "form submission", "POST handler", "controller action", "frontName", "noroute", "404",
  "form key", "validate form key", "middleware", "request handler".
---

# Magento 2 Controller & Routing

You are a Magento 2 controller specialist. Create frontend and AJAX controllers, configure routes, and refactor deprecated controller patterns under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Creating frontend storefront controllers (GET pages, POST form handlers)
- Creating AJAX/JSON endpoints (frontend or admin)
- Adding or modifying `routes.xml` configuration
- Refactoring deprecated controller patterns (missing HTTP verb interface, ObjectManager usage, etc.)
- Implementing CSRF-exempt controllers (webhooks, external callbacks)
- Creating forward or redirect controllers

**Use `/m2-admin-ui` instead when:**
- Building admin CRUD pages (grid + form) — the admin controllers are part of that workflow

**Use `/m2-api-builder` instead when:**
- Exposing data via REST or GraphQL APIs — use service contracts and `webapi.xml`

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Controller purpose** — what the controller does (display page, handle form, return JSON, etc.)
- **Area** — `frontend` (default) or `adminhtml`
- **HTTP method** — GET or POST
- **Result type** — page, json, redirect, forward, or raw

**Optional (use defaults if not specified):**
- **Route frontName** — default: derive from module name (lowercase, no separators)
- **Route ID** — default: `{vendor}_{module}` (lowercase with underscore)
- **Controller path** — default: derive from purpose (e.g., `Controller/Index/Index`)
- **CSRF exempt** — default: no (yes only for webhooks/external callbacks)

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Route frontName | lowercase, no separators | `customshipping` |
| Route ID | `{vendor}_{module}` (lowercase) | `acme_customshipping` |
| Controller namespace | `Controller\{Folder}\{Action}` | `Controller\Quote\Submit` |
| URL pattern | `{frontName}/{folder}/{action}` | `customshipping/quote/submit` |
| Layout handle | `{route_id}_{folder}_{action}` (all lowercase) | `acme_customshipping_quote_submit` |
| Default controller | `Controller/Index/Index.php` | URL: `{frontName}` or `{frontName}/index/index` |
| Default action | `Index.php` in the folder | URL: `{frontName}/{folder}` resolves to `Index` |

**URL Resolution:** Magento resolves URLs as `{frontName}/{controllerFolder}/{actionClass}`. Each segment maps to the directory/class structure under `Controller/`. If a segment is omitted, it defaults to `Index`.

## 4. HTTP Verb Interfaces

Every controller **must** implement at least one HTTP verb interface. Without it, Magento rejects the request.

| Interface | HTTP Method | Use When |
|-----------|-------------|----------|
| `HttpGetActionInterface` | GET | Displaying pages, returning data, AJAX GET |
| `HttpPostActionInterface` | POST | Form submissions, AJAX POST, data mutations |
| `HttpPutActionInterface` | PUT | REST-style updates (rare for controllers) |
| `HttpDeleteActionInterface` | DELETE | REST-style deletes (rare for controllers) |
| `HttpGetActionInterface` + `HttpPostActionInterface` | GET and POST | Controller that handles both (e.g., form display + submission in one class) |

All interfaces are in the `Magento\Framework\App\Action` namespace.

## 5. Result Types

| Result Type | Factory Class | Return Type | Use When |
|-------------|--------------|-------------|----------|
| Page | `Magento\Framework\View\Result\PageFactory` | `Magento\Framework\View\Result\Page` | Rendering a full page with layout |
| JSON | `Magento\Framework\Controller\Result\JsonFactory` | `Magento\Framework\Controller\Result\Json` | AJAX responses, API-like endpoints |
| Redirect | `Magento\Framework\Controller\Result\RedirectFactory` | `Magento\Framework\Controller\Result\Redirect` | After form submission, login redirects |
| Forward | `Magento\Framework\Controller\ResultFactory` | `Magento\Framework\Controller\Result\Forward` | Internal dispatch to another action (no URL change) |
| Raw | `Magento\Framework\Controller\Result\RawFactory` | `Magento\Framework\Controller\Result\Raw` | Custom content-type responses (XML, CSV, plain text) |

**Note:** `Redirect` is also available via `$this->resultRedirectFactory` inherited from `Action` — no need to inject separately for frontend controllers extending `Magento\Framework\App\Action\Action`.

## 6. Controller Templates

For full PHP controller templates, see `.claude/skills/m2-controller/references/controller-templates.md`.

Templates provided:
1. Frontend GET Page Controller
2. Frontend POST Form Handler + Redirect
3. Frontend AJAX GET JSON Controller
4. Frontend AJAX POST JSON Controller
5. CSRF-Exempt POST Controller (webhooks)
6. Forward Controller

## 7. Route Configuration

### 7.1 Frontend `etc/frontend/routes.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:App/etc/routes.xsd">
    <router id="standard">
        <route id="{route_id}" frontName="{frontname}">
            <module name="{Vendor}_{ModuleName}"/>
        </route>
    </router>
</config>
```

### 7.2 Admin `etc/adminhtml/routes.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:App/etc/routes.xsd">
    <router id="admin">
        <route id="{route_id}" frontName="{frontname}">
            <module name="{Vendor}_{ModuleName}"/>
        </route>
    </router>
</config>
```

### 7.3 Route Override

To add controllers to an existing route (e.g., extend a core module's route):

```xml
<route id="catalog" frontName="catalog">
    <module name="{Vendor}_{ModuleName}" before="Magento_Catalog"/>
</route>
```

- `before="Magento_Catalog"` — your module's controllers are checked first. If a matching action exists, it handles the request; otherwise, Magento falls through to the original module.
- `after="Magento_Catalog"` — your module's controllers are checked only if the original module has no matching action.

**Use `before` when:** you want to override an existing controller action.
**Use `after` when:** you want to add new actions to an existing route without risk of overriding.

## 8. CSRF and Security

### 8.1 Frontend CSRF (Form Key Validation)

Magento 2.3+ enforces CSRF validation on all POST requests by default. Frontend controllers extending `Magento\Framework\App\Action\Action` get automatic form key validation.

**In templates,** include the form key in every POST form:

```html
<form action="<?= $escaper->escapeUrl($block->getUrl('route/folder/action')) ?>" method="post">
    <?= $block->getBlockHtml('formkey') ?>
    <!-- form fields -->
</form>
```

**In AJAX requests,** include the form key:

```javascript
fetch(url, {
    method: 'POST',
    headers: {'X-Requested-With': 'XMLHttpRequest'},
    body: JSON.stringify({form_key: window.FORM_KEY, ...data})
});
```

### 8.2 CSRF-Exempt Controllers (Webhooks/Callbacks)

For controllers that receive POST requests from external systems (payment gateways, webhooks), implement `CsrfAwareActionInterface`:

```php
use Magento\Framework\App\CsrfAwareActionInterface;
use Magento\Framework\App\Request\InvalidRequestException;
use Magento\Framework\App\RequestInterface;

class Webhook extends Action implements HttpPostActionInterface, CsrfAwareActionInterface
{
    public function createCsrfValidationException(RequestInterface $request): ?InvalidRequestException
    {
        return null;
    }

    public function validateForCsrf(RequestInterface $request): ?bool
    {
        // Implement your own validation (e.g., signature verification)
        return true;
    }
}
```

**Important:** Only use `CsrfAwareActionInterface` when the POST originates from an external system that cannot provide a Magento form key. Always implement alternative validation (HMAC signature, API key, IP whitelist) in `validateForCsrf()`.

### 8.3 Admin CSRF

Admin controllers extending `Magento\Backend\App\Action` get CSRF protection automatically via the admin session and secret key in URLs. No additional configuration is needed.

## 9. Generation Rules

Follow this sequence when generating controller code:

1. **Verify the module exists** — check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct user to run `/m2-module`.

2. **Check or create `routes.xml`** — check `etc/{area}/routes.xml`. If it exists with the needed route, skip. If the file exists but the route is missing, add the route inside the existing `<router>` element. If the file doesn't exist, create it.

3. **Create the controller class** — place it at `Controller/{Folder}/{Action}.php`. Follow the appropriate template from `references/controller-templates.md` based on the HTTP method and result type.

4. **Create layout XML if page result** — for controllers returning a Page result, create `view/{area}/layout/{route_id}_{folder}_{action}.xml` (all lowercase). The layout file loads the template:

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceContainer name="content">
            <block class="Magento\Framework\View\Element\Template"
                   name="{vendor}_{module}_{block_name}"
                   template="{Vendor}_{ModuleName}::{template_name}.phtml"/>
        </referenceContainer>
    </body>
</page>
```

Prefer ViewModels over Block classes for passing data to templates — see `/m2-frontend-layout` for ViewModel patterns, layout XML operations, and template escaping rules.

5. **Create template if needed** — `view/{area}/templates/{template_name}.phtml` with a minimal starter template.

6. **Remind the user** to run post-generation commands (see section 12).

**Merge logic for existing XML files:**
- `routes.xml` — if the route already exists, skip. Otherwise append inside `<router>`.
- Layout XML — create new files only; never overwrite existing layouts without confirmation.

## 10. Refactoring Deprecated Patterns

When refactoring an existing controller, check for and fix these issues:

### 10.1 Missing HTTP Verb Interface

**Before (deprecated):**
```php
class View extends Action
{
    public function execute() { ... }
}
```

**After:**
```php
class View extends Action implements HttpGetActionInterface
{
    public function execute(): Page { ... }
}
```

Add the appropriate `Http*ActionInterface` based on what HTTP method the controller handles.

### 10.2 Raw Response Instead of Result Objects

**Before (deprecated):**
```php
$this->getResponse()->setBody(json_encode($data));
$this->getResponse()->setHeader('Content-Type', 'application/json');
```

**After:**
```php
$result = $this->jsonFactory->create();
return $result->setData($data);
```

Always return a Result object from `execute()`.

### 10.3 Business Logic in Controller

**Before (anti-pattern):**
```php
public function execute()
{
    $product = $this->productRepository->getById($id);
    $product->setPrice($newPrice);
    $product->setSpecialPrice($newPrice * 0.9);
    $this->productRepository->save($product);
    // ... 50 more lines of logic
}
```

**After:**
```php
public function execute(): Redirect
{
    $this->priceUpdateService->execute($id, $newPrice);
    // controller only handles HTTP concerns
}
```

Extract business logic into a service class. Controllers should only: parse request, call service, return result.

### 10.4 Using `_forward()` and `_redirect()` Methods

**Before (deprecated):**
```php
$this->_forward('edit');
$this->_redirect('*/*/index');
```

**After:**
```php
// Forward:
$forward = $this->resultFactory->create(ResultFactory::TYPE_FORWARD);
return $forward->forward('edit');

// Redirect:
return $this->resultRedirectFactory->create()->setPath('*/*/index');
```

### 10.5 ObjectManager Usage

**Before (anti-pattern):**
```php
$logger = \Magento\Framework\App\ObjectManager::getInstance()
    ->get(\Psr\Log\LoggerInterface::class);
```

**After:**
```php
public function __construct(
    Context $context,
    private readonly LoggerInterface $logger
) {
    parent::__construct($context);
}
```

All dependencies must be constructor-injected.

### 10.6 Missing `declare(strict_types=1)`

Add to all controller class files. Not needed in `registration.php`.

### 10.7 No `final` on Controllers

Do NOT use `final` on controller classes — Magento's interceptor system needs to generate proxy subclasses. See `_shared/conventions.md` for the full rule.

### 10.8 Missing Error Response Handling

Controllers should return appropriate HTTP status codes:

```php
// 404 Not Found — entity doesn't exist
$forward = $this->resultFactory->create(ResultFactory::TYPE_FORWARD);
return $forward->forward('noroute');

// 400 Bad Request — invalid input (JSON response)
$result = $this->jsonFactory->create();
return $result->setHttpResponseCode(400)->setData(['error' => true, 'message' => 'Invalid input']);

// 500 errors — let exceptions propagate to Magento's error handler
// Do NOT catch and return 200 with error messages
```

Use 4xx for client errors (bad input, not found, unauthorized) and let Magento handle 5xx for server errors. Never return HTTP 200 with an error payload — it breaks API consumers and monitoring.

## 11. Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Missing HTTP verb interface | Magento rejects requests or logs warnings | Add `HttpGetActionInterface` or `HttpPostActionInterface` |
| Business logic in controller | Untestable, violates single responsibility | Extract to service class |
| `ObjectManager::getInstance()` | Hidden dependencies, untestable | Constructor injection |
| No Result object returned | Bypasses response handling, breaks FPC | Return Page/Json/Redirect/Forward |
| Missing form key validation on POST | CSRF vulnerability | Use Magento's built-in form key (included automatically for `Action` subclasses) |
| Hardcoded URLs | Breaks with custom base URLs and rewrites | Use `$this->_url->getUrl()` or `$this->resultRedirectFactory->create()->setPath()` |
| Too many constructor dependencies (>5) | Controller doing too much | Extract logic into service classes |
| `echo` or `die()` in controller | Breaks response pipeline | Return proper Result object |
| Missing return type on `execute()` | Inconsistent, harder to debug | Add return type declaration |

## 12. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: layout XML / templates / config changes, new module enable.

**Verification:** Access the controller URL in the browser:
- Frontend: `https://{base_url}/{frontName}/{folder}/{action}`
- Admin: `https://{base_url}/admin/{frontName}/{folder}/{action}`

If the page returns a 404, check:
1. `routes.xml` has the correct frontName and router ID
2. Controller file is in the correct namespace/directory
3. Controller implements the correct HTTP verb interface
4. Cache is flushed
