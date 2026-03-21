# Right Fit Match Simulator – User Guide

**Confluence-friendly format** | For SEED Foundation admins and counselors

---

## Overview

The **Right Fit Match Simulator** is an admin tool that lets you test college matching logic without going through the student survey flow. You can adjust criteria (GPA, test scores, regions, college size, setting) and see which colleges match in real time. Use it to:

- Validate that colleges appear as expected for certain criteria
- Troubleshoot "no matches" or low match counts
- Understand how broadening or narrowing criteria affects results
- Test the same logic students experience in the Right Fit Survey

---

## Where to Find It

The Right Fit Match Simulator is a **Lightning Web Component** that can be placed on:

- **App page** – e.g., a dedicated Right Fit Tools app
- **Home page** – Lightning Home
- **Record page** – e.g., a Contact or custom object

Ask your Salesforce admin to add the **Right Fit Match Simulator** component to a page you can access. The component API name is `rightFitMatchDiagnostic`.

---

## How to Use the Simulator

### 1. Set criteria

Use the **Criteria** panel on the left to configure matching options.

| Section | Options | Notes |
|---------|---------|-------|
| **GPA** | Low / High (0–4.5) | Range for median GPA of accepted students |
| **ACT** | Low / High (1–36) | ACT composite score range |
| **SAT Math** | Low / High (200–800) | SAT Math score range |
| **SAT Verbal** | Low / High (200–800) | SAT Verbal / Evidence-Based Reading & Writing range |
| **Test Scores Optional** | Checkbox | When checked, includes schools that do not require test scores |
| **Regions** | Far West, Great Lakes, Mid East, New England, Plains, Rocky Mountains, Southeast, Southwest | Select one or more; use **Select All** to include all regions |
| **College Size** | Small (<5K), Medium (5K–15K), Large (15K+) | Select one or more; use **Select All** for all sizes |
| **College Setting** | Rural, Town, Suburban, Urban | Select one or more, or check **Any/All (no preference)** |

### 2. Minimum criteria

You must select **at least one** of the following:

- At least one **Region**, or  
- At least one **College Size**, or  
- At least one **College Setting** (or Any/All)

Until you do, the simulator will prompt you to select criteria.

### 3. View results

The **Results** panel on the right updates as you change criteria. It shows:

- **Match count** – Number of colleges matching your criteria (badge: green if ≥10, yellow if 1–9, red if 0)
- **Active filters** – Summary of all criteria currently applied
- **Suggestions** – Tips to broaden criteria when you have fewer than 10 matches
- **Zero-match feedback** – If no colleges match, explains possible causes and next steps

### 4. Results table

When colleges match, a table shows:

| Column | Description |
|--------|-------------|
| College | College name (link to Account record) |
| Right Fit | Right Fit match color (Yellow, Green, or Red) |
| Region | Geographical region |
| Size | Small, Medium, or Large |
| Setting | Rural, Town, Suburban, or Urban |
| GPA | Median GPA (— if not available) |
| ACT | Median ACT composite (— if not available) |
| SAT Math | Median SAT Math (— if not available) |
| SAT Verbal | Median SAT Verbal (— if not available) |

Click a college name to open its Account record in a new tab.

---

## Tips for Admins

### Broaden criteria for more matches

- Add more **regions** or use **Select All** for regions
- Add more **college sizes** or use **Select All** for sizes
- Choose **Any/All (no preference)** for College Setting
- Widen GPA or test score ranges
- Check **Test Scores Optional** to include test-optional schools

### Zero matches

If you see "No colleges match":

- Review **Possible causes** and **What to do** in the zero-match feedback box
- Confirm colleges in your org have Right Fit attributes filled (region, size, setting, GPA, etc.)
- Check that colleges have **Right Fit Match Color** = Yellow or Green (only these are matchable)
- Ensure you have selected at least one region, size, or setting

### Match logic

The simulator uses the same logic as the student Right Fit Survey and the record-triggered flow that creates **Student Right Fit Lists**. Criteria are combined with AND logic for region, size, and setting; GPA and test scores use range matching.

---

## Technical Reference

| Item | Value |
|------|-------|
| Component | rightFitMatchDiagnostic |
| Apex Service | RightFitMatchService |
| Methods Used | getMatchResultsBySelections, getMatchPreviewBySelections |

---

## Related Documentation

- [Right Fit Survey: Match Preview Refresh – User & Admin Guide](SEED-Right-Fit-Survey-User-Guide.md)
- [CMT Platform Training](https://attainpartners.atlassian.net/wiki/spaces/SEED/pages/1758035969/CMT+Platform+Training)
- [Project Background](BACKGROUND.md)
