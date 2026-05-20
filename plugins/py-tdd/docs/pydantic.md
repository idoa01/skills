# Pydantic in TDD

## Models as Deep Modules

Pydantic models are natural deep modules — a small interface (field assignments) with complex validation hidden inside:

```python
from pydantic import BaseModel, field_validator
from decimal import Decimal


class Order(BaseModel):
    customer_email: str
    items: list[OrderItem]
    total: Decimal

    @field_validator("items")
    @classmethod
    def must_have_items(cls, v: list[OrderItem]) -> list[OrderItem]:
        if not v:
            raise ValueError("Order must contain at least one item")
        return v

    @field_validator("total")
    @classmethod
    def total_must_be_positive(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Total must be positive")
        return v
```

## Testing Models

Test through the constructor — that's the public interface. Don't test individual validators in isolation:

```python
class TestOrder:
    def test_valid_order(self):
        order = Order(
            customer_email="alice@example.com",
            items=[OrderItem(product_id="abc", quantity=1, price=Decimal("9.99"))],
            total=Decimal("9.99"),
        )

        assert order.customer_email == "alice@example.com"

    def test_rejects_empty_items(self):
        with pytest.raises(ValidationError, match="must contain at least one item"):
            Order(customer_email="alice@example.com", items=[], total=Decimal("9.99"))

    def test_rejects_negative_total(self):
        with pytest.raises(ValidationError, match="must be positive"):
            Order(
                customer_email="alice@example.com",
                items=[OrderItem(product_id="abc", quantity=1, price=Decimal("9.99"))],
                total=Decimal("-1.00"),
            )
```

## Test Data Factories

### With polyfactory (when available in pyproject.toml)

```python
from polyfactory.factories.pydantic_factory import ModelFactory


class OrderFactory(ModelFactory):
    __model__ = Order

    @classmethod
    def build(cls, **kwargs) -> Order:
        defaults = {
            "customer_email": "test@example.com",
            "items": [OrderItemFactory.build()],
            "total": Decimal("9.99"),
        }
        defaults.update(kwargs)
        return super().build(**defaults)


class TestDiscountEngine:
    def test_bulk_discount_applies(self, discount_engine: DiscountEngine):
        order = OrderFactory.build(total=Decimal("100.00"))

        result = discount_engine.calculate(order)

        assert result.discount_amount == Decimal("10.00")
```

### Without polyfactory (manual factories)

```python
def make_order(**overrides) -> Order:
    defaults = {
        "customer_email": "test@example.com",
        "items": [make_order_item()],
        "total": Decimal("9.99"),
    }
    defaults.update(overrides)
    return Order(**defaults)


def make_order_item(**overrides) -> OrderItem:
    defaults = {"product_id": "abc", "quantity": 1, "price": Decimal("9.99")}
    defaults.update(overrides)
    return OrderItem(**defaults)
```

## Models as Interface Contracts

Use pydantic models for input/output at service boundaries:

```python
class CheckoutRequest(BaseModel):
    cart_id: str
    payment_method_id: str


class CheckoutResult(BaseModel):
    order_id: str
    status: OrderStatus
    charged_amount: Decimal


class CheckoutService:
    def __init__(self, payment_client: PaymentClient, cart_repo: CartRepository):
        self._payment = payment_client
        self._cart_repo = cart_repo

    def checkout(self, request: CheckoutRequest) -> CheckoutResult:
        ...
```

This makes tests self-documenting — the model defines exactly what goes in and comes out:

```python
class TestCheckoutService:
    def test_successful_checkout(self, checkout_service: CheckoutService):
        request = CheckoutRequest(cart_id="cart-1", payment_method_id="pm-1")

        result = checkout_service.checkout(request)

        assert result.status == OrderStatus.CONFIRMED
        assert result.charged_amount > Decimal("0")
```

## Guidelines

- Test models through their constructor, not individual validators
- Use `pytest.raises(ValidationError, match=...)` for rejection tests
- Use polyfactory when it's in pyproject.toml, manual factories otherwise
- Models at boundaries make tests readable — you see the full contract
- Don't over-validate — only enforce invariants that are meaningful to the domain
