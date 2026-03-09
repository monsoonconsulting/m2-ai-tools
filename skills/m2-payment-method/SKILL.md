---
name: m2-payment-method
description: >
  Generate Magento 2 payment method configuration including payment gateway commands,
  transfer factories, HTTP clients, value handlers, validators, and payment method
  facade via di.xml. Use this skill when building custom payment integrations.
  Trigger on: "payment method", "payment gateway", "payment.xml", "gateway command",
  "authorize", "capture", "void", "refund", "payment integration", "payment config",
  "credit card payment", "online payment", "payment facade", "TransferFactory",
  "GatewayCommand", "payment form", "payment JS component", "order payment",
  "checkout payment", "payment processor", "payment provider", "vault", "payment token".
---

# Magento 2 Payment Method Generator

You are a Magento 2 payment gateway specialist. Generate payment method configuration, gateway commands, and supporting classes under existing modules in `app/code/{Vendor}/{ModuleName}/`.

Follow the coding conventions and file headers defined in `.claude/skills/_shared/conventions.md` and `.claude/skills/m2-module/SKILL.md`. Do not duplicate those conventions here.

**Prerequisites:** Module must exist (see `_shared/conventions.md`). If not, use `/m2-module` first.

## 1. Decision Tree

**Use this skill when:**
- Building a new payment method integration (credit card, bank transfer, wallet, etc.)
- Implementing gateway commands (authorize, capture, void, refund)
- Configuring payment method facade via di.xml

**Use `/m2-plugin` instead when:**
- Modifying an existing payment method's behavior

**Use `/m2-system-config` instead when:**
- Only adding configuration fields (no payment processing logic)

## 2. Gather Requirements

**Required (ask if not provided):**
- **Module name** — `Vendor_ModuleName`
- **Payment method code** — lowercase identifier (e.g., `acme_gateway`)
- **Gateway operations** — which operations: authorize, capture, authorize_and_capture, void, refund
- **Payment type** — online (API-based) or offline (manual processing)

**Optional:**
- **Payment form on checkout** — does it render a form for card details? (default: no — redirect-based)
- **Sandbox/production modes** — default: yes (both modes)
- **Supported currencies** — default: all
- **Supported countries** — default: all

## 3. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Method code | `{vendor}_{gateway}` lowercase | `acme_gateway` |
| Config path | `payment/{method_code}/{field}` | `payment/acme_gateway/active` |
| Gateway namespace | `Gateway/` | `Gateway/Command/`, `Gateway/Http/`, `Gateway/Request/`, `Gateway/Response/` |
| DI facade name | `{Vendor}{ModuleName}Facade` | `AcmeGatewayFacade` |

## 4. Architecture Overview

Magento's Payment Gateway uses a command pattern:

```
Checkout -> PaymentMethodFacade -> GatewayCommand -> RequestBuilder -> TransferFactory -> HttpClient -> ResponseHandler/Validator
```

1. **Facade** — entry point, routes to commands (authorize, capture, etc.)
2. **Command** — orchestrates a single operation (e.g., authorize)
3. **RequestBuilder** — builds the API request payload
4. **TransferFactory** — creates a transfer object (URL, headers, body)
5. **HttpClient** — sends the HTTP request to the gateway API
6. **ResponseHandler** — processes the API response, updates payment object
7. **Validator** — validates the API response (success/failure)

## 5. Templates

### 5.1 config.xml — `etc/config.xml`

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Store:etc/config.xsd">
    <default>
        <payment>
            <{method_code}>
                <active>0</active>
                <title>{Payment Method Title}</title>
                <model>{Vendor}{ModuleName}Facade</model>
                <order_status>processing</order_status>
                <payment_action>authorize_and_capture</payment_action>
                <can_authorize>1</can_authorize>
                <can_capture>1</can_capture>
                <can_void>1</can_void>
                <can_refund>1</can_refund>
                <can_use_checkout>1</can_use_checkout>
                <can_use_internal>1</can_use_internal>
                <is_gateway>1</is_gateway>
                <sandbox_mode>1</sandbox_mode>
            </{method_code}>
        </payment>
    </default>
</config>
```

### 5.2 di.xml — Payment Facade (Virtual Type)

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:framework:ObjectManager/etc/config.xsd">

    <!-- Payment Method Facade -->
    <virtualType name="{Vendor}{ModuleName}Facade" type="Magento\Payment\Model\Method\Adapter">
        <arguments>
            <argument name="code" xsi:type="const">{Vendor}\{ModuleName}\Model\Config::METHOD_CODE</argument>
            <argument name="formBlockType" xsi:type="string">Magento\Payment\Block\Form</argument>
            <argument name="infoBlockType" xsi:type="string">Magento\Payment\Block\Info</argument>
            <argument name="valueHandlerPool" xsi:type="object">{Vendor}{ModuleName}ValueHandlerPool</argument>
            <argument name="commandPool" xsi:type="object">{Vendor}{ModuleName}CommandPool</argument>
        </arguments>
    </virtualType>

    <!-- Command Pool -->
    <virtualType name="{Vendor}{ModuleName}CommandPool" type="Magento\Payment\Gateway\Command\CommandPool">
        <arguments>
            <argument name="commands" xsi:type="array">
                <item name="authorize" xsi:type="string">{Vendor}{ModuleName}AuthorizeCommand</item>
                <item name="capture" xsi:type="string">{Vendor}{ModuleName}CaptureCommand</item>
            </argument>
        </arguments>
    </virtualType>

    <!-- Value Handler Pool -->
    <virtualType name="{Vendor}{ModuleName}ValueHandlerPool" type="Magento\Payment\Gateway\Config\ValueHandlerPool">
        <arguments>
            <argument name="handlers" xsi:type="array">
                <item name="default" xsi:type="string">{Vendor}{ModuleName}ConfigValueHandler</item>
            </argument>
        </arguments>
    </virtualType>

    <virtualType name="{Vendor}{ModuleName}ConfigValueHandler" type="Magento\Payment\Gateway\Config\ConfigValueHandler">
        <arguments>
            <argument name="gateway" xsi:type="object">{Vendor}{ModuleName}Config</argument>
        </arguments>
    </virtualType>

    <virtualType name="{Vendor}{ModuleName}Config" type="Magento\Payment\Gateway\Config\Config">
        <arguments>
            <argument name="methodCode" xsi:type="const">{Vendor}\{ModuleName}\Model\Config::METHOD_CODE</argument>
        </arguments>
    </virtualType>
</config>
```

### 5.3 Config Model — `Model/Config.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model;

final class Config
{
    public const METHOD_CODE = '{method_code}';
}
```

### 5.4 Request Builder — `Gateway/Request/AuthorizeRequestBuilder.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Gateway\Request;

use Magento\Payment\Gateway\Helper\SubjectReader;
use Magento\Payment\Gateway\Request\BuilderInterface;

final class AuthorizeRequestBuilder implements BuilderInterface
{
    public function build(array $buildSubject): array
    {
        $paymentDO = SubjectReader::readPayment($buildSubject);
        $payment = $paymentDO->getPayment();
        $order = $paymentDO->getOrder();

        return [
            'amount' => SubjectReader::readAmount($buildSubject),
            'currency' => $order->getCurrencyCode(),
            'order_id' => $order->getOrderIncrementId(),
        ];
    }
}
```

### 5.5 Transfer Factory — `Gateway/Http/TransferFactory.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Gateway\Http;

use Magento\Payment\Gateway\Http\TransferBuilder;
use Magento\Payment\Gateway\Http\TransferFactoryInterface;
use Magento\Payment\Gateway\Http\TransferInterface;

final class TransferFactory implements TransferFactoryInterface
{
    public function __construct(
        private readonly TransferBuilder $transferBuilder,
        private readonly \Magento\Payment\Gateway\Config\Config $config
    ) {
    }

    public function create(array $request): TransferInterface
    {
        $apiUrl = $this->config->getValue('sandbox_mode')
            ? 'https://sandbox.gateway.example.com/api'
            : 'https://gateway.example.com/api';

        return $this->transferBuilder
            ->setUri($apiUrl)
            ->setMethod('POST')
            ->setHeaders(['Content-Type' => 'application/json'])
            ->setBody(json_encode($request))
            ->build();
    }
}
```

### 5.6 Capture Request Builder — `Gateway/Request/CaptureRequestBuilder.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Gateway\Request;

use Magento\Payment\Gateway\Helper\SubjectReader;
use Magento\Payment\Gateway\Request\BuilderInterface;

final class CaptureRequestBuilder implements BuilderInterface
{
    public function build(array $buildSubject): array
    {
        $paymentDO = SubjectReader::readPayment($buildSubject);
        $payment = $paymentDO->getPayment();

        return [
            'amount' => SubjectReader::readAmount($buildSubject),
            'transaction_id' => $payment->getLastTransId(),
        ];
    }
}
```

### 5.7 Payment Action Source Model — `Model/Source/PaymentAction.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Model\Source;

use Magento\Framework\Data\OptionSourceInterface;

final class PaymentAction implements OptionSourceInterface
{
    public function toOptionArray(): array
    {
        return [
            ['value' => 'authorize', 'label' => __('Authorize Only')],
            ['value' => 'authorize_and_capture', 'label' => __('Authorize and Capture')],
        ];
    }
}
```

### 5.8 Gateway Command Virtual Types (di.xml)

Add these inside the `<config>` element in `etc/di.xml`, alongside the Facade and Command Pool from section 5.2:

```xml
    <!-- Authorize Command -->
    <virtualType name="{Vendor}{ModuleName}AuthorizeCommand" type="Magento\Payment\Gateway\Command\GatewayCommand">
        <arguments>
            <argument name="requestBuilder" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Request\AuthorizeRequestBuilder</argument>
            <argument name="transferFactory" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Http\TransferFactory</argument>
            <argument name="client" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Http\Client</argument>
            <argument name="handler" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Response\AuthorizeHandler</argument>
            <argument name="validator" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Validator\ResponseValidator</argument>
        </arguments>
    </virtualType>

    <!-- Capture Command -->
    <virtualType name="{Vendor}{ModuleName}CaptureCommand" type="Magento\Payment\Gateway\Command\GatewayCommand">
        <arguments>
            <argument name="requestBuilder" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Request\CaptureRequestBuilder</argument>
            <argument name="transferFactory" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Http\TransferFactory</argument>
            <argument name="client" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Http\Client</argument>
            <argument name="handler" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Response\CaptureHandler</argument>
            <argument name="validator" xsi:type="object">{Vendor}\{ModuleName}\Gateway\Validator\ResponseValidator</argument>
        </arguments>
    </virtualType>
```

### 5.9 HTTP Client, Response Handler, Response Validator (Summary)

These classes complete the gateway command chain. Create them under `Gateway/`:

- **`Gateway/Http/Client.php`** — implements `ClientInterface`, sends HTTP requests via cURL. See `references/gateway-commands.md` for full template.
- **`Gateway/Response/AuthorizeHandler.php`** — implements `HandlerInterface`, stores `transaction_id` on payment. See `references/gateway-commands.md`.
- **`Gateway/Response/CaptureHandler.php`** — similar to AuthorizeHandler, closes the transaction (`setIsTransactionClosed(true)`).
- **`Gateway/Validator/ResponseValidator.php`** — extends `AbstractValidator`, checks `$response['success']`. See `references/gateway-commands.md`.

## 6. system.xml — Admin Configuration

```xml
<section id="payment">
    <group id="{method_code}" translate="label" sortOrder="100" showInDefault="1" showInWebsite="1">
        <label>{Payment Method Title}</label>
        <field id="active" translate="label" type="select" sortOrder="10" showInDefault="1" showInWebsite="1">
            <label>Enabled</label>
            <source_model>Magento\Config\Model\Config\Source\Yesno</source_model>
        </field>
        <field id="title" translate="label" type="text" sortOrder="20" showInDefault="1" showInWebsite="1" showInStore="1">
            <label>Title</label>
        </field>
        <field id="sandbox_mode" translate="label" type="select" sortOrder="30" showInDefault="1" showInWebsite="1">
            <label>Sandbox Mode</label>
            <source_model>Magento\Config\Model\Config\Source\Yesno</source_model>
        </field>
        <field id="api_key" translate="label" type="obscure" sortOrder="40" showInDefault="1" showInWebsite="1">
            <label>API Key</label>
            <backend_model>Magento\Config\Model\Config\Backend\Encrypted</backend_model>
        </field>
        <field id="payment_action" translate="label" type="select" sortOrder="50" showInDefault="1" showInWebsite="1">
            <label>Payment Action</label>
            <source_model>{Vendor}\{ModuleName}\Model\Source\PaymentAction</source_model>
        </field>
    </group>
</section>
```

## 7. Generation Rules

1. **Verify the module exists** — check `registration.php`.
2. **Create `Model/Config.php`** — method code constant.
3. **Create `etc/config.xml`** — payment defaults.
4. **Create gateway classes** — request builders, transfer factory, HTTP client, response handlers (see `references/gateway-commands.md`).
5. **Create `etc/di.xml`** — facade, command pool, value handler pool, gateway commands.
6. **Create `etc/adminhtml/system.xml`** — admin config fields under `payment` section.
7. **Remind the user** to run post-generation commands.

## 8. Anti-Patterns

**Storing card data in Magento.** Never store credit card numbers. Use tokenization via the gateway. PCI compliance requires it.

**Hardcoded API URLs.** Always use config values for API endpoints. Support sandbox/production modes.

**Missing error handling in response handlers.** Always validate API responses and throw `CommandException` on failures.

**Using `payment_action` without implementing the command.** If `config.xml` says `authorize_and_capture`, both authorize and capture commands must exist in the command pool.

## 9. Post-Generation Steps

Follow `.claude/skills/_shared/post-generation.md` for: di.xml, new module enable.

**Verification:** In admin: **Stores > Configuration > Sales > Payment Methods** — your method should appear.
