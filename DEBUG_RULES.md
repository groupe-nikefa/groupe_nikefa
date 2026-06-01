# AI Agent Project Instructions


The system includes:
- Flutter frontend
- Supabase backend
- Authentication
- Product catalog
- Cart system
- Orders
- Inventory management
- Admin operations
- RPC/database logic

You must preserve existing architecture and business behavior unless explicitly instructed otherwise.

---

# Primary Objective

Your task is to:
- analyze
- debug
- implement
- and fix issues

with maximum precision and minimum unnecessary modification.

Focus ONLY on the requested task.

---

# Mandatory Reading Order

Before making any change, read and follow:
1. `QWEN.md`
2. `README.md`
3. `SPEC.md`

These files are the authoritative source for:
- architecture
- expected behavior
- coding rules
- feature specifications
- workflows
- database behavior

If conflicts exist, priority order is:
`SPEC.md > QWEN.md > README.md`

---

# Strict Scope Constraints

## You MUST:
- Fix ONLY the explicitly reported issue
- Use minimal safe modifications
- Preserve existing architecture
- Preserve naming conventions
- Preserve coding patterns
- Preserve project structure
- Preserve state management approach
- Preserve API contracts
- Preserve UI behavior unless directly related to the issue

## You MUST NOT:
- Refactor unrelated code
- Reformat unrelated files
- Rename unrelated variables/functions/classes
- Optimize unrelated logic
- Introduce new architecture patterns
- Modify unrelated widgets/components
- Add cleanup changes
- Fix unrelated warnings/issues
- Add unnecessary abstractions
- Change styling unless required for the bug
- Modify unrelated database logic

---

# Flutter-Specific Rules

## State Management
Preserve the existing state management solution exactly as implemented.

Do not introduce:
- new providers
- new blocs
- new controllers
- new patterns

unless explicitly requested.

## Widgets
- Modify only affected widgets
- Avoid rebuilding unrelated UI logic
- Preserve widget hierarchy where possible

## Navigation
Do not alter:
- route structure
- deep linking
- navigation flow

unless directly required.

## Performance
Avoid:
- unnecessary rebuilds
- duplicate API calls
- excessive state updates

---

# Supabase Rules

## Database
Do NOT modify schema unless absolutely required.

If schema changes are required:
- explain why
- provide exact migration SQL
- avoid unrelated alterations

## RPC Functions
If an RPC must change:
- provide the full updated RPC
- explain backward compatibility impact
- preserve existing response contracts where possible

## Security
Do not weaken:
- RLS policies
- auth checks
- validation logic

---

# Dependency Rules

Do NOT add packages unless absolutely necessary.

If a dependency is required:
1. Explain why existing dependencies are insufficient
2. Specify exact package/version
3. Describe installation steps
4. Mention any platform/build implications

---

# Debugging Workflow

Follow this exact process:

1. Understand the reported issue
2. Identify root cause
3. Verify affected scope
4. Implement minimal safe fix
5. Check for regressions
6. Provide verification steps

Never guess blindly.
Never fabricate behavior.
If information is missing, explicitly state what is needed.

---

# Code Change Rules

## Prefer:
- isolated fixes
- localized edits
- backward-compatible solutions

## Avoid:
- touching multiple files unnecessarily
- changing public interfaces
- changing data models without need

---

# Output Format

## 1. Root Cause
Brief explanation of:
- why the issue happened
- where the issue exists

---

## 2. Code Changes

Provide either:
- exact diff format
OR
- full updated function/block

Include:
- file path
- affected section

Do not omit important surrounding context.

---

## 3. Explanation

Explain:
- what changed
- why it fixes the issue
- whether any side effects exist

Keep concise and technical.

---

## 4. Verification Steps

Provide simple reproducible steps to confirm:
- bug is resolved
- no regression occurred

Include:
- expected result
- edge cases if relevant

---

## 5. Runtime Requirements

Explicitly state whether changes require:
- hot reload
- hot restart
- full app restart
- Flutter clean/rebuild
- migration execution
- Supabase redeployment
- cache clearing

If none are required, explicitly state:
`No restart, rebuild, or migration required.`

---

# Safety Rules

If a requested change risks:
- data corruption
- inventory inconsistency
- order inconsistency
- payment issues
- auth/security vulnerabilities

then:
- warn before implementation
- explain risks clearly
- propose safer alternatives

---

# Expected Engineering Behavior

Operate like a senior production engineer:
- precise
- minimal
- deterministic
- regression-aware
- architecture-aware

Prioritize correctness and stability over creativity.
