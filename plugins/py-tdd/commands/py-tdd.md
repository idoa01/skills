---
name: py-tdd
description: Test-driven development with red-green-refactor loop in Python. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, asks for test-first development, or mentions pytest.
alwaysApply: false
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal method and tests fail, those tests were testing implementation, not behavior.

See [docs/tests.md](../docs/tests.md) for examples, [docs/mocking.md](../docs/mocking.md) for mocking guidelines, [docs/fixtures.md](../docs/fixtures.md) for pytest fixtures, and [docs/pydantic.md](../docs/pydantic.md) for model testing.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" — treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, method signatures) rather than user-facing behavior
- Tests become insensitive to real changes — they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

When exploring the codebase, use the project's domain glossary so that test names and interface vocabulary match the project's language, and respect ADRs in the area you're touching.

Before writing any code:

- [ ] Check `pyproject.toml` for available test dependencies (polyfactory, freezegun, pytest-asyncio, pytest-mock)
- [ ] Examine existing test structure — follow conventions already in use
- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] Identify opportunities for [deep modules](../docs/deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](../docs/interface-design.md)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

### 2. Test Layout

Detect the project's existing test structure and follow it. If no tests exist yet, default to:

```
tests/
├── conftest.py
├── unit/
│   └── ...
├── integration/
│   └── ...
└── e2e/
    └── ...
```

### 3. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet — proves the path works end-to-end.

### 4. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 5. Refactor

After all tests pass, look for [refactor candidates](../docs/refactoring.md):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Adding tests to existing code (test-after)

Sometimes the code already exists and works — you skipped TDD, or you're backfilling tests
flagged by [`/audit-tests`](audit-tests.md). The standard loop assumes the test fails first,
but here the behavior is already implemented, so a correct test **passes the moment you
write it**. That removes the RED step — and RED is what proves the test can actually fail.
A test you never saw fail might be passing for the wrong reason (vacuous assertion,
tautology, asserting nothing). That's the same weak-test trap TDD exists to avoid.

First, split the work by *why* the behavior is untested:

- **Missing or broken behavior** — the code doesn't do it yet, or does it wrong. This is a
  genuine RED. Use the normal red→green loop above; do **not** use the test-after recipe.
- **Already-working behavior, just untested** — the code is correct, only the test is
  missing. Use the test-after recipe below.

**Test-after recipe — recover RED by breaking the code on purpose.** For each behavior, one
at a time:

```
1. Write ONE behavior test through the public interface.
2. Run it — it passes (expected; the code already works).
3. CONFIRM IT CAN FAIL: temporarily break the implementation it covers
   (comment out the `raise`, flip a condition, return a wrong value).
4. Run it — it must now FAIL, and fail for the reason you expect.
   - Still passes? The test is vacuous. Strengthen the assertion and repeat from 3.
5. Revert the break. Run it — green again.
6. Move to the next behavior.
```

Step 3–4 is the whole point: it's poor-man's mutation testing, and it's what makes a
test-after test trustworthy. Never skip it. Same rules as the normal loop otherwise — one
behavior at a time, public interface only, no bulk test-writing.

## Reference files (load as needed)

- **Tests** — good vs bad test examples → [docs/tests.md](../docs/tests.md)
- **Mocking** — when/how to mock, Protocols → [docs/mocking.md](../docs/mocking.md)
- **Fixtures** — pytest fixtures, DI patterns → [docs/fixtures.md](../docs/fixtures.md)
- **Pydantic** — model testing, factories → [docs/pydantic.md](../docs/pydantic.md)
- **Interface design** — testability principles → [docs/interface-design.md](../docs/interface-design.md)
- **Deep modules** — small interface, deep impl → [docs/deep-modules.md](../docs/deep-modules.md)
- **Refactoring** — post-TDD refactor candidates → [docs/refactoring.md](../docs/refactoring.md)

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```
