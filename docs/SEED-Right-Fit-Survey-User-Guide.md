# Right Fit Survey: Match Preview Refresh – User & Admin Guide

**Confluence-friendly format** | For SEED Foundation end-users and admins

---

## For Students Using the Right Fit Survey

### What changed

When you complete the Right Fit Survey and see the **Matching Preview** screen, you may see fewer than 10 colleges matched. Previously, if you went back to change your criteria and then clicked **Next** again, the number would not update. It now updates automatically so you can broaden your search and see more matches.

### What you need to know

1. **Minimum 10 matches**
   - You need at least 10 colleges to proceed.
   - If you see fewer, the screen will show suggestions to broaden your criteria (e.g., regions, college size, test scores).

2. **Broadening your search**
   - Click **Previous** to return to the criteria screen.
   - Add more regions, college sizes, or relax test score ranges.
   - Click **Next** again.
   - The match count will update automatically with your new choices.

3. **Recalculate button**
   - If the count does not update, use the **Recalculate** button to refresh manually.

4. **No more automatic refresh**
   - The screen no longer refreshes every few seconds. Use **Recalculate** only when needed.

---

## For Admins & Support

### Flow and component

| Item | Value |
|------|-------|
| Flow | Student_Right_Fit_School_Selection_Criteria |
| Flow API Name | Student_Right_Fit_School_Selection_Criteria |
| Preview Screen | MatchingPreviewScreen |
| LWC | rightFitMatchPreview |

### Key setting

The Right Fit Match Preview component uses **"Refresh inputs to incorporate changes elsewhere in the flow"** so that when students navigate back and forward, the preview gets fresh data.

**To change this in Flow Builder:**
1. Open the flow *Student_Right_Fit_School_Selection_Criteria*.
2. Select the **MatchingPreviewScreen**.
3. Select the **Right Fit Match Preview** component.
4. In the component properties, find the option for when the user revisits the screen.
5. Ensure it is set to **Refresh inputs to incorporate changes elsewhere in the flow** (not "Use values from when the user last visited this screen").

### Formula_Refresh_Timestamp

The flow uses a formula `Formula_Refresh_Timestamp` so the preview knows when to recalculate.  
The formula must use:
- `$Flow.CurrentDate` for date parts (YEAR, MONTH, DAY)
- `TIMEVALUE($Flow.CurrentDateTime)` for time parts (HOUR, MINUTE, SECOND)

Using `$Flow.CurrentDateTime` directly with YEAR/MONTH/DAY will cause validation errors.

### Troubleshooting

| Symptom | Possible cause | Action |
|---------|----------------|--------|
| Match count does not update after going back | Flow component set to UseStoredValues | Set to Refresh inputs (see above) |
| Flow validation error on Formula_Refresh_Timestamp | Wrong data types (Date/Time vs Date/Time) | Use formula from plan.md |
| Student still stuck | Criteria too narrow | Suggest broadening regions, sizes, or test score ranges |

### Deployment

- **Main org:** seedfoundation
- **Full sandbox:** seed-fullsb
- **Repo:** https://github.com/mauricedavis/SEED_RightFit

---

## Related documentation

- [CMT Platform Training](https://attainpartners.atlassian.net/wiki/spaces/SEED/pages/1758035969/CMT+Platform+Training)
- JIRA: [SEED-21](https://attainpartners.atlassian.net/browse/SEED-21)
