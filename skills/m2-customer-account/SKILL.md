---
name: m2-customer-account
description: >
  Generate Magento 2 customer "My Account" sections including customer_account layout
  handle, sidebar navigation links, authenticated controllers, customer area ViewModels,
  and account dashboard tabs. Use this skill when adding custom pages or sections to
  the customer account area.
  Trigger on: "my account", "customer account", "customer dashboard", "customer section",
  "account page", "customer area", "customer tab", "customer navigation", "sidebar link",
  "customer controller", "customer session", "logged in page", "customer_account",
  "account sidebar", "customer profile", "customer authenticated",
  "my orders", "authenticated page", "customer route".
---

# Magento 2 Customer Account Sections

You are a Magento 2 customer account specialist. Generate customer "My Account" pages, navigation links, controllers, and ViewModels under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Adding a new page/section to the customer "My Account" area
- Adding sidebar navigation links to the customer account
- Creating authenticated customer controllers
- Building ViewModels that use customer session data

**Use `/m2-controller` instead when:**
- Creating general frontend controllers (non-customer area)

**Use `/m2-frontend-layout` instead when:**
- Working with general frontend layout (non-customer area)

**Use `/m2-customer-sections` instead when:**
- Displaying client-side private content on FPC-cached pages (e.g., reward points, loyalty tier)

**Use `/m2-eav-attributes` instead when:**
- Adding custom fields to the customer entity (not UI pages)

## 2. Gather Requirements

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Page title** — what appears in the account section (e.g., "My Rewards")
- **Page purpose** — what the page displays or allows

**Optional:**
- **Sidebar link** — add to customer account navigation? (default: yes)
- **Sort order** — position in sidebar (default: after existing links)
- **Controller path** — default: derived from page purpose

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Route frontName | lowercase | `rewards` |
| Layout handle | `{route_id}_{folder}_{action}` | `rewards_index_index` |
| Customer layout handle | `customer_account` (shared) | Applied to all account pages |
| Controller namespace | `Controller\{Section}\{Action}` | `Controller\Rewards\Index` |
| ViewModel | `ViewModel\Customer\{Name}` | `ViewModel\Customer\Rewards` |

## 4. Templates

### 4.1 Layout XML — Add Sidebar Navigation Link

File: `view/frontend/layout/customer_account.xml`

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceBlock name="customer_account_navigation">
            <block class="Magento\Customer\Block\Account\SortLinkInterface"
                   name="{vendor}_{module}_{section}_link"
                   after="-">
                <arguments>
                    <argument name="label" xsi:type="string" translate="true">{Page Title}</argument>
                    <argument name="path" xsi:type="string">{frontname}/{folder}/{action}</argument>
                    <argument name="sortOrder" xsi:type="number">250</argument>
                </arguments>
            </block>
        </referenceBlock>
    </body>
</page>
```

The `customer_account` layout handle is applied to ALL customer account pages. Adding a block here makes the link appear in the sidebar navigation on every account page.

### 4.2 Layout XML — Custom Account Page

File: `view/frontend/layout/{route_id}_{folder}_{action}.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd"
      layout="2columns-left">
    <update handle="customer_account"/>
    <head>
        <title>{Page Title}</title>
    </head>
    <body>
        <referenceContainer name="content">
            <block class="Magento\Framework\View\Element\Template"
                   name="{vendor}_{module}_{block_name}"
                   template="{Vendor}_{ModuleName}::{section}/{template}.phtml">
                <arguments>
                    <argument name="view_model" xsi:type="object">{Vendor}\{ModuleName}\ViewModel\Customer\{ViewModelName}</argument>
                </arguments>
            </block>
        </referenceContainer>
    </body>
</page>
```

**Key elements:**
- `layout="2columns-left"` — matches the standard My Account layout (sidebar + content)
- `<update handle="customer_account"/>` — includes the sidebar navigation and account layout
- The `<head><title>` sets the page title

### 4.3 Authenticated Controller

File: `Controller/{Section}/Index.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Section};

use Magento\Customer\Controller\AbstractAccount;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\View\Result\Page;
use Magento\Framework\View\Result\PageFactory;

class Index extends AbstractAccount implements HttpGetActionInterface
{
    public function __construct(
        \Magento\Framework\App\Action\Context $context,
        private readonly PageFactory $resultPageFactory
    ) {
        parent::__construct($context);
    }

    public function execute(): Page
    {
        $resultPage = $this->resultPageFactory->create();
        $resultPage->getConfig()->getTitle()->set(__('{Page Title}'));
        return $resultPage;
    }
}
```

**`AbstractAccount`** provides automatic authentication checking — unauthenticated users are redirected to the login page. This is the standard base class for all customer account controllers.

### 4.4 Customer ViewModel

File: `ViewModel/Customer/{Name}.php`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\ViewModel\Customer;

use Magento\Customer\Model\Session as CustomerSession;
use Magento\Framework\View\Element\Block\ArgumentInterface;

final class {Name} implements ArgumentInterface
{
    public function __construct(
        private readonly CustomerSession $customerSession
    ) {
    }

    public function getCustomerId(): ?int
    {
        return $this->customerSession->isLoggedIn()
            ? (int) $this->customerSession->getCustomerId()
            : null;
    }

    public function getCustomerName(): string
    {
        $customer = $this->customerSession->getCustomer();
        return $customer->getName() ?? '';
    }
}
```

**Customer session patterns:**
- `$this->customerSession->isLoggedIn()` — check authentication
- `$this->customerSession->getCustomerId()` — get customer ID
- `$this->customerSession->getCustomer()` — get customer model (lazy-loaded)
- `$this->customerSession->getCustomerData()` — get customer data model (API interface)

### 4.5 phtml Template

File: `view/frontend/templates/{section}/{template}.phtml`

```php
<?php
// Standard file header — see _shared/conventions.md
declare(strict_types=1);

/**
 * @var \Magento\Framework\View\Element\Template $block
 * @var \Magento\Framework\Escaper $escaper
 * @var \{Vendor}\{ModuleName}\ViewModel\Customer\{Name} $viewModel
 */
$viewModel = $block->getData('view_model');
?>
<div class="block {vendor}-{module}-{section}">
    <div class="block-title">
        <strong><?= $escaper->escapeHtml(__('{Page Title}')) ?></strong>
    </div>
    <div class="block-content">
        <p><?= $escaper->escapeHtml(__('Welcome, %1', $viewModel->getCustomerName())) ?></p>
    </div>
</div>
```

### 4.6 Frontend routes.xml

File: `etc/frontend/routes.xml`

```xml
<?xml version="1.0"?>
<!-- Standard XML header — see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:App/etc/routes.xsd">
    <router id="standard">
        <route id="{route_id}" frontName="{frontname}">
            <module name="{Vendor}_{ModuleName}"/>
        </route>
    </router>
</config>
```

## 5. Customer Account Navigation — Sort Order Reference

Magento's default navigation link sort orders:

| Link | Sort Order |
|------|-----------|
| My Account (Dashboard) | 10 |
| My Orders | 40 |
| My Downloadable Products | 50 |
| My Wish List | 60 |
| Address Book | 70 |
| Account Information | 80 |
| Stored Payment Methods | 90 |
| My Product Reviews | 100 |
| Newsletter Subscriptions | 110 |

Use a sort order value between existing items to position your link, or use a high number (250+) to append at the end.

## 6. Generation Rules

1. **Verify the module exists** — check `registration.php`.
2. **Create `etc/frontend/routes.xml`** — register the frontend route.
3. **Create `view/frontend/layout/customer_account.xml`** — add sidebar navigation link.
4. **Create page layout XML** — `view/frontend/layout/{handle}.xml` with `<update handle="customer_account"/>`.
5. **Create the controller** — extending `AbstractAccount` for automatic auth check.
6. **Create the ViewModel** — with customer session dependency.
7. **Create the phtml template** — with proper escaping.
8. **Remind the user** to run post-generation commands.

## 7. Anti-Patterns

**Not extending `AbstractAccount`.**
Without `AbstractAccount`, unauthenticated users can access customer pages. Always extend it — it handles the login redirect automatically.

**Using `layout="1column"` for account pages.**
Customer account pages should use `layout="2columns-left"` to match the sidebar navigation pattern. Using a different layout breaks the visual consistency.

**Forgetting `<update handle="customer_account"/>`.**
Without this, the page won't include the sidebar navigation. The user sees the content but no account menu.

**Accessing customer data without session check.**
Always check `$customerSession->isLoggedIn()` before accessing customer data in ViewModels. Even with `AbstractAccount`, edge cases exist (e.g., session expiry mid-request).

**Putting customer-specific data in FPC.**
Customer account pages are not cached by Full Page Cache (they're behind authentication). However, if you add customer data to public pages, use private content (sections) instead.

## 8. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: layout XML / templates / config changes.

Test: Log in as a customer, navigate to My Account, and verify the new link appears in the sidebar and the page loads correctly.
