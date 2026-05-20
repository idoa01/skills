# Interface Design for Testability

Good interfaces make testing natural:

## 1. Accept dependencies, don't create them

```python
# Testable — dependencies injected via constructor
class OrderService:
    def __init__(self, payment_client: PaymentClient, inventory: InventoryClient):
        self._payment = payment_client
        self._inventory = inventory


# Hard to test — creates its own dependencies
class OrderService:
    def __init__(self):
        self._payment = StripeClient(os.environ["STRIPE_KEY"])
        self._inventory = WarehouseApi(os.environ["WAREHOUSE_URL"])
```

## 2. Return results, don't produce side effects

```python
# Testable — returns a value you can assert on
class DiscountCalculator:
    def calculate(self, cart: Cart) -> Discount:
        ...


# Hard to test — mutates input, nothing to assert on directly
class DiscountCalculator:
    def apply(self, cart: Cart) -> None:
        cart.total -= self._compute_discount(cart)
```

## 3. Use Protocols for boundary contracts

```python
from typing import Protocol


class EmailSender(Protocol):
    def send(self, to: str, subject: str, body: str) -> None: ...


class AsyncEmailSender(Protocol):
    async def send(self, to: str, subject: str, body: str) -> None: ...
```

Protocols give you:
- Type checking without inheritance
- Any object satisfying the shape works (duck typing made explicit)
- Easy to create fakes in tests — no base class needed

## 4. Small surface area

- Fewer public methods = fewer tests needed
- Fewer constructor params = simpler test setup
- One responsibility per class = one reason to change

```python
# GOOD: One focused class
class CartPricer:
    def total(self, cart: Cart) -> Decimal: ...


# BAD: God class with sprawling interface
class CartManager:
    def add_item(self, item: Item) -> None: ...
    def remove_item(self, item_id: str) -> None: ...
    def calculate_total(self) -> Decimal: ...
    def apply_coupon(self, code: str) -> None: ...
    def checkout(self) -> Order: ...
    def send_receipt(self) -> None: ...
```

## 5. Separate construction from behavior

Use a factory or composition root to wire up dependencies. Classes should not know how to build their collaborators:

```python
# Composition root — wires everything together
def create_order_service(settings: Settings) -> OrderService:
    payment = StripeClient(settings.stripe_key)
    inventory = WarehouseClient(settings.warehouse_url)
    return OrderService(payment_client=payment, inventory=inventory)


# In tests — swap boundaries with fakes
def make_order_service(
    payment: PaymentClient | None = None,
    inventory: InventoryClient | None = None,
) -> OrderService:
    return OrderService(
        payment_client=payment or FakePaymentClient(),
        inventory=inventory or FakeInventoryClient(),
    )
```
