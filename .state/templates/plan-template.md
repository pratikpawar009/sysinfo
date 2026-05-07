# Implementation Plan: [FEATURE_NAME]

**Feature**: [FEATURE_NUMBER] - [FEATURE_NAME]  
**Specification**: [LINK_TO_SPEC]  
**Status**: Draft  
**Created**: [DATE]  
**Last Updated**: [DATE]

---

## Executive Summary

[Brief 2-3 sentence summary of what will be built and key technical approach]

---

## Technical Context

### Technology Stack
- **Primary Language**: [LANGUAGE_AND_VERSION]
- **Framework/Runtime**: [FRAMEWORK_DETAILS]
- **Build System**: [BUILD_TOOL]
- **Testing Framework**: [TEST_FRAMEWORK]

### Key Technologies & Dependencies
- **[Technology 1]**: [Purpose and version]
- **[Technology 2]**: [Purpose and version]
- **[External Dependency]**: [Purpose and version]

### System Architecture Context
[Where does this feature fit in the overall system? What components does it interact with?]

### Platform/Environment Constraints
- **Target Platforms**: [OS/platforms supported]
- **Minimum Versions**: [Compiler/runtime minimum versions]
- **Platform-Specific Considerations**: [Any platform-specific details]

---

## Constitution Check

**Review Date**: [DATE]  
**Constitution Version**: [VERSION]

### Principle Alignment

**Principle 1: [NAME]**
- ✅ / ⚠️ / ❌ Status
- **Assessment**: [How this feature aligns or conflicts]
- **Mitigation** (if needed): [Steps to ensure compliance]

**Principle 2: [NAME]**
- ✅ / ⚠️ / ❌ Status
- **Assessment**: [How this feature aligns or conflicts]
- **Mitigation** (if needed): [Steps to ensure compliance]

**Principle 3: [NAME]**
- ✅ / ⚠️ / ❌ Status
- **Assessment**: [How this feature aligns or conflicts]
- **Mitigation** (if needed): [Steps to ensure compliance]

**Principle 4: [NAME]**
- ✅ / ⚠️ / ❌ Status
- **Assessment**: [How this feature aligns or conflicts]
- **Mitigation** (if needed): [Steps to ensure compliance]

**Principle 5: [NAME]**
- ✅ / ⚠️ / ❌ Status
- **Assessment**: [How this feature aligns or conflicts]
- **Mitigation** (if needed): [Steps to ensure compliance]

### Gate Evaluation

**Quality Gate**: Constitution compliance is MANDATORY before proceeding.

- [ ] All principles show ✅ or justified ⚠️ with mitigation
- [ ] No ❌ violations unless constitutional amendment is approved
- [ ] Technical approach aligns with project standards

**Gate Status**: ⚠️ BLOCKED / 🟢 PASSED

---

## Phase 0: Research & Discovery

### Research Objectives
1. [Research question or unknown to resolve]
2. [Technology evaluation needed]
3. [Best practice investigation required]

### Research Findings

#### Finding 1: [Topic]
- **Decision**: [What was chosen]
- **Rationale**: [Why this choice was made]
- **Alternatives Considered**: [Other options evaluated]
- **References**: [Links to docs, discussions, benchmarks]

#### Finding 2: [Topic]
- **Decision**: [What was chosen]
- **Rationale**: [Why this choice was made]
- **Alternatives Considered**: [Other options evaluated]
- **References**: [Links to docs, discussions, benchmarks]

### Research Artifacts
- [research.md](./research.md) - Detailed research documentation

---

## Phase 1: Design

### Data Model

[Reference to data-model.md or inline description of key entities and their relationships]

**Key Entities**:
1. **[Entity Name]**
   - Fields: [field list]
   - Relationships: [to other entities]
   - Validation Rules: [constraints]

2. **[Entity Name]**
   - Fields: [field list]
   - Relationships: [to other entities]
   - Validation Rules: [constraints]

**State Transitions**: [If applicable, describe state machine or workflow states]

### Interface Contracts

[List of contracts defined in /contracts/ directory]

**Contract 1: [Name]**
- **Type**: [API/CLI/Protocol/Schema]
- **Location**: [contracts/api.yaml or similar]
- **Purpose**: [What this contract defines]
- **Stability**: [Stable/Evolving/Experimental]

**Contract 2: [Name]**
- **Type**: [API/CLI/Protocol/Schema]
- **Location**: [contracts/schema.json or similar]
- **Purpose**: [What this contract defines]
- **Stability**: [Stable/Evolving/Experimental]

### Component Architecture

```
[ASCII diagram or description of major components and their interactions]

┌──────────────┐
│  Component A │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Component B │
└──────────────┘
```

**Components**:
1. **[Component Name]**
   - Responsibility: [What it does]
   - Dependencies: [What it depends on]
   - Interfaces: [How it's accessed]

2. **[Component Name]**
   - Responsibility: [What it does]
   - Dependencies: [What it depends on]
   - Interfaces: [How it's accessed]

### Design Artifacts
- [data-model.md](./data-model.md) - Detailed entity and relationship definitions
- [contracts/](./contracts/) - Interface contracts and schemas
- [quickstart.md](./quickstart.md) - Developer quickstart guide

### Post-Design Constitution Check

**Re-evaluation Date**: [DATE]

[Repeat constitution check after design decisions are made. Ensure no new violations introduced.]

**Gate Status**: ⚠️ BLOCKED / 🟢 PASSED

---

## Phase 2: Implementation Strategy

### File Changes

**Files to Create**:
- `[path/to/new/file.ext]` - [Purpose]
- `[path/to/another/file.ext]` - [Purpose]

**Files to Modify**:
- `[path/to/existing/file.ext]` - [Changes needed]
- `[path/to/another/file.ext]` - [Changes needed]

**Files to Delete**:
- `[path/to/deprecated/file.ext]` - [Reason for removal]

### Implementation Sequence

**Step 1: [Phase Name]**
- Objective: [What this step accomplishes]
- Files: [Files involved]
- Dependencies: [Prerequisites]
- Validation: [How to verify completion]

**Step 2: [Phase Name]**
- Objective: [What this step accomplishes]
- Files: [Files involved]
- Dependencies: [Prerequisites]
- Validation: [How to verify completion]

**Step 3: [Phase Name]**
- Objective: [What this step accomplishes]
- Files: [Files involved]
- Dependencies: [Prerequisites]
- Validation: [How to verify completion]

### Testing Strategy

**Unit Tests**:
- [Test scenario 1]
- [Test scenario 2]
- Coverage Target: [percentage or specific paths]

**Integration Tests**:
- [Integration scenario 1]
- [Integration scenario 2]

**Platform-Specific Tests**:
- [Platform 1]: [Specific test requirements]
- [Platform 2]: [Specific test requirements]

**Performance Tests**:
- [Performance benchmark 1]
- [Performance benchmark 2]
- Success Criteria: [Specific metrics from spec]

### Rollout Plan

**Development**:
1. [Development step]
2. [Development step]

**Testing**:
1. [Testing phase]
2. [Testing phase]

**Deployment**:
1. [Deployment step]
2. [Deployment step]

---

## Risk Management

### Technical Risks

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|--------|------------|------------|-------|
| [Risk description] | H/M/L | H/M/L | [Mitigation strategy] | [Team/Person] |
| [Risk description] | H/M/L | H/M/L | [Mitigation strategy] | [Team/Person] |

### Contingency Plans

**If [Risk X] occurs**:
- Fallback approach: [Alternative implementation]
- Rollback procedure: [How to undo changes]

---

## Success Metrics

[Map to success criteria from specification]

1. **[Metric from Spec]**: [How we'll measure it]
   - Measurement Tool: [Tool/command]
   - Target: [Specific value]
   - Validation: [How to verify]

2. **[Metric from Spec]**: [How we'll measure it]
   - Measurement Tool: [Tool/command]
   - Target: [Specific value]
   - Validation: [How to verify]

---

## Open Items

- [ ] [Outstanding question or decision]
- [ ] [Dependency waiting on external party]
- [ ] [Item needing clarification]

---

## References

- Specification: [link to spec.md]
- Research: [link to research.md]
- Data Model: [link to data-model.md]
- Contracts: [link to contracts/]
- Constitution: [link to constitution.md]
- [External documentation]
- [Related issues/PRs]

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | [DATE] | [AUTHOR] | Initial plan |
