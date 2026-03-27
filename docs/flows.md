# Execution Flows

## Planning Pipeline

The primary flow triggered by `/snoodles:plan <task>`.

```mermaid
flowchart TD
    user[User describes task] --> dp[derive-prompt]
    dp --> clarify{Needs clarification?}
    clarify -->|yes, max 3 questions| dp
    clarify -->|no| refined[Refined prompt]
    refined --> bs[brainstorm]
    bs --> explore[Explore: fill dimensions table\n≤15 tool uses]
    explore --> scope{Multi-system?}
    scope -->|yes| decompose[Flag for decomposition]
    decompose --> bs
    scope -->|no| questions[Design questions\none at a time]
    questions --> approaches[Propose ≤3 approaches]
    approaches --> plan[Write phased plan doc]
    plan --> approve{User approves?}
    approve -->|no| plan
    approve -->|yes| exec[execute]

    style dp fill:#e1f5fe
    style bs fill:#e8f5e9
    style exec fill:#fff3e0
```

## Phase Execution

How `execute` dispatches parallel agents per phase.

```mermaid
flowchart TD
    start[Read plan doc] --> mode{Validation mode?}
    mode -->|between phases| bp[Between-phases mode]
    mode -->|end only| eo[End-only mode]
    bp --> phase
    eo --> phase

    subgraph phase[Per Phase]
        dispatch[Dispatch all tasks in parallel\none agent per task\nisolation: worktree] --> collect[Collect results]
        collect --> merge[Merge worktree branches]
        merge --> conflicts{Merge conflicts?}
        conflicts -->|yes| resolve[Resolve] --> tests
        conflicts -->|no| tests[Run test suite]
        tests --> pass{Tests pass?}
        pass -->|no| fix[Fix failures] --> tests
        pass -->|yes| review_check{Between-phases mode?}
        review_check -->|yes| code_review[Code review on merged diff]
        review_check -->|no| next
        code_review --> issues{Critical/Important?}
        issues -->|yes| fix_issues[Fix issues] --> code_review
        issues -->|no| next[Next phase]
    end

    next --> more{More phases?}
    more -->|yes| phase
    more -->|no| final

    subgraph final[Final Validation]
        run_tests[Run test suite] --> spec[Spec compliance review\nwhole workload vs plan]
        spec --> spec_ok{Spec compliant?}
        spec_ok -->|no| fix_spec[Fix gaps] --> spec
        spec_ok -->|yes| quality[Code quality review]
        quality --> quality_ok{Issues?}
        quality_ok -->|yes| fix_quality[Fix issues] --> quality
        quality_ok -->|no| finish_skill[finish skill]
    end

    style dispatch fill:#fff3e0
    style spec fill:#fce4ec
    style finish_skill fill:#e8f5e9
```

## Agent Lifecycle

What happens inside each dispatched implementer agent.

```mermaid
flowchart TD
    receive[Receive task packet] --> unclear{Anything unclear?}
    unclear -->|yes| ask[Report NEEDS_CONTEXT\nwait for answer]
    ask --> receive
    unclear -->|no| implement[Implement task]
    implement --> test[Run verification command]
    test --> self_review[Self-review checklist\n5 checks]
    self_review --> found{Issues found?}
    found -->|yes| fix_self[Fix before reporting] --> test
    found -->|no| report{Can do it right?}
    report -->|yes| done[Report DONE or\nDONE_WITH_CONCERNS]
    report -->|no| blocked[Report BLOCKED]

    style blocked fill:#ffcdd2
    style done fill:#c8e6c9
```

## Hidden Flows

Processes that run automatically without Claude's involvement.

### Session Injection

```mermaid
flowchart LR
    start[Session starts] --> hook[SessionStart hook fires]
    hook --> read[Read entry/SKILL.md\n+ insights/SKILL.md]
    read --> escape[Escape for JSON]
    escape --> inject[Inject as additional_context\nin EXTREMELY_IMPORTANT tags]
    inject --> session[Claude has routing table\n+ behavioral rules]
```

### PostToolUse Validation

```mermaid
flowchart TD
    edit[Claude edits a file] --> hook[PostToolUse fires\n3 hooks run in parallel]

    hook --> ts{.ts/.tsx?}
    hook --> py{.py?}
    hook --> go{.go?}

    ts -->|yes| tsconfig{tsconfig.json exists?}
    ts -->|no| skip1[Exit 0 silent]
    tsconfig -->|yes| tsc[tsc --noEmit]
    tsconfig -->|no| skip2[Exit 0 silent]

    py -->|yes| pyroot{pyproject.toml exists?}
    py -->|no| skip3[Exit 0 silent]
    pyroot -->|yes| pyright[pyright or mypy]
    pyroot -->|no| skip4[Exit 0 silent]

    go -->|yes| gomod{go.mod exists?}
    go -->|no| skip5[Exit 0 silent]
    gomod -->|yes| govet[go vet]
    gomod -->|no| skip6[Exit 0 silent]

    tsc --> tsc_ok{Pass?}
    tsc_ok -->|yes| silent1[Exit 0 silent\n0 tokens]
    tsc_ok -->|no| report1[Inject errors into context]

    pyright --> py_ok{Pass?}
    py_ok -->|yes| silent2[Exit 0 silent\n0 tokens]
    py_ok -->|no| report2[Inject errors into context]

    govet --> go_ok{Pass?}
    go_ok -->|yes| silent3[Exit 0 silent\n0 tokens]
    go_ok -->|no| report3[Inject errors into context]

    style silent1 fill:#c8e6c9
    style silent2 fill:#c8e6c9
    style silent3 fill:#c8e6c9
    style report1 fill:#ffcdd2
    style report2 fill:#ffcdd2
    style report3 fill:#ffcdd2
```

## Decision Points

Critical gates where the flow branches based on user input or system state.

```mermaid
flowchart TD
    subgraph planning[Planning Decisions]
        d1{Scope: single or multi-system?}
        d1 -->|multi| decompose[Decompose into sub-projects first]
        d1 -->|single| proceed[Continue to approaches]
    end

    subgraph execution[Execution Decisions]
        d2{Validation mode?}
        d2 -->|between phases| careful[Review after each phase merge]
        d2 -->|end only| fast[Review once at end]

        d3{Agent reports BLOCKED}
        d3 --> provide[Provide context, re-dispatch]

        d4{3+ fix attempts failed}
        d4 --> arch[Question architecture\nDiscuss before more fixes]
    end

    subgraph completion[Completion Decisions]
        d5{Finish options}
        d5 -->|1| merge[Merge locally]
        d5 -->|2| pr[Push + create PR]
        d5 -->|3| keep[Keep branch as-is]
        d5 -->|4| discard[Discard — requires typed confirm]
    end

    subgraph model[Model Selection]
        d6{Task complexity?}
        d6 -->|mechanical| haiku[haiku]
        d6 -->|moderate| sonnet[sonnet]
        d6 -->|complex| opus[opus]
    end
```

## Behavioral Rules Flow

How `insights` rules interact with other skills.

```mermaid
flowchart TD
    subgraph always[Always Active — Injected Every Session]
        honesty[Epistemic Honesty\nadmit gaps, cite sources, quote first]
        eng[Over-Engineering\nsimplest first, earn abstractions, prefer stdlib]
        action[Bias Toward Action\nexecute don't deliberate, trust verified, ask before thrashing]
        feedback[Receiving Feedback\nverify before implementing, push back, no performative agreement]
        verify_edits[Verify Edits\nhooks handle build validation, only run tests explicitly]
    end

    action -->|"can't find in 5 tool uses"| ask_user[Ask user for path]
    action -->|"agent verified it"| no_reread[Don't re-read]
    verify_edits -->|"hook reports error"| fix[Claude fixes the error]
    verify_edits -->|"hook silent"| continue[Claude continues — 0 tokens spent]
    feedback -->|"reviewer wrong"| pushback[Push back with evidence]
```
