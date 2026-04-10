---
name: kotlin-spring
description: Code quality rules for Kotlin/Spring Boot projects
---

# Kotlin/Spring Boot Stack Adapter

## Code Quality Rules

These rules are injected into `/tdd-ralph` prompts and `/code-review` checklists.

### Kotlin Functional Style (MANDATORY)
- `val` only (never `var`), immutable collections
- `map`/`filter`/`fold` (never `for`/`while` loops)
- Expression bodies (`=` for single-expression functions)
- Null safety: `?.` `?:` `let` `takeIf` (never `!!`)
- Extension functions over static helpers
- Sealed/data classes for state and DTOs
- Imports at top (never inline fully-qualified names)
- Pure functions where possible (same input → same output)

### Scope Functions
- `let` — transforms value, returns new value
- `run` — executes on receiver using `this`, returns result
- `also` — side effect, returns original
- `apply` — configures object, returns receiver
- If it's a side effect (returns Unit), use plain function call, not `.let`

### SOLID Principles
- **S**: Each function does ONE thing, max 20 lines
- **O**: Extend via new classes, not modification
- **L**: Subtypes substitutable for base types
- **I**: Small, focused interfaces
- **D**: Depend on abstractions (interfaces, sealed classes)

### Clean Code
- Meaningful names (no `data`, `temp`, `x`, `result`)
- No magic numbers or strings — use constants
- No dead code, unused imports, commented-out blocks
- No code duplication (DRY)
- Comments are last resort — prefer better names, extracted functions

### Spring Boot Conventions
- Use `@RequestParam`, `@PathVariable`, `@RequestBody` (Spring MVC)
- NEVER use JAX-RS annotations (`@QueryParam`, `@PathParam`) — silently ignored
- `@Service` for business logic, `@Repository` for data access
- Constructor injection (not field injection)

### RowMapper Convention
- `rs.getLong()`, `rs.getString()` for non-nullable fields
- `rs.getLongOrNull()`, `rs.getStringOrNull()` for nullable fields
- Never use `.takeIf { !rs.wasNull() }` pattern

### Linting
- Run `ktlintCheck` on changed files only
- NEVER run `ktlintFormat` — destroys git history, creates massive diffs
- Fix violations MANUALLY in the specific affected file
- NEVER fix pre-existing violations in unrelated files

### Testing
- Unit tests extend test helpers with auto-registered mocks
- TDD tests are ALWAYS unit tests (10x faster)
- Mock external dependencies
- Integration tests only after unit tests pass
- Test names describe behavior, not implementation

### Compilation Gate
- Always compile main + testFixtures + test source sets before push
- `compileTestFixturesKotlin` catches test helper breaks that `compileKotlin` misses

### Pagination with App-Level Filtering
If filtering happens post-query, NEVER derive `hasMore` from filtered slice size:
```kotlin
// WRONG — silent data loss
val hasMore = filteredItems.size > targetLimit

// CORRECT — based on total count
val totalCount = getTotalCount()
val hasMore = requestedOffset + targetLimit < totalCount
```
