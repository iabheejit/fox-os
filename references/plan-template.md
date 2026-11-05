# Milestone Plan Template

Use this template for every new plan document at `.claude/plans/milestone-{N}-{slug}.md`.

```markdown
# Milestone {N}: {Name}
**Created**: {date} | **Target**: {date} | **Project**: {project name or area}

## Sprint (team mode only — delete when solo)
**Sprint goal**: {one sentence the product owner would recognise}
**Dates**: {start} → {end}
**Backlog** (ordered; top items are committed, the rest are stretch):
- [ ] {story / task} — {owner} — {estimate}
- [ ] …

## Objective
{One sentence: what this milestone delivers and why it matters}

## Acceptance Criteria
1. {Specific, verifiable criterion — must be testable}
2. {Specific, verifiable criterion}
...

## Approach
{Key technical decisions, dependencies, risks, and tradeoffs}

## Files Affected
{List of files/modules to create or modify}

## Tests Required
{What tests verify each acceptance criterion is met}

## Out of Scope
{What this milestone explicitly does NOT include — prevents scope creep}

## Dependencies
{What must exist before this work can begin}

## Design Considerations
{Optional if no UI/UX involved. If there is: which user flows are in scope? What are the primary actions? Known accessibility or mobile constraints? Give Divya enough signal to review.}

## Operational Considerations
{Optional if no deployment changes. If there are: environment variables added/changed? New infrastructure dependencies? Health check or logging changes? Give Sanjay enough signal to review.}

## Fundability / Demo Value
{Optional but encouraged: how does this milestone serve the narrative for funders, investors, or users?}
```
