# Copilot Instructions

- Inspect relevant existing files before modifying code.
- Follow the existing architecture, Flutter conventions, and Dart style. See [`AGENTS.md`](../AGENTS.md) for project context.
- Reuse existing widgets, utilities, and the `Api` client whenever possible.
- Avoid unnecessary duplication, dependencies, refactoring, or architectural changes.
- Preserve existing functionality unless the task explicitly requires a change.
- Trace dependencies and possible side effects before changing shared files or API contracts.
- Never overwrite user changes or delete files without a clear reason.
- Never expose secrets or modify environment configuration without authorization.
- Run relevant tests, linting, or build checks when available; distinguish verified checks from unverified assumptions.
- Explain the purpose of significant changes and list all modified files.
- If requirements are ambiguous, inspect the codebase first and ask for clarification when necessary.
- Never claim that a feature, test, or command works unless it has been verified.