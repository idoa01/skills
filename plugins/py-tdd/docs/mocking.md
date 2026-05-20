# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes — prefer test DB)
- Time/randomness (see [Time section](#time))
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Tools

Use **monkeypatch** for simple value/attribute replacement. Use **pytest-mock** (`mocker` fixture) when you need to assert on interactions at boundaries.

## Designing for Mockability

At system boundaries, design interfaces using Protocol classes that are easy to substitute:

**1. Use constructor injection with Protocols**

```python
from typing import Protocol
from decimal import Decimal


class PaymentClient(Protocol):
    def charge(self, amount: Decimal) -> PaymentResult: ...


class OrderService:
    def __init__(self, payment_client: PaymentClient):
        self._payment_client = payment_client

    def process(self, order: Order) -> PaymentResult:
        return self._payment_client.charge(order.total)
```

```python
# In tests — just pass a fake that satisfies the Protocol
class FakePaymentClient:
    def __init__(self, result: PaymentResult):
        self._result = result

    def charge(self, amount: Decimal) -> PaymentResult:
        return self._result


def test_order_processing():
    client = FakePaymentClient(PaymentResult(status="success"))
    service = OrderService(payment_client=client)

    result = service.process(order)

    assert result.status == "success"
```

**2. Async boundaries**

```python
from typing import Protocol
from decimal import Decimal


class AsyncPaymentClient(Protocol):
    async def charge(self, amount: Decimal) -> PaymentResult: ...


class AsyncOrderService:
    def __init__(self, payment_client: AsyncPaymentClient):
        self._payment_client = payment_client

    async def process(self, order: Order) -> PaymentResult:
        return await self._payment_client.charge(order.total)
```

```python
class FakeAsyncPaymentClient:
    def __init__(self, result: PaymentResult):
        self._result = result

    async def charge(self, amount: Decimal) -> PaymentResult:
        return self._result


@pytest.mark.asyncio
async def test_async_order_processing():
    client = FakeAsyncPaymentClient(PaymentResult(status="success"))
    service = AsyncOrderService(payment_client=client)

    result = await service.process(order)

    assert result.status == "success"
```

**3. Prefer specific interfaces over generic ones**

```python
# GOOD: Each method is independently mockable, clear contract
class InventoryClient(Protocol):
    def check_stock(self, product_id: str) -> int: ...
    def reserve(self, product_id: str, quantity: int) -> Reservation: ...


# BAD: Generic interface forces conditional logic in fakes
class ApiClient(Protocol):
    def request(self, endpoint: str, method: str, **kwargs) -> Response: ...
```

## Time

**Unit/class level**: Inject time as a dependency.

```python
from typing import Callable
from datetime import datetime


class SubscriptionService:
    def __init__(self, clock: Callable[[], datetime]):
        self._clock = clock

    def is_expired(self, subscription: Subscription) -> bool:
        return self._clock() > subscription.expires_at
```

```python
def test_expired_subscription():
    fixed_time = datetime(2025, 6, 1)
    service = SubscriptionService(clock=lambda: fixed_time)

    subscription = Subscription(expires_at=datetime(2025, 5, 1))

    assert service.is_expired(subscription) is True
```

**Integration level**: Use `freezegun` when available (check `pyproject.toml`). Fall back to DI when it's not.

```python
from freezegun import freeze_time


@freeze_time("2025-06-01")
def test_subscription_renewal_flow(subscription_service: SubscriptionService):
    subscription = subscription_service.create(plan="monthly")

    subscription_service.advance_billing_cycle()

    assert subscription_service.get(subscription.id).status == "renewed"
```

## Using monkeypatch vs pytest-mock

**monkeypatch** — replacing values, no need to assert on calls:

```python
def test_reads_config_from_env(monkeypatch):
    monkeypatch.setenv("API_BASE_URL", "https://test.example.com")

    config = AppConfig.from_env()

    assert config.api_base_url == "https://test.example.com"
```

**pytest-mock** — need to verify an interaction happened at a boundary:

```python
def test_sends_confirmation_email(mocker, order_service: OrderService):
    mock_send = mocker.patch("app.email.client.send")

    order_service.complete(order)

    mock_send.assert_called_once_with(
        to=order.customer_email,
        template="order_confirmation",
        context={"order_id": order.id},
    )
```
