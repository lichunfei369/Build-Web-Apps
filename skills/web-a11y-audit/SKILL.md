---
name: web-a11y-audit
description: "Accessibility audit for web UIs — keyboard navigation, focus order, ARIA roles/names, color contrast, headings/landmarks, form labels, and screen-reader semantics. Use when the user asks to check or improve accessibility / a11y / WCAG compliance, or wants a UI usable without a mouse. Uses agent-browser's accessibility snapshot plus an injected axe-core pass."
---

# Web A11y Audit

Audit a rendered UI for accessibility. Browser backend is the **`agent-browser` CLI**. Two complementary signals:

1. **Accessibility snapshot (free):** `agent-browser snapshot` already returns the accessibility tree with roles/names and `@e` refs — use it to judge semantics, names, and structure directly.
2. **axe-core deep pass (best-effort):** inject `scripts/inject-axe.js` (via agent-browser's init-script / eval) to run a WCAG ruleset and collect violations. If injection isn't supported on the installed version, fall back to Playwright + `@axe-core/playwright`, or do the manual checks below.

Confirm flags with `agent-browser --help`.

## What to check

### Automated (axe-core)
- Run axe against the page (and after opening menus/modals — audit each significant state).
- Group violations by impact (critical / serious / moderate). Common hits: missing form labels, insufficient contrast, missing `alt`, invalid ARIA, missing document language, duplicate ids, non-unique landmarks.

### Keyboard & focus (manual, via snapshot + key events)
- Tab order is logical and matches visual order; nothing important is unreachable.
- Visible focus indicator on every interactive element.
- No keyboard traps; `Esc` closes modals/menus; focus moves into an opened dialog and returns on close.
- Custom controls expose a role + name + state (not a bare `<div onClick>`).

### Structure & semantics (from the snapshot)
- One `h1`, logical heading hierarchy, landmark regions (`main`, `nav`, …).
- Images have meaningful `alt` (or empty `alt` if decorative).
- Form fields have associated labels; errors are announced.
- Color is not the only means of conveying information; contrast meets WCAG AA.

## Output

Report: **violation table** (rule, impact, element `@ref`, fix), a short **keyboard/focus findings** list, and the **prioritized fixes** (critical first) with the file/component to touch. Note that automated tools catch ~30–40% of issues — call out what still needs human/AT verification. Close the session when done.
