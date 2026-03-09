# Gateway Commands Reference

> Companion file for m2-payment-method. Contains gateway command virtual types and supporting class templates.

## Gateway Command Virtual Type (Authorize)

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

## HTTP Client — `Gateway/Http/Client.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Gateway\Http;

use Magento\Payment\Gateway\Http\ClientInterface;
use Magento\Payment\Gateway\Http\TransferInterface;
use Psr\Log\LoggerInterface;

final class Client implements ClientInterface
{
    public function __construct(
        private readonly \Magento\Framework\HTTP\Client\Curl $curl,
        private readonly LoggerInterface $logger
    ) {
    }

    public function placeRequest(TransferInterface $transferObject): array
    {
        $this->curl->setHeaders($transferObject->getHeaders());
        $this->curl->post($transferObject->getUri(), $transferObject->getBody());

        $response = json_decode($this->curl->getBody(), true) ?? [];

        $this->logger->debug('Gateway response', ['response' => $response]);

        return $response;
    }
}
```

## Response Handler — `Gateway/Response/AuthorizeHandler.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Gateway\Response;

use Magento\Payment\Gateway\Helper\SubjectReader;
use Magento\Payment\Gateway\Response\HandlerInterface;

final class AuthorizeHandler implements HandlerInterface
{
    public function handle(array $handlingSubject, array $response): void
    {
        $paymentDO = SubjectReader::readPayment($handlingSubject);
        $payment = $paymentDO->getPayment();

        $payment->setTransactionId($response['transaction_id'] ?? '');
        $payment->setIsTransactionClosed(false);
    }
}
```

## Response Validator — `Gateway/Validator/ResponseValidator.php`

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Gateway\Validator;

use Magento\Payment\Gateway\Validator\AbstractValidator;
use Magento\Payment\Gateway\Validator\ResultInterface;
use Magento\Payment\Gateway\Validator\ResultInterfaceFactory;

class ResponseValidator extends AbstractValidator
{
    public function validate(array $validationSubject): ResultInterface
    {
        $response = $validationSubject['response'] ?? [];
        $isValid = isset($response['success']) && $response['success'] === true;
        $errorMessages = [];

        if (!$isValid) {
            $errorMessages[] = $response['error_message'] ?? __('Payment gateway error.');
        }

        return $this->createResult($isValid, $errorMessages);
    }
}
```
