# REST API Test Patterns

## API Functional Test Base

Magento API functional tests use `Magento\TestFramework\TestCase\WebapiAbstract` and run against the REST/SOAP endpoints.

### Basic REST API Test

```php
<?php
/**
 * Copyright © Monsoon Consulting. All rights reserved.
 * See LICENSE_MONSOON.txt for license details.
 */

declare(strict_types=1);

namespace {Vendor}\{ModuleName}\Test\Api;

use Magento\TestFramework\TestCase\WebapiAbstract;

final class {Entity}RepositoryTest extends WebapiAbstract
{
    private const RESOURCE_PATH = '/V1/{vendor}-{module}/{entity-kebab}';
    private const SERVICE_NAME = '{vendor}{Module}{Entity}RepositoryV1';

    /**
     * @magentoApiDataFixture {Vendor}_{ModuleName}::Test/Api/_files/{fixture}.php
     */
    public function testGetById(): void
    {
        $entityId = 1;
        $serviceInfo = [
            'rest' => [
                'resourcePath' => self::RESOURCE_PATH . '/' . $entityId,
                'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_GET,
            ],
        ];

        $response = $this->_webApiCall($serviceInfo);

        $this->assertArrayHasKey('entity_id', $response);
        $this->assertEquals($entityId, $response['entity_id']);
    }

    public function testGetByIdThrows404ForMissing(): void
    {
        $entityId = 99999;
        $serviceInfo = [
            'rest' => [
                'resourcePath' => self::RESOURCE_PATH . '/' . $entityId,
                'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_GET,
            ],
        ];

        $this->expectException(\Exception::class);
        $this->expectExceptionCode(404);

        $this->_webApiCall($serviceInfo);
    }

    public function testGetList(): void
    {
        $searchCriteria = [
            'searchCriteria' => [
                'filterGroups' => [],
                'pageSize' => 10,
                'currentPage' => 1,
            ],
        ];

        $serviceInfo = [
            'rest' => [
                'resourcePath' => self::RESOURCE_PATH . 's?' . http_build_query($searchCriteria),
                'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_GET,
            ],
        ];

        $response = $this->_webApiCall($serviceInfo);

        $this->assertArrayHasKey('items', $response);
        $this->assertArrayHasKey('total_count', $response);
    }

    public function testCreate(): void
    {
        $entityData = [
            'entity' => [
                'title' => 'Test Entity',
                'is_active' => true,
            ],
        ];

        $serviceInfo = [
            'rest' => [
                'resourcePath' => self::RESOURCE_PATH,
                'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_POST,
            ],
        ];

        $response = $this->_webApiCall($serviceInfo, $entityData);

        $this->assertArrayHasKey('entity_id', $response);
        $this->assertEquals('Test Entity', $response['title']);
    }

    public function testDelete(): void
    {
        $entityId = 1;
        $serviceInfo = [
            'rest' => [
                'resourcePath' => self::RESOURCE_PATH . '/' . $entityId,
                'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_DELETE,
            ],
        ];

        $response = $this->_webApiCall($serviceInfo);

        $this->assertTrue($response);
    }
}
```

### Token-Based Authentication

For endpoints requiring admin authentication:

```php
$token = $this->getAdminToken();

$serviceInfo = [
    'rest' => [
        'resourcePath' => self::RESOURCE_PATH,
        'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_GET,
        'token' => $token,
    ],
];
```

Helper method:

```php
private function getAdminToken(): string
{
    $serviceInfo = [
        'rest' => [
            'resourcePath' => '/V1/integration/admin/token',
            'httpMethod' => \Magento\Framework\Webapi\Rest\Request::HTTP_METHOD_POST,
        ],
    ];

    return $this->_webApiCall($serviceInfo, [
        'username' => TESTS_WEBSERVICE_USER,
        'password' => TESTS_WEBSERVICE_APIKEY,
    ]);
}
```

### Test Configuration

API functional tests require `dev/tests/api-functional/phpunit_rest.xml.dist` configuration. Set `TESTS_BASE_URL`, `TESTS_WEBSERVICE_USER`, and `TESTS_WEBSERVICE_APIKEY` in the config.

Run with: `vendor/bin/phpunit -c dev/tests/api-functional/phpunit_rest.xml.dist`
