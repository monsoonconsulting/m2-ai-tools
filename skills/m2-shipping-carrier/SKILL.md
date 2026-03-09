---
name: m2-shipping-carrier
description: >
  Generate Magento 2 custom shipping carrier including CarrierInterface implementation,
  config.xml carrier defaults, system.xml admin fields, rate request/result handling,
  tracking info, and di.xml carrier pool registration. Use this skill when building
  custom shipping methods or carrier integrations.
  Trigger on: "shipping carrier", "shipping method", "custom shipping", "CarrierInterface",
  "shipping rate", "collectRates", "shipping tracking", "carrier config", "free shipping",
  "shipping calculator", "delivery method", "shipping integration", "flat rate shipping",
  "table rates", "shipping API", "carrier code".
---

# Magento 2 Custom Shipping Carrier

You are a Magento 2 shipping carrier specialist. Generate custom shipping carriers, rate calculations, and tracking implementations under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Building a custom shipping method (flat rate, calculated, API-based)
- Integrating with an external shipping carrier API
- Creating table-rate or weight-based shipping calculations
- Adding shipping tracking information

**Use `/m2-plugin` instead when:**
- Modifying an existing carrier's behavior

**Use `/m2-system-config` instead when:**
- Only adding configuration fields without shipping logic

## 2. Gather Requirements

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Carrier code** — lowercase identifier (e.g., `acme_express`)
- **Carrier title** — display name (e.g., "Acme Express Delivery")
- **Rate calculation type** — flat rate, per-item, per-weight, API-based, table-rate

**Optional:**
- **Multiple methods** — does the carrier offer multiple shipping options? (default: single method)
- **Tracking support** — default: no
- **Free shipping threshold** — default: none
- **Allowed countries** — default: all

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Carrier code | `{vendor}_{carrier}` lowercase | `acme_express` |
| Config path | `carriers/{carrier_code}/{field}` | `carriers/acme_express/active` |
| Carrier class | `Model\Carrier\{Name}` | `Model\Carrier\Express` |
| Method code | lowercase identifier | `standard`, `express`, `overnight` |

## 4. Templates

### 4.1 Carrier Class — `Model/Carrier/{Name}.php`

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Carrier;

use Magento\Framework\App\Config\ScopeConfigInterface;
use Magento\Quote\Model\Quote\Address\RateRequest;
use Magento\Quote\Model\Quote\Address\RateResult\ErrorFactory;
use Magento\Quote\Model\Quote\Address\RateResult\MethodFactory;
use Magento\Shipping\Model\Carrier\AbstractCarrier;
use Magento\Shipping\Model\Carrier\CarrierInterface;
use Magento\Shipping\Model\Rate\ResultFactory;
use Psr\Log\LoggerInterface;

class {Name} extends AbstractCarrier implements CarrierInterface
{
    // Required by AbstractCarrier — framework convention, not a code style violation
    protected $_code = '{carrier_code}';

    public function __construct(
        ScopeConfigInterface $scopeConfig,
        ErrorFactory $rateErrorFactory,
        LoggerInterface $logger,
        private readonly ResultFactory $rateResultFactory,
        private readonly MethodFactory $rateMethodFactory,
        array $data = []
    ) {
        parent::__construct($scopeConfig, $rateErrorFactory, $logger, $data);
    }

    public function collectRates(RateRequest $request): \Magento\Shipping\Model\Rate\Result|bool
    {
        if (!$this->getConfigFlag('active')) {
            return false;
        }

        $result = $this->checkAvailableShipCountries($request);
        if ($result !== false) {
            return $result;
        }

        $result = $this->rateResultFactory->create();

        $method = $this->rateMethodFactory->create();
        $method->setCarrier($this->_code);
        $method->setCarrierTitle($this->getConfigData('title'));
        $method->setMethod('standard');
        $method->setMethodTitle($this->getConfigData('method_title'));
        $method->setPrice($this->getConfigData('price'));
        $method->setCost($this->getConfigData('price'));

        $result->append($method);

        return $result;
    }

    public function getAllowedMethods(): array
    {
        return ['standard' => $this->getConfigData('method_title')];
    }

    public function isTrackingAvailable(): bool
    {
        return false;
    }
}
```

### 4.2 Carrier with Multiple Methods

```php
public function collectRates(RateRequest $request): \Magento\Shipping\Model\Rate\Result|bool
{
    if (!$this->getConfigFlag('active')) {
        return false;
    }

    $result = $this->rateResultFactory->create();

    $methods = [
        'standard' => ['title' => 'Standard (3-5 days)', 'price' => 5.99],
        'express'  => ['title' => 'Express (1-2 days)', 'price' => 12.99],
        'overnight' => ['title' => 'Overnight', 'price' => 24.99],
    ];

    foreach ($methods as $code => $info) {
        $method = $this->rateMethodFactory->create();
        $method->setCarrier($this->_code);
        $method->setCarrierTitle($this->getConfigData('title'));
        $method->setMethod($code);
        $method->setMethodTitle($info['title']);
        $method->setPrice($info['price']);
        $method->setCost($info['price']);
        $result->append($method);
    }

    return $result;
}

public function getAllowedMethods(): array
{
    return [
        'standard' => 'Standard',
        'express' => 'Express',
        'overnight' => 'Overnight',
    ];
}
```

### 4.3 Weight-Based Rate Calculation

```php
public function collectRates(RateRequest $request): \Magento\Shipping\Model\Rate\Result|bool
{
    if (!$this->getConfigFlag('active')) {
        return false;
    }

    $result = $this->rateResultFactory->create();
    $basePrice = (float) $this->getConfigData('price');
    $pricePerKg = (float) $this->getConfigData('price_per_kg');
    $totalWeight = (float) $request->getPackageWeight();

    // Free shipping threshold
    $freeShippingThreshold = (float) $this->getConfigData('free_shipping_threshold');
    if ($freeShippingThreshold > 0 && $request->getPackageValue() >= $freeShippingThreshold) {
        $shippingPrice = 0;
    } else {
        $shippingPrice = $basePrice + ($totalWeight * $pricePerKg);
    }

    $method = $this->rateMethodFactory->create();
    $method->setCarrier($this->_code);
    $method->setCarrierTitle($this->getConfigData('title'));
    $method->setMethod('standard');
    $method->setMethodTitle($this->getConfigData('method_title'));
    $method->setPrice($shippingPrice);
    $method->setCost($shippingPrice);
    $result->append($method);

    return $result;
}
```

### 4.4 Tracking Support

Add to the carrier class:

```php
public function isTrackingAvailable(): bool
{
    return true;
}

public function getTrackingInfo(string $trackingNumber): \Magento\Shipping\Model\Tracking\Result\Status
{
    $status = $this->_trackStatusFactory->create();
    $status->setCarrier($this->_code);
    $status->setCarrierTitle($this->getConfigData('title'));
    $status->setTracking($trackingNumber);
    $status->setUrl('https://tracking.example.com/?id=' . $trackingNumber);
    return $status;
}
```

Inject `\Magento\Shipping\Model\Tracking\Result\StatusFactory` in the constructor.

### 4.5 config.xml — `etc/config.xml`

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <carriers>
            <{carrier_code}>
                <active>0</active>
                <title>{Carrier Title}</title>
                <method_title>Standard Shipping</method_title>
                <price>5.99</price>
                <model>{Vendor}\{ModuleName}\Model\Carrier\{Name}</model>
                <sallowspecific>0</sallowspecific>
                <sort_order>100</sort_order>
            </{carrier_code}>
        </carriers>
    </default>
</config>
```

### 4.6 system.xml — Admin Configuration

```xml
<section id="carriers">
    <group id="{carrier_code}" translate="label" sortOrder="100" showInDefault="1" showInWebsite="1" showInStore="1">
        <label>{Carrier Title}</label>
        <field id="active" translate="label" type="select" sortOrder="10" showInDefault="1" showInWebsite="1">
            <label>Enabled</label>
            <source_model>Magento\Config\Model\Config\Source\Yesno</source_model>
        </field>
        <field id="title" translate="label" type="text" sortOrder="20" showInDefault="1" showInWebsite="1" showInStore="1">
            <label>Title</label>
        </field>
        <field id="method_title" translate="label" type="text" sortOrder="30" showInDefault="1" showInWebsite="1" showInStore="1">
            <label>Method Name</label>
        </field>
        <field id="price" translate="label" type="text" sortOrder="40" showInDefault="1" showInWebsite="1">
            <label>Shipping Cost</label>
            <validate>validate-number validate-zero-or-greater</validate>
        </field>
        <field id="sallowspecific" translate="label" type="select" sortOrder="90" showInDefault="1" showInWebsite="1">
            <label>Ship to Applicable Countries</label>
            <source_model>Magento\Shipping\Model\Config\Source\Allspecificcountries</source_model>
        </field>
        <field id="specificcountry" translate="label" type="multiselect" sortOrder="91" showInDefault="1" showInWebsite="1">
            <label>Ship to Specific Countries</label>
            <source_model>Magento\Directory\Model\Config\Source\Country</source_model>
            <depends><field id="sallowspecific">1</field></depends>
        </field>
        <field id="sort_order" translate="label" type="text" sortOrder="100" showInDefault="1" showInWebsite="1">
            <label>Sort Order</label>
            <validate>validate-number</validate>
        </field>
    </group>
</section>
```

## 5. Generation Rules

1. **Verify the module exists** — check `registration.php`.
2. **Create the Carrier class** — `Model/Carrier/{Name}.php` implementing `CarrierInterface`.
3. **Create `etc/config.xml`** — carrier defaults under `carriers/{code}`.
4. **Create admin config** — `etc/adminhtml/system.xml` fields under `carriers` section.
5. **Add module dependency** — add `Magento_Shipping` to `etc/module.xml` sequence.
6. **Remind the user** to run post-generation commands.

## 6. Anti-Patterns

**Missing `model` in config.xml.** The `model` field must contain the fully qualified carrier class name. Without it, Magento cannot instantiate your carrier.

**`collectRates` returning `null`.** Return `false` when the carrier is inactive or unavailable. Return a `Result` object (even empty) otherwise. Returning `null` causes errors.

**Not implementing `getAllowedMethods`.** This method is required for admin order creation and affects which methods appear in the admin shipping method dropdown.

**Hardcoded prices.** Always read prices from config (`$this->getConfigData('price')`) so admins can adjust without code changes.

**Ignoring `$request` data.** The `RateRequest` contains destination, weight, value, and item details. Use them for accurate rate calculations. Ignoring destination means no country filtering.

**Missing country restriction.** Always support `sallowspecific`/`specificcountry` config to let admins restrict shipping to specific countries.

## 7. Post-Generation Steps

```bash
bin/magento module:enable {Vendor}_{ModuleName}
bin/magento setup:upgrade
bin/magento setup:di:compile
bin/magento cache:flush
```

Test: Stores > Configuration > Sales > Shipping Methods — your carrier should appear. Add items to cart and proceed to checkout to verify rates appear.
