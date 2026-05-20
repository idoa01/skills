# Refactor Candidates

After TDD cycle, look for:

- **Duplication** → Extract method or class
- **Long methods** → Break into private methods (keep tests on public interface)
- **Shallow classes** → Combine or deepen
- **Feature envy** → Move logic to where data lives
- **Primitive obsession** → Introduce pydantic models or value objects
- **Fat `__init__`** → Extract setup into factory or builder
- **Existing code** the new code reveals as problematic

## Python-Specific Refactors

- **Dict soup** → Replace with pydantic model or dataclass
- **Boolean params** → Split into separate methods or use enum
- **God module** → Extract classes with clear boundaries
- **Bare try/except** → Catch specific exceptions, let unexpected ones propagate
- **Class that should be a function** → If it has one public method and no state, make it a function
