/**
 * Right Fit College Match Funnel Analysis
 * Run in Developer Console → Debug → Open Execute Anonymous Window
 *
 * Analyzes WHY no Colleges match student criteria. Applies matching filters
 * step-by-step (same logic as RightFitMatchService) to find the bottleneck.
 *
 * Simulates BROAD criteria: all regions, all sizes, all settings,
 * GPA 2.5–4.5, ACT 19–31 OR Test Optional.
 */
Set<String> MATCHABLE_COLORS = new Set<String>{
    'Yellow', 'Green', 'SEEDMatchingYellow', 'SEEDMatchGreenConstant'
};

Set<String> ALL_REGIONS = new Set<String>{
    'Far West', 'FarWest', 'Great Lakes', 'GreatLakes', 'Mid East', 'MidEast',
    'New England', 'NewEngland', 'Rocky Mountains', 'RockyMountains',
    'Southeast', 'Southwest', 'Plains'
};

Set<String> ALL_SIZES = new Set<String>{
    'Small', 'SizeSmall', 'Medium', 'SizeMedium', 'Large', 'SizeLarge'
};

Set<String> ALL_SETTINGS = new Set<String>{ 'Rural', 'Town', 'Suburban', 'Urban' };

Double GPA_LOW = 2.5;
Double GPA_HIGH = 4.5;
Double ACT_LOW = 19.0;
Double ACT_HIGH = 31.0;

List<Account> all = [
    SELECT Id, Name, Right_Fit_Match_Color_Automatic__c, Geographical_Region__c,
           College_Size_Formula__c, College_Setting__c, Test_Scores_Optional__c,
           Median_GPA__c, Median_ACT_Composite__c, Median_SAT_Math__c, Median_SAT_Verbal__c
    FROM Account
    WHERE RecordType.DeveloperName = 'College'
];

System.debug('╔══════════════════════════════════════════════════════════════╗');
System.debug('║  RIGHT FIT COLLEGE MATCH FUNNEL ANALYSIS                    ║');
System.debug('╚══════════════════════════════════════════════════════════════╝');
System.debug('');
System.debug('Total College records: ' + all.size());
System.debug('');

// Step 1: Color filter (matchable only)
List<Account> afterColor = new List<Account>();
for (Account a : all) {
    if (MATCHABLE_COLORS.contains(a.Right_Fit_Match_Color_Automatic__c)) {
        afterColor.add(a);
    }
}
System.debug('STEP 1: Right Fit Match Color (Yellow/Green/SEEDMatchingYellow/SEEDMatchGreenConstant)');
System.debug('  Input:  ' + all.size());
System.debug('  Output: ' + afterColor.size());
if (afterColor.isEmpty()) {
    System.debug('  ⚠️  BOTTLENECK: Zero colleges have matchable color. Check Right_Fit_Match_Color_Automatic__c.');
    System.debug('  Color distribution in DB:');
    Map<String, Integer> colorDist = new Map<String, Integer>();
    for (Account a : all) {
        String c = a.Right_Fit_Match_Color_Automatic__c != null ? a.Right_Fit_Match_Color_Automatic__c : '(null)';
        colorDist.put(c, colorDist.containsKey(c) ? colorDist.get(c) + 1 : 1);
    }
    for (String k : colorDist.keySet()) { System.debug('    [' + k + ']: ' + colorDist.get(k)); }
    return;
}
System.debug('  ✓ Passed');
System.debug('');

// Step 2: GPA filter (2.5–4.5)
List<Account> afterGpa = new List<Account>();
Integer gpaNull = 0;
for (Account a : afterColor) {
    if (a.Median_GPA__c == null) {
        gpaNull++;
    } else if (a.Median_GPA__c >= GPA_LOW && a.Median_GPA__c <= GPA_HIGH) {
        afterGpa.add(a);
    }
}
System.debug('STEP 2: GPA in range ' + GPA_LOW + '–' + GPA_HIGH);
System.debug('  Input:  ' + afterColor.size());
System.debug('  Output: ' + afterGpa.size());
System.debug('  (Skipped: ' + gpaNull + ' with null Median_GPA__c)');
if (afterGpa.isEmpty()) {
    System.debug('  ⚠️  BOTTLENECK: Zero colleges have Median_GPA__c in range. Sample GPAs from matchable:');
    for (Integer i = 0; i < Math.min(5, afterColor.size()); i++) {
        Account a = afterColor[i];
        System.debug('    ' + a.Name + ' | GPA: ' + a.Median_GPA__c);
    }
    System.debug('  Consider broadening GPA in RightFitMatchService or populating Median_GPA__c.');
}
System.debug('');

// Step 3: Test scores – ACT 19–31 OR Test Optional
List<Account> afterTest = new List<Account>();
Integer actMatch = 0, testOptMatch = 0;
for (Account a : afterGpa) {
    Boolean actOk = a.Median_ACT_Composite__c != null && a.Median_ACT_Composite__c >= ACT_LOW && a.Median_ACT_Composite__c <= ACT_HIGH;
    Boolean testOpt = a.Test_Scores_Optional__c == true;
    if (actOk || testOpt) {
        afterTest.add(a);
        if (actOk) actMatch++;
        if (testOpt) testOptMatch++;
    }
}
System.debug('STEP 3: Test scores – (ACT ' + ACT_LOW + '–' + ACT_HIGH + ') OR Test_Scores_Optional__c = true');
System.debug('  Input:  ' + afterGpa.size());
System.debug('  Output: ' + afterTest.size());
System.debug('  (Via ACT: ' + actMatch + ', via Test Optional: ' + testOptMatch + ')');
if (afterTest.isEmpty()) {
    System.debug('  ⚠️  BOTTLENECK: Zero colleges pass test criteria. Sample from GPA-passed:');
    for (Integer i = 0; i < Math.min(5, afterGpa.size()); i++) {
        Account a = afterGpa[i];
        System.debug('    ' + a.Name + ' | ACT: ' + a.Median_ACT_Composite__c + ' | TestOpt: ' + a.Test_Scores_Optional__c);
    }
}
System.debug('');

// Step 4: Region OR Size OR Setting OR Test Optional (at least one)
List<Account> afterLoc = new List<Account>();
Integer regionNull = 0, sizeNull = 0, settingNull = 0;
for (Account a : afterTest) {
    Boolean hasRegion = a.Geographical_Region__c != null && ALL_REGIONS.contains(a.Geographical_Region__c);
    Boolean hasSize = a.College_Size_Formula__c != null && ALL_SIZES.contains(a.College_Size_Formula__c);
    Boolean hasSetting = a.College_Setting__c != null && ALL_SETTINGS.contains(a.College_Setting__c);
    Boolean hasTestOpt = a.Test_Scores_Optional__c == true;
    if (!hasRegion && a.Geographical_Region__c != null && !ALL_REGIONS.contains(a.Geographical_Region__c)) {
        // Track unexpected values
    }
    if (a.Geographical_Region__c == null) regionNull++;
    if (a.College_Size_Formula__c == null) sizeNull++;
    if (a.College_Setting__c == null) settingNull++;
    if (hasRegion || hasSize || hasSetting || hasTestOpt) {
        afterLoc.add(a);
    }
}
System.debug('STEP 4: Region OR Size OR Setting OR Test Optional (must match at least one)');
System.debug('  Input:  ' + afterTest.size());
System.debug('  Output: ' + afterLoc.size());
System.debug('  Null counts in input: Region=' + regionNull + ', Size=' + sizeNull + ', Setting=' + settingNull);
if (afterLoc.isEmpty()) {
    System.debug('  ⚠️  BOTTLENECK: Zero colleges pass location/size/setting. Actual values in DB:');
    Map<String, Integer> regionVals = new Map<String, Integer>();
    Map<String, Integer> sizeVals = new Map<String, Integer>();
    Map<String, Integer> settingVals = new Map<String, Integer>();
    for (Account a : afterTest) {
        String r = a.Geographical_Region__c != null ? a.Geographical_Region__c : '(null)';
        regionVals.put(r, regionVals.containsKey(r) ? regionVals.get(r) + 1 : 1);
        String s = a.College_Size_Formula__c != null ? a.College_Size_Formula__c : '(null)';
        sizeVals.put(s, sizeVals.containsKey(s) ? sizeVals.get(s) + 1 : 1);
        String st = a.College_Setting__c != null ? a.College_Setting__c : '(null)';
        settingVals.put(st, settingVals.containsKey(st) ? settingVals.get(st) + 1 : 1);
    }
    System.debug('  Geographical_Region__c values: ' + regionVals.keySet());
    System.debug('  College_Size_Formula__c values: ' + sizeVals.keySet());
    System.debug('  College_Setting__c values: ' + settingVals.keySet());
    System.debug('  Expected regions: Far West, FarWest, Great Lakes, GreatLakes, etc.');
    System.debug('  Expected sizes: Small, SizeSmall, Medium, SizeMedium, Large, SizeLarge');
}
System.debug('');

// Summary
System.debug('═══════════════════════════════════════════════════════════════');
System.debug('FINAL MATCH COUNT (broad criteria): ' + afterLoc.size());
System.debug('═══════════════════════════════════════════════════════════════');
if (afterLoc.size() > 0) {
    System.debug('Sample matches (first 5):');
    for (Integer i = 0; i < Math.min(5, afterLoc.size()); i++) {
        Account a = afterLoc[i];
        System.debug('  ' + a.Name + ' | Region:' + a.Geographical_Region__c + ' | Size:' + a.College_Size_Formula__c + ' | Setting:' + a.College_Setting__c + ' | GPA:' + a.Median_GPA__c + ' | ACT:' + a.Median_ACT_Composite__c);
    }
} else {
    System.debug('No colleges match. Review BOTTLENECK messages above.');
}
