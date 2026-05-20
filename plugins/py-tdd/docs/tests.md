# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

### Sync

```python
# GOOD: Tests observable behavior through the class interface
class TestCheckout:
    def test_user_can_checkout_with_valid_cart(self, checkout_service: CheckoutService):
        cart = Cart()
        cart.add(Product(name="Widget", price=Decimal("9.99")))

        result = checkout_service.checkout(cart, payment_method)

        assert result.status == OrderStatus.CONFIRMED
```

### Async

```python
class TestCheckout:
    @pytest.mark.asyncio
    async def test_user_can_checkout_with_valid_cart(self, checkout_service: AsyncCheckoutService):
        cart = Cart()
        cart.add(Product(name="Widget", price=Decimal("9.99")))

        result = await checkout_service.checkout(cart, payment_method)

        assert result.status == OrderStatus.CONFIRMED
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```python
# BAD: Tests implementation details
class TestCheckout:
    def test_checkout_calls_payment_service_process(self, mocker):
        mock_payment = mocker.patch("app.services.payment_service.process")
        cart = Cart()
        cart.add(Product(name="Widget", price=Decimal("9.99")))

        checkout(cart, payment_method)

        mock_payment.assert_called_once_with(Decimal("9.99"))
```

Red flags:

- Mocking internal collaborators
- Testing private methods (`_calculate_total`)
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```python
# BAD: Bypasses interface to verify
class TestUserCreation:
    def test_create_user_saves_to_database(self, db_session):
        user_service.create_user(name="Alice")

        row = db_session.execute(text("SELECT * FROM users WHERE name = 'Alice'")).fetchone()
        assert row is not None

# GOOD: Verifies through interface
class TestUserCreation:
    def test_create_user_makes_user_retrievable(self, user_service: UserService):
        user = user_service.create_user(name="Alice")

        retrieved = user_service.get_user(user.id)
        assert retrieved.name == "Alice"
```
