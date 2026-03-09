# GraphQL Testing Reference

## API Functional Tests for GraphQL

GraphQL API tests extend `Magento\TestFramework\TestCase\GraphQlAbstract`.

### Test File Location

```
dev/tests/api-functional/testsuite/{Vendor}/{ModuleName}/GraphQl/{Entity}Test.php
```

### Basic Query Test

```php
<?php
declare(strict_types=1);

namespace {Vendor}\{ModuleName}\GraphQl;

use Magento\TestFramework\TestCase\GraphQlAbstract;

class {Entity}QueryTest extends GraphQlAbstract
{
    /**
     * @magentoApiDataFixture {Vendor}_{ModuleName}::Test/Fixture/{entity}_fixture.php
     */
    public function testGetEntity(): void
    {
        $query = <<<QUERY
{
    {entityCamel}(entity_id: 1) {
        entity_id
        title
        is_active
    }
}
QUERY;

        $response = $this->graphQlQuery($query);

        self::assertArrayHasKey('{entityCamel}', $response);
        self::assertEquals(1, $response['{entityCamel}']['entity_id']);
        self::assertNotEmpty($response['{entityCamel}']['title']);
    }
}
```

### Mutation Test

```php
public function testCreateEntity(): void
{
    $mutation = <<<MUTATION
mutation {
    create{Entity}(input: {
        title: "Test Title"
        is_active: true
    }) {
        entity_id
        title
        is_active
    }
}
MUTATION;

    $response = $this->graphQlMutation($mutation);

    self::assertArrayHasKey('create{Entity}', $response);
    self::assertEquals('Test Title', $response['create{Entity}']['title']);
    self::assertTrue($response['create{Entity}']['is_active']);
}
```

### Authenticated Query

```php
public function testAuthenticatedQuery(): void
{
    $query = '{ ... }';
    $headerMap = ['Authorization' => 'Bearer ' . $this->getCustomerToken()];

    $response = $this->graphQlQuery($query, [], '', $headerMap);
    // assertions
}
```

## cURL Testing

### Query

```bash
curl -X POST https://magento.test/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ {entityCamel}(entity_id: 1) { entity_id title } }"}'
```

### Mutation

```bash
curl -X POST https://magento.test/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { create{Entity}(input: { title: \"Test\" }) { entity_id title } }"}'
```

### Introspection (schema discovery)

```bash
curl -X POST https://magento.test/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __type(name: \"{Entity}\") { fields { name type { name } } } }"}'
```

## Running GraphQL Tests

```bash
# All GraphQL tests
vendor/bin/phpunit -c dev/tests/api-functional/phpunit_graphql.xml.dist

# Single test class
vendor/bin/phpunit -c dev/tests/api-functional/phpunit_graphql.xml.dist \
  --filter {Entity}QueryTest
```
