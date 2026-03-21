/**
 * Right Fit College Match Funnel Analysis
 * Run via: Developer Console → Execute Anonymous → RightFitMatchFunnel.run();
 *
 * Analyzes WHY no Colleges match student criteria. Applies matching filters
 * step-by-step (same logic as RightFitMatchService) to find the bottleneck.
 * Simulates BROAD criteria: all regions, all sizes, all settings,
 * GPA 2.5–4.5, ACT 19–31 OR Test Optional.
 */
public with sharing class RightFitMatchFunnel {
    private static final Set<String> MATCHABLE_COLORS = new Set<String>{
        'Yellow', 'Green', 'SEEDMatchingYellow', 'SEEDMatchGreenConstant'
    };

    private static final Set<String> ALL_REGIONS = new Set<String>{
        'Far West', 'FarWest', 'Great Lakes', 'GreatLakes', 'Mid East', 'MidEast',
        'New England', 'NewEngland', 'Rocky Mountains', 'RockyMountains',
        'Southeast', 'Southwest', 'Plains'
    };

    private static final Set<String> ALL_SIZES = new Set<String>{
        'Small', 'SizeSmall', 'Medium', 'SizeMedium', 'Large', 'SizeLarge'
    };

    private static final Set<String> ALL_SETTINGS = new Set<String>{ 'Rural', 'Town', 'Suburban', 'Urban' };

    private static final Double GPA_LOW = 2.5;
    private static final Double GPA_HIGH = 4.5;
    private static final Double ACT_LOW = 19.0;
    private static final Double ACT_HIGH = 31.0;

    /** Testable row data - use runWithData() from tests for full path coverage. */
    @TestVisible
    public class FunnelRow {
        @TestVisible public String name;
        @TestVisible public String color;
        @TestVisible public String region;
        @TestVisible public String size;
        @TestVisible public String setting;
        @TestVisible public Boolean testOpt;
        @TestVisible public Double gpa;
        @TestVisible public Double act;
    }

    public static void run() {
        List<Account> all = [
            SELECT Id, Name, Right_Fit_Match_Color_Automatic__c, Geographical_Region__c,
                   College_Size_Formula__c, College_Setting__c, Test_Scores_Optional__c,
                   Median_GPA__c, Median_ACT_Composite__c
            FROM Account
            WHERE RecordType.DeveloperName = 'College'
        ];
        List<FunnelRow> rows = new List<FunnelRow>();
        for (Account a : all) {
            FunnelRow r = new FunnelRow();
            r.name = a.Name;
            r.color = a.Right_Fit_Match_Color_Automatic__c;
            r.region = a.Geographical_Region__c;
            r.size = a.College_Size_Formula__c;
            r.setting = a.College_Setting__c;
            r.testOpt = a.Test_Scores_Optional__c == true;
            r.gpa = a.Median_GPA__c;
            r.act = a.Median_ACT_Composite__c;
            rows.add(r);
        }
        runWithData(rows);
    }

    /** Entry point for tests - accepts mock data to exercise all code paths. */
    @TestVisible
    private static void runWithData(List<FunnelRow> all) {
        log('╔══════════════════════════════════════════════════════════════╗');
        log('║  RIGHT FIT COLLEGE MATCH FUNNEL ANALYSIS                    ║');
        log('╚══════════════════════════════════════════════════════════════╝');
        log('');
        log('Total College records: ' + all.size());
        log('');

        List<FunnelRow> afterColor = new List<FunnelRow>();
        for (FunnelRow r : all) {
            if (MATCHABLE_COLORS.contains(r.color)) {
                afterColor.add(r);
            }
        }
        log('STEP 1: Right Fit Match Color (Yellow/Green/SEEDMatchingYellow/SEEDMatchGreenConstant)');
        log('  Input:  ' + all.size());
        log('  Output: ' + afterColor.size());
        if (afterColor.isEmpty()) {
            log('  ⚠️  BOTTLENECK: Zero colleges have matchable color. Check Right_Fit_Match_Color_Automatic__c.');
            Map<String, Integer> colorDist = new Map<String, Integer>();
            for (FunnelRow r : all) {
                String c = r.color != null ? r.color : '(null)';
                colorDist.put(c, colorDist.containsKey(c) ? colorDist.get(c) + 1 : 1);
            }
            for (String k : colorDist.keySet()) {
                log('    [' + k + ']: ' + colorDist.get(k));
            }
            return;
        }
        log('  ✓ Passed');
        log('');

        List<FunnelRow> afterGpa = new List<FunnelRow>();
        Integer gpaNull = 0;
        for (FunnelRow r : afterColor) {
            if (r.gpa == null) {
                gpaNull++;
            } else if (r.gpa >= GPA_LOW && r.gpa <= GPA_HIGH) {
                afterGpa.add(r);
            }
        }
        log('STEP 2: GPA in range ' + GPA_LOW + '-' + GPA_HIGH);
        log('  Input:  ' + afterColor.size());
        log('  Output: ' + afterGpa.size());
        log('  (Skipped: ' + gpaNull + ' with null Median_GPA__c)');
        if (afterGpa.isEmpty()) {
            log('  ⚠️  BOTTLENECK: Zero colleges have Median_GPA__c in range. Sample GPAs from matchable:');
            for (Integer i = 0; i < Math.min(5, afterColor.size()); i++) {
                log('    ' + afterColor[i].name + ' | GPA: ' + afterColor[i].gpa);
            }
        }
        log('');

        List<FunnelRow> afterTest = new List<FunnelRow>();
        Integer actMatch = 0;
        Integer testOptMatch = 0;
        for (FunnelRow r : afterGpa) {
            Boolean actOk = r.act != null && r.act >= ACT_LOW && r.act <= ACT_HIGH;
            if (actOk || r.testOpt == true) {
                afterTest.add(r);
                if (actOk) actMatch++;
                if (r.testOpt == true) testOptMatch++;
            }
        }
        log('STEP 3: Test scores – (ACT ' + ACT_LOW + '-' + ACT_HIGH + ') OR Test_Scores_Optional__c = true');
        log('  Input:  ' + afterGpa.size());
        log('  Output: ' + afterTest.size());
        log('  (Via ACT: ' + actMatch + ', via Test Optional: ' + testOptMatch + ')');
        if (afterTest.isEmpty()) {
            log('  ⚠️  BOTTLENECK: Zero colleges pass test criteria. Sample from GPA-passed:');
            for (Integer i = 0; i < Math.min(5, afterGpa.size()); i++) {
                FunnelRow r = afterGpa[i];
                log('    ' + r.name + ' | ACT: ' + r.act + ' | TestOpt: ' + r.testOpt);
            }
        }
        log('');

        List<FunnelRow> afterLoc = new List<FunnelRow>();
        Integer regionNull = 0;
        Integer sizeNull = 0;
        Integer settingNull = 0;
        for (FunnelRow r : afterTest) {
            Boolean hasRegion = r.region != null && ALL_REGIONS.contains(r.region);
            Boolean hasSize = r.size != null && ALL_SIZES.contains(r.size);
            Boolean hasSetting = r.setting != null && ALL_SETTINGS.contains(r.setting);
            if (r.region == null) regionNull++;
            if (r.size == null) sizeNull++;
            if (r.setting == null) settingNull++;
            if (hasRegion || hasSize || hasSetting || r.testOpt == true) {
                afterLoc.add(r);
            }
        }
        log('STEP 4: Region OR Size OR Setting OR Test Optional (must match at least one)');
        log('  Input:  ' + afterTest.size());
        log('  Output: ' + afterLoc.size());
        log('  Null counts in input: Region=' + regionNull + ', Size=' + sizeNull + ', Setting=' + settingNull);
        if (afterLoc.isEmpty()) {
            log('  ⚠️  BOTTLENECK: Zero colleges pass location/size/setting. Actual values in DB:');
            Map<String, Integer> regionVals = new Map<String, Integer>();
            Map<String, Integer> sizeVals = new Map<String, Integer>();
            Map<String, Integer> settingVals = new Map<String, Integer>();
            for (FunnelRow r : afterTest) {
                String rv = r.region != null ? r.region : '(null)';
                regionVals.put(rv, regionVals.containsKey(rv) ? regionVals.get(rv) + 1 : 1);
                String sv = r.size != null ? r.size : '(null)';
                sizeVals.put(sv, sizeVals.containsKey(sv) ? sizeVals.get(sv) + 1 : 1);
                String st = r.setting != null ? r.setting : '(null)';
                settingVals.put(st, settingVals.containsKey(st) ? settingVals.get(st) + 1 : 1);
            }
            log('  Geographical_Region__c values: ' + regionVals.keySet());
            log('  College_Size_Formula__c values: ' + sizeVals.keySet());
            log('  College_Setting__c values: ' + settingVals.keySet());
            log('  Expected regions: Far West, FarWest, Great Lakes, GreatLakes, etc.');
            log('  Expected sizes: Small, SizeSmall, Medium, SizeMedium, Large, SizeLarge');
        }
        log('');

        log('═══════════════════════════════════════════════════════════════');
        log('FINAL MATCH COUNT (broad criteria): ' + afterLoc.size());
        log('═══════════════════════════════════════════════════════════════');
        if (afterLoc.size() > 0) {
            log('Sample matches (first 5):');
            for (Integer i = 0; i < Math.min(5, afterLoc.size()); i++) {
                FunnelRow r = afterLoc[i];
                log('  ' + r.name + ' | Region:' + r.region + ' | Size:' + r.size
                    + ' | Setting:' + r.setting + ' | GPA:' + r.gpa + ' | ACT:' + r.act);
            }
        } else {
            log('No colleges match. Review BOTTLENECK messages above.');
        }
    }

    private static void log(String msg) {
        System.debug(msg);
    }
}
