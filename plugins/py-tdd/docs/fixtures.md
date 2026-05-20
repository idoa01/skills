# Pytest Fixtures

Fixtures handle test setup, dependency injection, and teardown.

## Scope and Placement

- **`conftest.py`** — shared fixtures visible to all tests in the directory and below
- **Test module** — fixtures used by a single module only
- **Scope** — use `function` (default) unless setup is expensive, then `session` or `module`

## Dependency Injection in Tests

Use fixtures to inject services with fake boundaries:

```python
# conftest.py
import pytest


@pytest.fixture
def fake_payment_client() -> FakePaymentClient:
    return FakePaymentClient(default_result=PaymentResult(status="success"))


@pytest.fixture
def order_service(fake_payment_client: FakePaymentClient) -> OrderService:
    return OrderService(payment_client=fake_payment_client)
```

```python
# test_orders.py
class TestOrderProcessing:
    def test_successful_checkout(self, order_service: OrderService):
        cart = Cart()
        cart.add(Product(name="Widget", price=Decimal("9.99")))

        result = order_service.checkout(cart)

        assert result.status == OrderStatus.CONFIRMED
```

## Async Fixtures

```python
@pytest.fixture
async def async_order_service(fake_payment_client: FakeAsyncPaymentClient) -> AsyncOrderService:
    return AsyncOrderService(payment_client=fake_payment_client)
```

## Database Fixtures

When using a test database, manage transactions per test:

```python
@pytest.fixture
def db_session(engine: Engine):
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def user_service(db_session: Session) -> UserService:
    return UserService(session=db_session)
```

## Factory Fixtures

Create fixtures that return factory callables for flexible test data:

```python
@pytest.fixture
def make_product():
    def _make(name: str = "Widget", price: Decimal = Decimal("9.99")) -> Product:
        return Product(name=name, price=price)
    return _make


class TestCart:
    def test_total_sums_products(self, make_product):
        cart = Cart()
        cart.add(make_product(price=Decimal("10.00")))
        cart.add(make_product(price=Decimal("5.00")))

        assert cart.total == Decimal("15.00")
```

## Guidelines

- Fixtures should be **minimal** — only set up what the test needs
- Name fixtures after what they provide, not what they do (`order_service`, not `setup_order_service`)
- Avoid deeply nested fixture chains — if you need 5 fixtures to build one thing, your production code may have too many dependencies
- Use `yield` for teardown, not separate teardown functions
- Prefer function scope unless startup cost forces wider scope
