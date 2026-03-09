# Message Queue Adapter Comparison

## MySQL (`db`) vs AMQP (`amqp`) / RabbitMQ

| Feature | MySQL (`db`) | AMQP (`amqp`) |
|---------|-------------|----------------|
| **Setup** | Zero — uses existing database | Requires RabbitMQ server |
| **Configuration** | Automatic (uses Magento DB) | `env.php` → `queue.amqp` section |
| **Performance** | Good for low-moderate volume | High throughput, scalable |
| **Persistence** | Stored in `queue_message` table | Configurable (persistent/transient) |
| **Retry semantics** | Basic — failed messages stay in queue | Advanced — dead letter exchanges, TTL |
| **Routing** | Topic-based only | Exchange types: direct, topic, fanout, headers |
| **Monitoring** | SQL queries on queue tables | RabbitMQ Management UI |
| **Multi-consumer** | Supported but single-threaded per consumer | Native parallel consumers |
| **Cloud compatibility** | Always available | Requires Magento Commerce or custom setup |

## When to Use MySQL (`db`)

- Magento Open Source (Community Edition)
- Low-to-moderate message volume (< 10,000/day)
- Simple pub/sub patterns
- No external service dependencies desired
- Development and staging environments

## When to Use AMQP (`amqp`)

- Magento Commerce (Adobe Commerce) — RabbitMQ included
- High message volume (> 10,000/day)
- Need advanced routing, dead letter queues, or TTL
- Multiple consumers processing in parallel
- Production environments with dedicated message broker

## env.php Configuration for AMQP

```php
'queue' => [
    'amqp' => [
        'host' => 'rabbitmq.example.com',
        'port' => '5672',
        'user' => 'magento',
        'password' => 'secret',
        'virtualhost' => '/',
    ],
],
```

## Connection Name in XML Files

- For MySQL: `connection="db"`
- For AMQP: `connection="amqp"`

All four XML files (communication.xml, queue_topology.xml, queue_consumer.xml, queue_publisher.xml) must use the same connection for a given topic.
