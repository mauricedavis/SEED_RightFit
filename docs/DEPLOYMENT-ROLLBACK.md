# Deployment and rollback (Salesforce)

Salesforce does not offer a one-click “undo” for API metadata deploys. Rollback is a **second deploy** that puts the org back in a known-good state from **git** (or a saved package).

## What to do on every non-trivial deploy

1. **Ship from a known commit** — tag or record the `git` SHA you deployed (e.g. `7d05c2c`).
2. **Log deploy job IDs** — in each org, **Setup → Deployment Status** (or the CLI’s `Deploy ID` in the `sf` output). Append them to a new `deploy-rollback-*.txt` in the repo root, or in this file’s “Recent deploys” list.
3. **Optional: tag after prod** — e.g. `git tag -a v2026-04-23-prod 7d05c2c -m "Deployed seedfoundation"`.

## Roll back using git (preferred)

1. Find the last good commit (e.g. the parent of the release: `git log -2 --oneline`).
2. **Modified files:** restore the old version, then redeploy the same components:

   ```powershell
   cd "c:\Users\MauriceJDavis\SEED_RightFit"
   git checkout e24f1c9 -- path/to/file1 path/to/file2
   sf project deploy start -m "ApexClass:SomeClass" ... -o seedfoundation
   ```

3. **New metadata added in the bad release** (Apex, Flow, etc.): you must both remove the files from the project **and** remove the metadata from the org, or the org will keep the new behavior:

   - From the repo: `git rm` the added files, commit if needed, or `git checkout e24f1c9 --` on the parent directory and delete untracked adds as appropriate.
   - From the org (destructive, confirm first):

   ```text
   sf project delete source --target-org <alias> --metadata ApexClass:ClassName
   ```

   Or deploy a [destructiveChanges.xml](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/file_delete.htm) package. Prefer doing this in a full sandbox first.

4. **Verify** in the target org: smoke-test the affected flows, community login, and any automation that was touched.

## If you do not have the right source in git

- Use **Setup → Deployment Status** in the org to see what ran; you still need a copy of the **previous** metadata to deploy back.
- If needed, retrieve the known-good state from a **sandbox** that was not yet updated, or from an older local branch, then deploy to prod.

## Recent rollback records (pointers)

| Date       | File |
|-----------|------|
| 2026-04-06 | [../deploy-rollback-seedfoundation-login-link-contrast-2026-04-06.txt](../deploy-rollback-seedfoundation-login-link-contrast-2026-04-06.txt) |
| 2026-04-23 | [../deploy-rollback-2026-04-23-seed-rightfit.txt](../deploy-rollback-2026-04-23-seed-rightfit.txt) (GPA, community, password bundle) |
| 2026-04-23 | [../deploy-rollback-2026-04-23-creating-right-fit-match-soql-bulk-dedupe.txt](../deploy-rollback-2026-04-23-creating-right-fit-match-soql-bulk-dedupe.txt) — *Creating Right Fit Match* flow: bulk SRL de-dupe / 101 SOQL; **follow-up** flow deploy (Get zero matching schools, no `CANNOT_EXECUTE_FLOW_TRIGGER` on survey save); same file lists both deploys |

Add a new `deploy-rollback-YYYY-MM-DD-*.txt` for each major production deploy you may need to reverse.
