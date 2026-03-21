# SEED RightFit

Salesforce DX project for the **SEED Right Fit** college matching solution. Students complete a Right Fit Survey; their criteria are matched against colleges (Accounts), and counselors review and curate the results before students access them in the SEED Right Fit Community portal.

**Repository:** [github.com/mauricedavis/SEED_RightFit](https://github.com/mauricedavis/SEED_RightFit)

---

## Key Components

| Component | Type | Purpose |
|-----------|------|---------|
| `rightFitMatchPreview` | LWC | Match preview in Right Fit Survey flow; shows match count, suggestions, Recalculate |
| `rightFitMatchDiagnostic` | LWC | Admin simulator for testing match logic |
| `RightFitMatchService` | Apex | Matching logic (`getMatchPreviewByRecordId`, `getMatchPreviewBySelections`) |
| `Student_Right_Fit_School_Selection_Criteria` | Flow | Right Fit Survey capture flow (Student Match Criteria → Matching Preview) |

---

## Prerequisites

- [Node.js](https://nodejs.org/) (v18 or later recommended)
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) (sf)
- [VS Code](https://code.visualstudio.com/) with [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode) (recommended)

---

## Setup

1. **Clone and install**
   ```powershell
   git clone https://github.com/mauricedavis/SEED_RightFit.git
   cd SEED_RightFit
   npm install
   ```

2. **Authorize a Salesforce org**
   ```powershell
   sf org login web
   ```

3. **Deploy to your org**
   ```powershell
   sf project deploy start --target-org seedfoundation
   ```

---

## Project Structure

```
SEED_RightFit/
├── force-app/main/default/
│   ├── lwc/
│   │   ├── rightFitMatchPreview/     # Right Fit Survey preview component
│   │   └── rightFitMatchDiagnostic/  # Admin diagnostic simulator
│   ├── classes/
│   │   ├── RightFitMatchService.cls
│   │   └── RightFitMatchServiceTest.cls
│   └── flows/
│       └── Student_Right_Fit_School_Selection_Criteria.flow-meta.xml
├── docs/
│   ├── BACKGROUND.md                 # Project background and terminology
│   ├── FLOW_CHECKBOX_MAPPING.md     # Checkbox-to-preview mapping
│   └── plan.md                      # Implementation plan and findings
├── config/                          # Scratch org def (optional)
└── sfdx-project.json
```

---

## Deploy Targets

| Environment | Target |
|-------------|--------|
| Default (seedfoundation) | `sf project deploy start --target-org seedfoundation` |
| Full Sandbox | `sf project deploy start --target-org <fullsb-alias>` |

---

## Retrieve Flow from Org

To pull the latest flow (e.g., after changes in Flow Builder):

```powershell
sf project retrieve start --metadata "Flow:Student_Right_Fit_School_Selection_Criteria" --target-org seedfoundation
```

---

## NPM Scripts

| Command | Description |
|---------|-------------|
| `npm run lint` | Lint Aura and LWC JavaScript |
| `npm run test` | Run LWC unit tests |
| `npm run test:unit:watch` | Run tests in watch mode |
| `npm run test:unit:coverage` | Run tests with coverage |
| `npm run prettier` | Format code |
| `npm run prettier:verify` | Check code formatting |

---

## Documentation

- [docs/BACKGROUND.md](docs/BACKGROUND.md) – Terminology, end-to-end flow, key objects
- [docs/FLOW_CHECKBOX_MAPPING.md](docs/FLOW_CHECKBOX_MAPPING.md) – Checkbox-to-preview mapping
- [docs/plan.md](docs/plan.md) – Implementation plan, formula fixes, Flow refresh settings

---

## Resources

- [LWC Developer Guide](https://developer.salesforce.com/docs/platform/lwc/guide)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev)
