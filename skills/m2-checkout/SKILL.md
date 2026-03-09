---
name: m2-checkout
description: >
  Generate Magento 2 checkout customization code including checkout_index_index.xml layout,
  ConfigProviderInterface for passing data to checkout JS, custom checkout steps with KnockoutJS,
  quote total collectors via sales.xml, and checkout event observers. Use this skill for
  customizing the checkout flow, adding checkout steps, or modifying totals.
  Trigger on: "checkout", "checkout step", "checkout_index_index", "ConfigProviderInterface",
  "checkout config", "quote total", "total collector", "sales.xml", "checkout layout",
  "checkout customization", "custom checkout", "add checkout step", "checkout JS",
  "KnockoutJS checkout", "checkout payment", "checkout shipping", "order total",
  "checkout plugin", "checkout observer", "onepage checkout".
---

# Magento 2 Checkout Customization

You are a Magento 2 checkout specialist. Generate checkout layout XML, config providers, custom checkout steps, quote total collectors, and checkout event observers under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Adding or rearranging components in `checkout_index_index.xml` (the checkout page layout)
- Creating a `ConfigProviderInterface` to pass PHP data to checkout JavaScript
- Adding a custom checkout step (KnockoutJS component registered with `step-navigator`)
- Implementing a quote total collector with `sales.xml` registration
- Observing checkout-specific events (order placement, cart updates, checkout success)

**Use `/m2-frontend-layout` instead when:**
- Working with general frontend layout changes outside the checkout page
- Adding blocks or templates to non-checkout pages (cart page uses `/m2-frontend-layout`)

**Use `/m2-plugin` instead when:**
- Modifying the behavior of an existing checkout method (e.g., changing shipping rate calculation)
- Intercepting core checkout service contract methods

**Use `/m2-customer-sections` instead when:**
- Building FPC-compatible private content for non-checkout pages (header mini-cart, wishlist count)

**Use `/m2-payment-method` instead when:**
- Building a complete payment gateway integration with authorize/capture/void commands

**Use `/m2-observer` instead when:**
- Observing non-checkout events or needing the full observer generation workflow

## 2. Gather Requirements

Before generating any files, collect the following from the user.

**Required (ask if not provided):**
- **Module name** -- `Vendor_ModuleName` where the checkout code will live
- **Customization type** -- one or more of: layout change, config provider, custom step, total collector, checkout observer

**Optional (use defaults if not specified):**
- **Checkout area** -- shipping step, payment step, order summary sidebar, or a new custom step
- **JS component needs** -- whether the customization requires a KnockoutJS component and HTML template
- **Dependencies** -- services the config provider or total collector needs injected

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Config provider class | `Model\Checkout\{Purpose}ConfigProvider` | `Model\Checkout\LoyaltyConfigProvider` |
| Config provider DI key | `{vendor}_{module}_{purpose}_config_provider` | `acme_loyalty_loyalty_config_provider` |
| Config JS key | `{vendor_module_key}` (snake_case, unique) | `acme_loyalty` |
| Checkout step code | lowercase hyphenated | `loyalty-verification` |
| Step JS component | `view/frontend/web/js/view/checkout/{step-name}.js` | `js/view/checkout/loyalty-verification.js` |
| Step HTML template | `view/frontend/web/template/checkout/{step-name}.html` | `template/checkout/loyalty-verification.html` |
| Total collector class | `Model\Total\{TotalName}` | `Model\Total\CustomFee` |
| Total code | snake_case | `custom_fee` |
| Layout file | `view/frontend/layout/checkout_index_index.xml` | Always this handle for checkout page |

## 4. Templates

### 4.1 checkout_index_index.xml -- Layout Customization

The checkout page uses a JS-driven layout tree defined via `<argument name="jsLayout">` on the `checkout.root` block. To add, move, or configure checkout UI components, nest `<item>` elements following the component hierarchy.

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<page xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" layout="checkout"
      xsi:noNamespaceSchemaLocation="urn:magento:framework:View/Layout/etc/page_configuration.xsd">
    <body>
        <referenceBlock name="checkout.root">
            <arguments>
                <argument name="jsLayout" xsi:type="array">
                    <item name="components" xsi:type="array">
                        <item name="checkout" xsi:type="array">
                            <item name="children" xsi:type="array">
                                <item name="steps" xsi:type="array">
                                    <item name="children" xsi:type="array">
                                        <item name="{custom-step}" xsi:type="array">
                                            <item name="component" xsi:type="string">{Vendor}_{ModuleName}/js/view/checkout/{step-name}</item>
                                            <item name="sortOrder" xsi:type="string">3</item>
                                            <item name="children" xsi:type="array">
                                                <!-- Child components here -->
                                            </item>
                                        </item>
                                    </item>
                                </item>
                            </item>
                        </item>
                    </item>
                </argument>
            </arguments>
        </referenceBlock>
    </body>
</page>
```

**Component hierarchy reference:** The jsLayout tree mirrors the checkout UI structure:
- `checkout` > `steps` > `shipping-step` / `billing-step` / `{custom-step}`
- `checkout` > `sidebar` > `summary` / `shipping-information`

To add a component under an existing step (e.g., a field under shipping):
```xml
<item name="shipping-step" xsi:type="array">
    <item name="children" xsi:type="array">
        <item name="shippingAddress" xsi:type="array">
            <item name="children" xsi:type="array">
                <item name="{custom-component}" xsi:type="array">
                    <item name="component" xsi:type="string">{Vendor}_{ModuleName}/js/view/checkout/{component-name}</item>
                    <item name="sortOrder" xsi:type="string">200</item>
                </item>
            </item>
        </item>
    </item>
</item>
```

### 4.2 ConfigProviderInterface -- Pass PHP Data to Checkout JS

Config providers make server-side data available to checkout JS via `window.checkoutConfig`.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Checkout;

use Magento\Checkout\Model\ConfigProviderInterface;

final class {Purpose}ConfigProvider implements ConfigProviderInterface
{
    public function __construct(
        // Inject dependencies: ScopeConfigInterface, Session, repositories, etc.
    ) {
    }

    /** @return array<string, mixed> */
    public function getConfig(): array
    {
        return [
            '{vendor_module_key}' => [
                'enabled' => true,
                'custom_setting' => 'value',
            ],
        ];
    }
}
```

Register in `etc/frontend/di.xml` (config providers are frontend-only):

```xml
<?xml version="1.0"?>
<!-- Standard XML header -- see _shared/conventions.md -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">
    <type name="Magento\Checkout\Model\CompositeConfigProvider">
        <arguments>
            <argument name="configProviders" xsi:type="array">
                <item name="{vendor}_{module}_{purpose}_config_provider" xsi:type="object">{Vendor}\{ModuleName}\Model\Checkout\{Purpose}ConfigProvider</item>
            </argument>
        </arguments>
    </type>
</config>
```

**Accessing in JS:** `window.checkoutConfig.{vendor_module_key}.custom_setting`

### 4.3 Custom Checkout Step (KnockoutJS)

A custom checkout step requires three files: layout XML (section 4.1), a JS component, and an HTML template.

**JS component** -- `view/frontend/web/js/view/checkout/{step-name}.js`

```javascript
// Standard file header -- see _shared/conventions.md
define([
    'ko',
    'uiComponent',
    'underscore',
    'Magento_Checkout/js/model/step-navigator'
], function (ko, Component, _, stepNavigator) {
    'use strict';

    return Component.extend({
        defaults: {
            template: '{Vendor}_{ModuleName}/checkout/{step-name}'
        },
        isVisible: ko.observable(true),
        initialize: function () {
            this._super();
            stepNavigator.registerStep(
                '{step-code}', null, '{Step Title}',
                this.isVisible, _.bind(this.navigate, this), this.sortOrder
            );
            return this;
        },
        navigate: function () { this.isVisible(true); },
        navigateToNextStep: function () { stepNavigator.next(); }
    });
});
```

**HTML template** -- `view/frontend/web/template/checkout/{step-name}.html`

```html
<!-- ko if: isVisible -->
<li id="{step-code}" data-bind="fadeVisible: isVisible">
    <div class="step-title" data-bind="i18n: '{Step Title}'" data-role="title"></div>
    <div id="{step-code}-content" class="step-content" data-role="content" role="tabpanel">
        <form data-bind="submit: navigateToNextStep" novalidate="novalidate">
            <div class="actions-toolbar">
                <div class="primary">
                    <button data-role="opc-continue" type="submit" class="button action continue primary">
                        <span><!-- ko i18n: 'Next'--><!-- /ko --></span>
                    </button>
                </div>
            </div>
        </form>
    </div>
</li>
<!-- /ko -->
```

**`registerStep` parameters:** step code (matches `<item name>` in layout), alias (`null` unless replacing a step), title, `isVisible` observable, navigate callback, sort order (shipping=1, payment=2; use 3+ for custom steps).

### 4.4 Quote Total Collector -- Custom Order Total

Total collectors calculate custom amounts (fees, discounts, surcharges) that appear in order totals.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Total;

use Magento\Quote\Api\Data\ShippingAssignmentInterface;
use Magento\Quote\Model\Quote;
use Magento\Quote\Model\Quote\Address\Total;
use Magento\Quote\Model\Quote\Address\Total\AbstractTotal;

final class {TotalName} extends AbstractTotal
{
    public function __construct()
    {
        $this->setCode('{total_code}');
    }

    public function collect(Quote $quote, ShippingAssignmentInterface $shippingAssignment, Total $total): self
    {
        parent::collect($quote, $shippingAssignment, $total);
        if (empty($shippingAssignment->getItems())) {
            return $this;
        }
        $amount = $this->calculateAmount($quote);
        $total->setTotalAmount($this->getCode(), $amount);
        $total->setBaseTotalAmount($this->getCode(), $amount);
        return $this;
    }

    public function fetch(Quote $quote, Total $total): array
    {
        return ['code' => $this->getCode(), 'title' => __('Custom Fee'), 'value' => $total->getTotalAmount($this->getCode())];
    }

    public function getLabel(): \Magento\Framework\Phrase
    {
        return __('Custom Fee');
    }

    private function calculateAmount(Quote $quote): float
    {
        // Custom calculation logic
        return 0.0;
    }
}
```

Register in `etc/sales.xml`:

```xml
<?xml version="1.0"?>
<!--
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */
-->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Sales:etc/sales.xsd">
    <section name="quote">
        <group name="totals">
            <item name="{total_code}" instance="{Vendor}\{ModuleName}\Model\Total\{TotalName}" sort_order="500"/>
        </group>
    </section>
</config>
```

**Sort order reference:** `subtotal`=100, `discount`=300, `shipping`=350, `tax`=450, `grand_total`=550. Place custom fees between 400-540 (after shipping, before grand total).

**Displaying in checkout sidebar:** Create a JS component extending `Magento_Checkout/js/view/summary/abstract-total` and register it under `checkout > sidebar > summary > totals` in `checkout_index_index.xml`.

### 4.5 Common Checkout Events

| Event | When it fires | Available data |
|-------|---------------|----------------|
| `checkout_submit_all_after` | After order placement completes | `order`, `quote` |
| `sales_model_service_quote_submit_before` | Before quote converts to order | `order`, `quote` |
| `checkout_cart_add_product_complete` | After product added to cart | `product`, `request` |
| `checkout_onepage_controller_success_action` | Order success page renders | `order_ids` |
| `sales_order_place_after` | After order entity saved | `order` |
| `sales_order_payment_place_start` | Payment processing begins | `payment` |
| `checkout_allow_guest` | Guest checkout check | `quote`, `store`, `result` |
| `checkout_cart_update_items_after` | Cart items updated | `cart`, `info` |
| `checkout_cart_save_after` | Cart saved | `cart` |
| `checkout_submit_before` | Before checkout submit | `quote` |

For observer implementation details, class templates, and events.xml configuration, see `/m2-observer`.

### 4.6 Checkout JS Mixin -- Modify Existing Behavior

To modify existing checkout JS components without overriding them, use RequireJS mixins. See `/m2-frontend-layout` for the full RequireJS mixin reference.

`view/frontend/requirejs-config.js`:

```javascript
// Standard file header -- see _shared/conventions.md
var config = {
    config: {
        mixins: {
            'Magento_Checkout/js/view/shipping': {
                '{Vendor}_{ModuleName}/js/view/shipping-mixin': true
            }
        }
    }
};
```

Mixin file (`view/frontend/web/js/view/shipping-mixin.js`) returns a function that receives and extends the original component, using `this._super()` to call the original method.

## 5. Generation Rules

1. **Verify the module exists** -- check `app/code/{Vendor}/{ModuleName}/registration.php`. If missing, instruct the user to run `/m2-module`.

2. **Generate files by customization type:**
   - **Layout** -- create/merge `view/frontend/layout/checkout_index_index.xml`
   - **Config provider** -- create `Model/Checkout/{Purpose}ConfigProvider.php` + merge `etc/frontend/di.xml`
   - **Custom step** -- create/merge `checkout_index_index.xml` + JS component + HTML template
   - **Total collector** -- create `Model/Total/{TotalName}.php` + create/merge `etc/sales.xml`
   - **Observer** -- defer to `/m2-observer`

3. **Apply XML merge rules** from `_shared/conventions.md`. For existing files, merge into the existing root element -- never duplicate `<page>`, `<config>`, or `<section>` elements.

4. **Remind the user** to run post-generation commands (see section 7).

## 6. Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Overriding checkout JS directly | Breaks on Magento upgrades | Use RequireJS mixins (section 4.6) or layout XML |
| Heavy computation in ConfigProviders | `getConfig()` runs every checkout page load | Cache expensive results; never make uncached API calls |
| Missing `sales.xml` registration | Total collector silently does nothing | Always register in `etc/sales.xml` and verify in quote totals |
| Total sort order >= 550 | Fee excluded from grand total calculation | Use sort order below 550 (see section 4.4 reference) |
| Not checking empty items in `collect()` | Total applied to wrong address in multi-shipping | Return early when `$shippingAssignment->getItems()` is empty |
| Manipulating quote totals in JS | Bypasses server-side validation | Use collector pattern server-side; let Magento sync to frontend |
| Config providers in global `di.xml` | Unnecessary instantiation in admin/API | Register in `etc/frontend/di.xml` |
| Testing with single payment/shipping | Misses compatibility issues | Test with 2+ shipping and 2+ payment methods active |
| Hardcoding prices without base currency | Breaks multi-currency stores | Set both `setTotalAmount` and `setBaseTotalAmount` |

## 7. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md`. Most checkout customizations combine di.xml, static assets, and layout:

```bash
bin/magento setup:di:compile && bin/magento setup:static-content:deploy -f && bin/magento cache:flush
```

**Verification:**
1. Navigate to `/checkout` and open browser DevTools
2. **Config providers** -- check `window.checkoutConfig` in the console for your keys
3. **Custom steps** -- verify the step appears in the navigation bar at the correct position
4. **Total collectors** -- check the order summary sidebar; verify via `GET /V1/carts/mine/totals`
5. **Layout changes** -- inspect the checkout DOM for added/moved components
6. Check `var/log/system.log` and `var/log/exception.log` for errors
