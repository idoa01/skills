# Deep Modules

From "A Philosophy of Software Design":

**Deep module** = small interface + lots of implementation

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid)

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

## In Python Classes

```python
# DEEP: Simple interface, complex behavior hidden inside
class PricingEngine:
    def __init__(self, rules: list[PricingRule]):
        self._rules = rules

    def calculate(self, cart: Cart) -> PricingResult:
        """Single method hides rule evaluation, stacking, conflicts, rounding."""
        ...


# SHALLOW: Interface mirrors implementation, caller must orchestrate
class PricingEngine:
    def get_applicable_rules(self, cart: Cart) -> list[PricingRule]: ...
    def evaluate_rule(self, rule: PricingRule, cart: Cart) -> Decimal: ...
    def resolve_conflicts(self, discounts: list[Decimal]) -> Decimal: ...
    def apply_rounding(self, amount: Decimal) -> Decimal: ...
```

## In Modules

Modules can also be deep or shallow:

```python
# DEEP: Module exposes one function, hides complexity
# pricing/__init__.py
from .engine import calculate_price  # single public function

# SHALLOW: Module exposes everything, forces caller to understand internals
# pricing/__init__.py
from .rules import get_rules, evaluate_rule
from .conflicts import resolve
from .rounding import apply_rounding
```

When designing interfaces, ask:

- Can I reduce the number of public methods?
- Can I simplify the parameters?
- Can I hide more complexity inside the class?
- Does the caller need to understand internal steps, or just the result?
