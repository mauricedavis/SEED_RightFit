# SEED-21: Right Fit Survey Match Preview Refresh Fix

**Use this content to update the JIRA ticket:** [SEED-21](https://attainpartners.atlassian.net/browse/SEED-21)

---

## Summary

Fixed the Right Fit Survey flow so the match preview recalculates when students go back, broaden their criteria, and return—enabling them to reach the required 10+ college matches without manual Recalculate only.

---

## Background

The Right Fit Survey (Flow: *Student_Right_Fit_School_Selection_Criteria*) guides students through college search criteria (GPA, regions, college size, setting, test scores). After they submit, a **Matching Preview** screen shows how many colleges match. Students need **at least 10 matches** to proceed. If they see fewer (e.g., 5), they can click **Previous**, broaden criteria, and click **Next** again.

**Issue:** After going back and changing criteria, the preview did not refresh. The same match count (e.g., 5) appeared, blocking progress until the user manually clicked **Recalculate**.

---

## Root Cause

The Flow’s Right Fit Match Preview LWC was set to **Use values from when the user last visited this screen** (`UseStoredValues`). When users navigated Previous → edit criteria → Next, Flow passed cached input values to the component instead of fresh ones, so the LWC never re-ran the match query.

---

## Solution Implemented

### 1. Flow component setting

- **Flow:** Student_Right_Fit_School_Selection_Criteria  
- **Screen:** MatchingPreviewScreen  
- **Component:** Right Fit Match Preview (c:rightFitMatchPreview)  
- **Change:** Set to **Refresh inputs to incorporate changes elsewhere in the flow** (`ResetValues`)  
- **Effect:** When users navigate forward after editing criteria, Flow re-evaluates inputs and passes updated values to the LWC.

### 2. Formula_Refresh_Timestamp formula

The formula provides a changing value so the LWC knows when to recalculate. Flow formula functions require correct data types:

- **YEAR(), MONTH(), DAY()** require **Date** (not Date/Time)  
- **HOUR(), MINUTE(), SECOND()** require **Time** (not Date/Time)

**Correct formula:**
```
YEAR({!$Flow.CurrentDate}) * 10000000000 + MONTH({!$Flow.CurrentDate}) * 100000000 + DAY({!$Flow.CurrentDate}) * 1000000 + HOUR(TIMEVALUE({!$Flow.CurrentDateTime})) * 10000 + MINUTE(TIMEVALUE({!$Flow.CurrentDateTime})) * 100 + SECOND(TIMEVALUE({!$Flow.CurrentDateTime}))
```

- Use `$Flow.CurrentDate` for date parts  
- Use `TIMEVALUE($Flow.CurrentDateTime)` for time parts

### 3. LWC change

- Removed the 4-second automatic polling (user feedback: annoying)  
- Kept the **Recalculate** button for manual refresh  
- Rely on Flow refresh and formula for automatic recalc when returning to the screen

---

## Artifacts

| Artifact | Location |
|----------|----------|
| Flow | `Student_Right_Fit_School_Selection_Criteria.flow-meta.xml` |
| LWC | `rightFitMatchPreview` (force-app/main/default/lwc/) |
| Apex | `RightFitMatchService` (getMatchPreviewByRecordId) |
| Repo | https://github.com/mauricedavis/SEED_RightFit |

---

## Deployment

- **Org:** seedfoundation (mjdavis1@attainpartners.com)  
- **Full Sandbox:** seed-fullsb (mjdavis1@attainpartners.com.fullsb)  
- **Command:** `sf project deploy start --target-org seedfoundation` (or `seed-fullsb`)

---

## References

- docs/plan.md – Implementation plan and technical details  
- docs/BACKGROUND.md – Right Fit terminology and flow  
- JIRA: SEED-21
