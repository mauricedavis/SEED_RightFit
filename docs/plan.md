# SEED RightFit – Implementation Plan & Findings

> **Last Updated:** March 2026  
> **Flow:** Student_Right_Fit_School_Selection_Criteria

---

## Overview

This document captures implementation details, requirements, and findings from the Right Fit Survey and matching solution work.

---

## 1. Right Fit Match Preview – Recount / Refresh Requirements

### Problem Statement

When a student sees the match preview (e.g., 5 colleges matched), goes back to broaden criteria (regions, sizes, test scores, etc.), then clicks **Next** again, the preview did not recalculate. The same match count appeared until the user manually clicked **Recalculate**.

### Root Cause

The Flow screen component `rightFitMatchPreview` was configured with **UseStoredValues** for `inputsOnNextNavToAssocScrn`. When users navigated Previous → edit criteria → Next, Flow passed cached inputs to the LWC instead of fresh values.

### Solution Implemented

1. **Flow setting:** Change the Right Fit Match Preview component’s `inputsOnNextNavToAssocScrn` from `UseStoredValues` to **`ResetValues`** (Flow Builder: “Refresh inputs to incorporate changes elsewhere in the flow”).
2. **Formula_Refresh_Timestamp:** Use a formula that produces a numeric key that changes when the screen is revisited:
   - Date portion: `$Flow.CurrentDate` with `YEAR()`, `MONTH()`, `DAY()` (Date type).
   - Time portion: `TIMEVALUE($Flow.CurrentDateTime)` with `HOUR()`, `MINUTE()`, `SECOND()` (Time type).
3. **LWC:** Removed 4-second polling; rely on Flow’s refreshed inputs and manual **Recalculate** when needed.

---

## 2. Formula_Refresh_Timestamp – Data Type Handling

### Issue

Flow formula functions have strict data types:

- **YEAR()**, **MONTH()**, **DAY()** → require **Date** (not Date/Time).
- **HOUR()**, **MINUTE()**, **SECOND()** → require **Time** (not Date/Time).

### Correct Formula

```
YEAR({!$Flow.CurrentDate}) * 10000000000 + MONTH({!$Flow.CurrentDate}) * 100000000 + DAY({!$Flow.CurrentDate}) * 1000000 + HOUR(TIMEVALUE({!$Flow.CurrentDateTime})) * 10000 + MINUTE(TIMEVALUE({!$Flow.CurrentDateTime})) * 100 + SECOND(TIMEVALUE({!$Flow.CurrentDateTime}))
```

- Use `$Flow.CurrentDate` for date parts (Date type).
- Use `TIMEVALUE($Flow.CurrentDateTime)` for time parts (converts Date/Time → Time).

---

## 3. Flow Metadata API – inputsOnNextNavToAssocScrn Enum

Valid values for `FlowScreenFieldInputsRevisited`:

| Value | Behavior |
|-------|----------|
| `UseStoredValues` | Use cached values when revisiting screen (default). |
| `ResetValues` | Refresh inputs when navigating forward after changes elsewhere. |

---

## 4. Deployment Targets

| Environment | Org | Notes |
|------------|-----|-------|
| Development | `seedfoundation` (mjdavis1@attainpartners.com) | Default org; primary dev/test. |
| Full Sandbox | seedfoundation--fullsb.sandbox.lightning.force.com | Add org if needed: `sf org login web --instance-url https://test.salesforce.com` (sandbox). |
| Production | seedfoundation (or org-specific) | Deploy after validation in sandbox. |

---

## 5. Key Components

| Component | Type | Purpose |
|-----------|------|---------|
| `rightFitMatchPreview` | LWC | Match preview in Right Fit Survey flow; calls `getMatchPreviewByRecordId`. |
| `rightFitMatchDiagnostic` | LWC | Admin simulator for testing match logic. |
| `RightFitMatchService` | Apex | Matching logic; `getMatchPreviewByRecordId`, `getMatchPreviewBySelections`. |
| `Student_Right_Fit_School_Selection_Criteria` | Flow | Right Fit Survey capture flow; includes MatchingPreviewScreen. |

---

## 6. Retrieve & Deploy Commands

**Retrieve from seedfoundation:**
```powershell
cd "c:\Users\MauriceJDavis\SEED_RightFit"
sf project retrieve start --metadata "Flow:Student_Right_Fit_School_Selection_Criteria" --target-org seedfoundation
```

**Deploy to org:**
```powershell
sf project deploy start --target-org seedfoundation
```

**Deploy to full sandbox** (after adding org):
```powershell
sf project deploy start --target-org <fullsb-alias>
```

---

## 7. References

- [docs/BACKGROUND.md](BACKGROUND.md) – Project background and terminology
- [docs/FLOW_CHECKBOX_MAPPING.md](FLOW_CHECKBOX_MAPPING.md) – Checkbox-to-preview mapping for flows
