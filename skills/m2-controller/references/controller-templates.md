# Controller Templates

Full PHP controller templates for common frontend controller patterns. All templates use Monsoon Consulting copyright, `declare(strict_types=1)`, and PHP 8.2+ constructor promotion.

## 1. Frontend GET Page Controller

Displays a full page with layout XML. Use for storefront pages.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Folder};

use Magento\Framework\App\Action\Action;
use Magento\Framework\App\Action\Context;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\View\Result\Page;
use Magento\Framework\View\Result\PageFactory;

class {Action} extends Action implements HttpGetActionInterface
{
    public function __construct(
        Context $context,
        private readonly PageFactory $resultPageFactory
    ) {
        parent::__construct($context);
    }

    public function execute(): Page
    {
        $resultPage = $this->resultPageFactory->create();
        $resultPage->getConfig()->getTitle()->set(__('Page Title'));

        return $resultPage;
    }
}
```

**Layout handle:** `{route_id}_{folder}_{action}.xml` (all lowercase)

## 2. Frontend POST Form Handler + Redirect

Handles form submissions, validates form key, delegates to a service, uses DataPersistor for error recovery.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Folder};

use Magento\Framework\App\Action\Action;
use Magento\Framework\App\Action\Context;
use Magento\Framework\App\Action\HttpPostActionInterface;
use Magento\Framework\App\Request\DataPersistorInterface;
use Magento\Framework\Controller\Result\Redirect;
use Magento\Framework\Exception\LocalizedException;

class {Action} extends Action implements HttpPostActionInterface
{
    public function __construct(
        Context $context,
        private readonly DataPersistorInterface $dataPersistor
    ) {
        parent::__construct($context);
    }

    public function execute(): Redirect
    {
        $resultRedirect = $this->resultRedirectFactory->create();

        $data = $this->getRequest()->getPostValue();
        if (empty($data)) {
            return $resultRedirect->setPath('*/*/');
        }

        try {
            // Delegate to service class:
            // $this->myService->execute($data);

            $this->messageManager->addSuccessMessage(__('Your submission has been saved.'));
            $this->dataPersistor->clear('{persistor_key}');

            return $resultRedirect->setPath('*/*/');
        } catch (LocalizedException $e) {
            $this->messageManager->addErrorMessage($e->getMessage());
        } catch (\Exception $e) {
            $this->messageManager->addExceptionMessage(
                $e,
                __('Something went wrong while saving your submission.')
            );
        }

        $this->dataPersistor->set('{persistor_key}', $data);

        return $resultRedirect->setPath('*/*/{form_action}');
    }
}
```

**Notes:**
- Form key validation is automatic for classes extending `Magento\Framework\App\Action\Action` with POST.
- Replace `{persistor_key}` with a unique key (e.g., `contact_form`).
- Replace the service call comment with actual business logic delegation.

## 3. Frontend AJAX GET JSON Controller

Returns JSON data for GET AJAX requests. Use for loading data without page reload.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Folder};

use Magento\Framework\App\Action\Action;
use Magento\Framework\App\Action\Context;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\Controller\Result\Json;
use Magento\Framework\Controller\Result\JsonFactory;

class {Action} extends Action implements HttpGetActionInterface
{
    public function __construct(
        Context $context,
        private readonly JsonFactory $jsonFactory
    ) {
        parent::__construct($context);
    }

    public function execute(): Json
    {
        $result = $this->jsonFactory->create();

        try {
            $data = [
                'success' => true,
                'data' => [],
            ];
        } catch (\Exception $e) {
            $data = [
                'success' => false,
                'message' => __('Unable to load data.'),
            ];
        }

        return $result->setData($data);
    }
}
```

## 4. Frontend AJAX POST JSON Controller

Handles POST AJAX requests and returns JSON. Use for form submissions via AJAX or data mutations.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Folder};

use Magento\Framework\App\Action\Action;
use Magento\Framework\App\Action\Context;
use Magento\Framework\App\Action\HttpPostActionInterface;
use Magento\Framework\Controller\Result\Json;
use Magento\Framework\Controller\Result\JsonFactory;

class {Action} extends Action implements HttpPostActionInterface
{
    public function __construct(
        Context $context,
        private readonly JsonFactory $jsonFactory
    ) {
        parent::__construct($context);
    }

    public function execute(): Json
    {
        $result = $this->jsonFactory->create();

        $data = $this->getRequest()->getPostValue();
        if (empty($data)) {
            return $result->setData([
                'success' => false,
                'message' => __('Invalid request.'),
            ]);
        }

        try {
            // Delegate to service class:
            // $responseData = $this->myService->execute($data);

            return $result->setData([
                'success' => true,
                'message' => __('Operation completed successfully.'),
            ]);
        } catch (\Exception $e) {
            return $result->setData([
                'success' => false,
                'message' => __('An error occurred: %1', $e->getMessage()),
            ]);
        }
    }
}
```

**Notes:**
- Form key validation is automatic. AJAX callers must include `form_key` in the POST body or `X-Requested-With: XMLHttpRequest` header.
- For JSON request bodies, read via `$this->getRequest()->getContent()` and `json_decode()`.

## 5. CSRF-Exempt POST Controller (Webhooks)

For controllers receiving POST requests from external systems that cannot provide a Magento form key.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Folder};

use Magento\Framework\App\Action\Action;
use Magento\Framework\App\Action\Context;
use Magento\Framework\App\Action\HttpPostActionInterface;
use Magento\Framework\App\CsrfAwareActionInterface;
use Magento\Framework\App\Request\InvalidRequestException;
use Magento\Framework\App\RequestInterface;
use Magento\Framework\Controller\Result\Json;
use Magento\Framework\Controller\Result\JsonFactory;
use Psr\Log\LoggerInterface;

class {Action} extends Action implements HttpPostActionInterface, CsrfAwareActionInterface
{
    public function __construct(
        Context $context,
        private readonly JsonFactory $jsonFactory,
        private readonly LoggerInterface $logger
    ) {
        parent::__construct($context);
    }

    public function createCsrfValidationException(RequestInterface $request): ?InvalidRequestException
    {
        return null;
    }

    public function validateForCsrf(RequestInterface $request): ?bool
    {
        // TODO: Implement signature verification, API key check, or IP whitelist.
        // Example HMAC verification:
        // $signature = $request->getHeader('X-Signature');
        // $payload = $request->getContent();
        // return hash_equals(hash_hmac('sha256', $payload, $secret), $signature);

        return true;
    }

    public function execute(): Json
    {
        $result = $this->jsonFactory->create();

        try {
            $payload = $this->getRequest()->getContent();
            $data = json_decode($payload, true, 512, JSON_THROW_ON_ERROR);

            // Delegate to service class:
            // $this->webhookProcessor->process($data);

            $this->logger->info('Webhook received', ['type' => $data['type'] ?? 'unknown']);

            return $result->setData(['success' => true]);
        } catch (\JsonException $e) {
            $this->logger->error('Webhook: invalid JSON payload', ['error' => $e->getMessage()]);

            return $result->setHttpResponseCode(400)->setData([
                'success' => false,
                'message' => 'Invalid JSON payload.',
            ]);
        } catch (\Exception $e) {
            $this->logger->error('Webhook processing failed', ['error' => $e->getMessage()]);

            return $result->setHttpResponseCode(500)->setData([
                'success' => false,
                'message' => 'Internal error.',
            ]);
        }
    }
}
```

**Important:** Always implement real validation in `validateForCsrf()`. The `return true` placeholder must be replaced with actual security checks (HMAC signature, shared secret, IP whitelist).

## 6. Forward Controller

Forwards to another controller action without changing the URL. Use for aliasing or conditional routing.

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Controller\{Folder};

use Magento\Framework\App\Action\Action;
use Magento\Framework\App\Action\HttpGetActionInterface;
use Magento\Framework\Controller\Result\Forward;
use Magento\Framework\Controller\ResultFactory;

class {Action} extends Action implements HttpGetActionInterface
{
    public function execute(): Forward
    {
        /** @var Forward $resultForward */
        $resultForward = $this->resultFactory->create(ResultFactory::TYPE_FORWARD);

        return $resultForward->forward('{target_action}');
    }
}
```

To forward to a different controller folder or module:

```php
$resultForward = $this->resultFactory->create(ResultFactory::TYPE_FORWARD);
$resultForward->setModule('{module_frontname}');
$resultForward->setController('{controller_folder}');
return $resultForward->forward('{action}');
```
