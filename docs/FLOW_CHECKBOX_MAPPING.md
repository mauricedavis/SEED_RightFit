# Flow: Checkbox-to-Preview Mapping

Regions, College Size, and College Setting use **multiple checkboxes** on the capture screen. The Right Fit Match Preview expects **one comma-separated string per category**. Create a Formula resource for each and map it to the component.

---

## 1. Regions (comma-separated)

**Checkboxes:** `Far_West__c`, `Great_Lakes__c`, `Mid_East__c`, `New_England__c`, `Plains__c`, `Rocky_Mountains__c`, `Southeast__c`, `Southwest__c`

**Formula** (replace with your screen component API names):
```
IF({!Far_West__c}, "Far West,", "") &
IF({!Great_Lakes__c}, "Great Lakes,", "") &
IF({!Mid_East__c}, "Mid East,", "") &
IF({!New_England__c}, "New England,", "") &
IF({!Plains__c}, "Plains,", "") &
IF({!Rocky_Mountains__c}, "Rocky Mountains,", "") &
IF({!Southeast__c}, "Southeast,", "") &
IF({!Southwest__c}, "Southwest,", "")
```

**Map to:** Right Fit Match Preview → **Regions (comma-separated)**

**Valid values:** Far West, Great Lakes, Mid East, New England, Plains, Rocky Mountains, Southeast, Southwest

---

## 2. College Size (comma-separated)

**Checkboxes:** `Small_Less_than_5_000_Students__c`, `Medium_5_000_to_15_000_Students__c`, `Large_15_000_Students__c`

**Formula** (replace with your screen component API names):
```
IF({!Small_Less_than_5_000_Students__c}, "Small,", "") &
IF({!Medium_5_000_to_15_000_Students__c}, "Medium,", "") &
IF({!Large_15_000_Students__c}, "Large,", "")
```

**Map to:** Right Fit Match Preview → **Sizes (comma-separated)**

**Valid values:** Small, Medium, Large

---

## 3. College Settings (comma-separated)

**Checkboxes:** `Rural__c`, `Town__c`, `Suburban__c`, `Urban__c`

**Formula** (replace with your screen component API names):
```
IF({!Rural__c}, "Rural,", "") &
IF({!Town__c}, "Town,", "") &
IF({!Suburban__c}, "Suburban,", "") &
IF({!Urban__c}, "Urban,", "")
```

**Map to:** Right Fit Match Preview → **College Settings (comma-separated)**

**Valid values:** Rural, Town, Suburban, Urban

---

## Summary: One Map Per Category

| Right Fit Match Preview Property | Flow Formula Resource | Checkbox Fields |
|----------------------------------|------------------------|-----------------|
| Regions (comma-separated) | `RegionsCombined` | Far_West__c, Great_Lakes__c, Mid_East__c, New_England__c, Plains__c, Rocky_Mountains__c, Southeast__c, Southwest__c |
| Sizes (comma-separated) | `SizesCombined` | Small_Less_than_5_000_Students__c, Medium_5_000_to_15_000_Students__c, Large_15_000_Students__c |
| College Settings (comma-separated) | `CollegeSettingsCombined` | Rural__c, Town__c, Suburban__c, Urban__c |

**Note:** If your flow uses **Student Match Criteria Id** and loads the record before the preview screen, the component can load all criteria from the record and no mapping is needed.
