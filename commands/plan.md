---
description: "Start the planning flow: derive-prompt → brainstorm → execute. Use with a task description."
argument-hint: "<task description>"
---

You MUST complete these steps in order. Do not skip any step.

**Step 1:** Invoke the `snoodles:derive-prompt` skill with the user's task description. Follow it to extract and refine intent. If it needs clarification, let it ask (max 3 questions).

**Step 2:** IMMEDIATELY after derive-prompt produces the refined prompt — in the same turn, without waiting for user input — invoke the `snoodles:brainstorm` skill. Pass it the refined prompt. Follow it to explore context, design, and produce a phased plan doc.

**Step 3:** Once the user approves the plan, invoke the `snoodles:execute` skill. Follow it to dispatch parallel agents.

Start now with Step 1.
