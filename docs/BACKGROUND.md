# Project Background

> **Source:** [CMT Platform Training](https://attainpartners.atlassian.net/wiki/spaces/SEED/pages/1758035969/CMT+Platform+Training)

---

## Overview

SEED Right Fit is a college matching solution that helps students find schools that align with their preferences (GPA, location, size, test scores, etc.). Counselors review and curate the matched school lists before students access them in the SEED Right Fit Community portal.

---

## Key Terminology

| Term | Definition |
|------|------------|
| CMT | College Match Tool / CMT Platform |
| SEED | SEED Foundation (organization) |
| Right Fit | College matching based on student criteria vs. school attributes |
| Student Match Criteria | Record capturing student's preferences from the Right Fit Survey |
| Student Right Fit Lists | Records linking a student to each matched school |
| Right Fit Progress | Contact field tracking workflow stage (Not Started, Match Criteria Submitted, Counselor Reviewed) |

---

## Right Fit Matching Solution

The match occurs when the student's "wish list" of attributes is compared against Right Fit–rated schools (Accounts) in Salesforce.

**Student attributes collected in the Right Fit Survey:**

- GPA
- Location (e.g., Southeast, Far West, New England, Southwest)
- College Setting (Rural, Town, Suburban, Urban, Any/All)
- College Size (Small, Medium, Large)
- ACT
- SAT Math
- SAT Verbal
- Test Scores Optional Schools

---

## End-to-End Flow

1. **Account creation** — Student gets login to SEED Right Fit Community; student and counselor are notified.
2. **Profile completion** — Student fills out College Match - Right Fit Profile; `Student Match Criteria` record is created.
3. **Automation** — Contact `Right Fit Progress` is set to "Match Criteria Submitted"; counselor is notified.
4. **Matching** — Flow matches student criteria against schools (Accounts); creates `Student Right Fit Lists` for each match.
5. **Counselor review** — Counselor reviews lists, adds/removes schools, then sets `Right Fit Progress` to "Counselor Reviewed."
6. **Student notification** — Email sent to student with link to SEED Right Fit Community.
7. **Student actions** — Student views list, removes/approves schools, adds feedback, marks application status per school.

---

## Automations (Record-Triggered Flows)

### Student Right Fit Email Alert

- **Trigger:** Contact updated with `Right Fit Progress` = "Counselor Reviewed"
- **Actions:** (1) Email student that list is ready with portal link; (2) Chatter post on Contact record.

### New Task When Student Match Criteria Submitted

- **Trigger:** `Student Match Criteria` record created or updated (student completes Right Fit Survey)
- **Action:** Creates Task for assigned Counselor.

### Student Match Criteria - Creating Right Fit Match Records

- **Trigger:** `Student Match Criteria` record
- **Action:** Matches criteria against Accounts; creates `Student Right Fit Lists`.

### Student Match Criteria - Right Fit Student Match Criteria Capture

- **Trigger:** Screen flow for capturing Right Fit Survey responses.

---

## Key Objects

| Object | Purpose |
|--------|---------|
| Contact | Student record; includes Right Fit Progress, Counselor assignment |
| Account | Schools/colleges with Right Fit attributes |
| Student Match Criteria | Student preferences from Right Fit Survey |
| Student Right Fit Lists | Student–school match records |

### Student Match Criteria — Field Schema (API Reference)

**Object:** `Student_Match_Criteria__c`

**Location (region checkboxes):** `Far_West__c`, `Great_Lakes__c`, `Mid_East__c`, `New_England__c`, `Plains__c`, `Rocky_Mountains__c`, `Southeast__c`, `Southwest__c` — Do not use `College_Location__c`.

**College Setting:** `Rural__c`, `Town__c`, `Suburban__c`, `Urban__c`

**College Size:** `Small_Less_than_5_000_Students__c`, `Medium_5_000_to_15_000_Students__c`, `Large_15_000_Students__c` — Do not use deprecated `College_Size__c`.

**GPA:** `Low_GPA_of_Accepted_Students__c`, `High_GPA_Accet__c` (picklists)

**Test scores:** `ACT_Score_Low__c`, `ACT_Composite_Score__c`, `SAT_Math_Low__c`, `SAT_Math_High__c`, `SAT_Verbal_Low__c`, `SAT_Verbal_High_Score__c` (picklists), `Test_Score_Optional_Schools__c` (checkbox)

**Other:** `Student__c` (Lookup Contact), `College_Major_First_Choice__c` (Lookup College Major), `Preferred_Major__c` (Text), `Any_All_no_preference__c` (Checkbox)

### Account (College) — Matching Fields

**Object:** `Account` | **RecordType:** College (`RecordType.DeveloperName = 'College'`)

**Location:** `Geographical_Region__c` (string). Canonical values from College Results Online `Region__c`: Far West, Rocky Mountains, Southeast, Mid East, Southwest, Plains, Great Lakes, New England.

**College Setting:** `College_Setting__c` (string) — equals Student Match Criteria value

**College Size:** `College_Size_Formula__c` — values "Small" (&lt;5K), "Medium" (5K–15K), "Large" (≥15K) from `Number_of_students__c`

**GPA:** `Median_GPA__c`

**Test scores:** `Median_ACT_Composite__c`, `Median_SAT_Math__c`, `Median_SAT_Verbal__c`, `SAT_Math_25th_Percentile_Score__c`, `SAT_Math_75th_Percentile_Score__c`, `SAT_Evidnce_Based_Reading_Writing_25th__c`, `SAT_Evidnce_Based_Reading_Writing_75th__c`

**Test optional:** `Test_Scores_Optional__c` (boolean)

**Display filter:** `Display_in_SEED_Community__c`, `Exclude_from_community__c`

**Experience Cloud:** Capture flow runs in SEED Right Fit Community via authenticated user logins. LWC and Apex must be exposed to the Experience Cloud site.

**Match feedback threshold:** 10+ matches → proceed to congrats; 0–9 matches → block, show suggestions, allow back to edit (choices saved in flow variables).

### Flow Matching Logic (Get Matching Schools)

**Flow:** Automation - Student Match Criteria - Creating Right Fit Match Records

**Logic:** `(1 OR 2) AND 3 AND 4 AND ((5 AND 6 AND 7 AND 8) OR (9 AND 10) OR 23) AND (11 OR 12 OR ... OR 23)`

- **1 OR 2:** Right Fit Match Color Automatic = Yellow or Green (matchable)
- **3 AND 4:** Median GPA within [GPAMatchLow, GPAHighMatch] — GPA picklist maps to `Median_GPA__c`
- **(5–8) OR (9–10) OR 23:** SAT Math+Verbal range OR ACT Composite range OR Test Scores Optional = true
- **11–18:** `Geographical_Region__c` Equals FarWest, RockyMountains, Southeast, MidEast, Southwest, Plains, GreatLakes, NewEngland
- **19–21:** `College_Size_Formula__c` Equals SizeSmall, SizeMedium, SizeLarge
- **22:** `College_Setting__c` Equals Student Match Criteria `College_Setting__c`

---

## User Roles & Permissions

**Counselors**

- Profile: "CoPilot: College Success Program Staff"
- Permissions defined by Profile + Permission Sets
- Can review Right Fit Lists, add/remove schools, update Right Fit Progress

**Admins**

- Can edit most records; validation rules may block some edits
- To restrict Admin edits: set fields to Read Only
- History Tracking: up to 20 fields per object for audit trail

---

## Data Import & Bulk Updates

**Data Import**

- URL: [Data Management](https://seedfoundation.my.salesforce-setup.com/lightning/setup/DataManagementDataImporter/home)
- Required fields: Last Name, First Name, SEED Email, SEED School, Record Type, Status, Campaign Id
- Example Record Type ID: `012i000000126pxAAA` (Not Enrolled)

**Inline Edits**

- Use List Views; all records in the view must share the same Record Type.

**Preserving Data**

- History Tracking for audit trail
- Field-level CRUD (Create, Read, Update, Delete) to control updates

---

## Troubleshooting

### Common failure: No schools matched

- **Cause:** Matching rules return zero schools; data quality is critical.
- **Detection:** No error message; only automations/flows log errors.
- **Fix options:**
  1. Reset Contact `Right Fit Progress` to "Not Started"; student retries with different criteria.
  2. Manually update `Student Match Criteria` record.
  3. Delete `Student Match Criteria` and associated `Student Right Fit Lists`, then re-run.

### Flow failures

- Error logs are created; users can be configured to receive failure notifications.

### Scenario: Student submits survey, no list generated

- Use Student Match Criteria and Right Fit Lists troubleshooting above.

### Scenario: Counselor doesn't receive notification

- Flow failure; Apex Exception Error sent to configured Admins.

### Scenario: Student sees wrong or unexpected list

- Permissions and matching criteria should prevent wrong lists. If list is too large or too small, troubleshoot via Student Match Criteria and Right Fit Lists.
