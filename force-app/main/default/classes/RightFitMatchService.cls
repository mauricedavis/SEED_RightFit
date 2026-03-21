/**
 * RightFitMatchService - Core matching logic for SEED Right Fit
 * Mirrors flow "Automation - Student Match Criteria - Creating Right Fit Match Records"
 * Used by rightFitMatchPreview (student) and rightFitMatchDiagnostic (admin) LWCs
 */
public with sharing class RightFitMatchService {
    private static final Integer SUGGESTION_THRESHOLD = 10;
    private static final Integer ALL_REGIONS_COUNT = 8;
    private static final Integer ALL_SIZES_COUNT = 3;
    private static final Integer ALL_SETTINGS_COUNT = 4;

    /**
     * Match preview for student flow - loads criteria from record and runs match (no CriteriaInput round-trip).
     * Ensures same matching logic as simulator.
     */
    @AuraEnabled(cacheable=false)
    public static MatchPreviewResult getMatchPreviewByRecordId(Id studentMatchCriteriaId) {
        CriteriaInput c = loadCriteriaFromRecordInternal(studentMatchCriteriaId);
        return getMatchPreview(c);
    }

    /**
     * Match preview for student flow - returns count and suggestions when 0-9 matches
     */
    @AuraEnabled(cacheable=false)
    public static MatchPreviewResult getMatchPreview(CriteriaInput criteria) {
        MatchPreviewResult result = new MatchPreviewResult();
        List<Account> matches = getMatchingAccounts(criteria);
        result.matchCount = matches.size();
        result.canSubmit = result.matchCount >= SUGGESTION_THRESHOLD;
        result.suggestions = getMatchSuggestions(criteria, result.matchCount);
        if (result.matchCount == 0 && criteria != null) {
            result.zeroMatchFeedback = buildZeroMatchFeedback(criteria);
        }
        return result;
    }

    /**
     * Diagnostic: match by selections - bypasses CriteriaInput for reliable serialization
     */
    @AuraEnabled(cacheable=false)
    public static List<AccountMatchResult> getMatchResultsBySelections(List<String> regions, List<String> sizes, List<String> collegeSettings, Boolean testScoresOptional,
            Decimal gpaLow, Decimal gpaHigh, Decimal actLow, Decimal actHigh, Decimal satMathLow, Decimal satMathHigh, Decimal satVerbalLow, Decimal satVerbalHigh) {
        CriteriaInput c = new CriteriaInput();
        c.regions = regions != null ? regions : new List<String>();
        c.sizes = sizes != null ? sizes : new List<String>();
        c.collegeSettings = collegeSettings != null ? collegeSettings : new List<String>();
        c.testScoresOptional = testScoresOptional == true;
        c.gpaLow = gpaLow;
        c.gpaHigh = gpaHigh;
        c.actLow = actLow;
        c.actHigh = actHigh;
        c.satMathLow = satMathLow;
        c.satMathHigh = satMathHigh;
        c.satVerbalLow = satVerbalLow;
        c.satVerbalHigh = satVerbalHigh;
        c.diagnosticMode = true;
        return getMatchResults(c);
    }

    /**
     * Diagnostic: match preview by selections - bypasses CriteriaInput for reliable serialization
     */
    @AuraEnabled(cacheable=false)
    public static MatchPreviewResult getMatchPreviewBySelections(List<String> regions, List<String> sizes, List<String> collegeSettings, Boolean testScoresOptional,
            Decimal gpaLow, Decimal gpaHigh, Decimal actLow, Decimal actHigh, Decimal satMathLow, Decimal satMathHigh, Decimal satVerbalLow, Decimal satVerbalHigh) {
        CriteriaInput c = new CriteriaInput();
        c.regions = regions != null ? regions : new List<String>();
        c.sizes = sizes != null ? sizes : new List<String>();
        c.collegeSettings = collegeSettings != null ? collegeSettings : new List<String>();
        c.testScoresOptional = testScoresOptional == true;
        c.gpaLow = gpaLow;
        c.gpaHigh = gpaHigh;
        c.actLow = actLow;
        c.actHigh = actHigh;
        c.satMathLow = satMathLow;
        c.satMathHigh = satMathHigh;
        c.satVerbalLow = satVerbalLow;
        c.satVerbalHigh = satVerbalHigh;
        c.diagnosticMode = true;
        return getMatchPreview(c);
    }

    /**
     * Full match results for admin diagnostic - returns list of matching Accounts
     */
    @AuraEnabled(cacheable=false)
    public static List<AccountMatchResult> getMatchResults(CriteriaInput criteria) {
        List<Account> accounts = getMatchingAccounts(criteria);
        List<AccountMatchResult> results = new List<AccountMatchResult>();
        for (Account a : accounts) {
            AccountMatchResult ar = new AccountMatchResult();
            ar.accountId = a.Id;
            ar.accountName = a.Name;
            ar.rightFitMatchColor = a.SEED_College_Matching_Color__c != null ? a.SEED_College_Matching_Color__c : a.Right_Fit_Match_Color_Automatic__c;
            ar.medianGpa = a.Median_GPA__c;
            ar.medianAct = a.Median_ACT_Composite__c;
            ar.medianSatMath = a.Median_SAT_Math__c;
            ar.medianSatVerbal = a.Median_SAT_Verbal__c;
            ar.geographicalRegion = a.Geographical_Region__c;
            ar.collegeSizeFormula = a.College_Size_Formula__c;
            ar.collegeSetting = a.College_Setting__c;
            ar.testScoresOptional = a.Test_Scores_Optional__c == true;
            results.add(ar);
        }
        return results;
    }

    /**
     * Run match with one criterion relaxed for permutation testing
     */
    @AuraEnabled(cacheable=false)
    public static PermutationResult runPermutation(CriteriaInput baseCriteria, String relaxationType) {
        CriteriaInput relaxed = baseCriteria.copy();
        relaxed.applyRelaxation(relaxationType);
        List<Account> matches = getMatchingAccounts(relaxed);
        PermutationResult result = new PermutationResult();
        result.matchCount = matches.size();
        result.relaxationType = relaxationType;
        result.suggestions = getMatchSuggestions(relaxed, result.matchCount);
        return result;
    }

    /**
     * Get suggested criteria alternatives that improve match count
     */
    @AuraEnabled(cacheable=false)
    public static List<SuggestedCriteria> getSuggestedCriteria(CriteriaInput criteria) {
        List<SuggestedCriteria> suggestions = new List<SuggestedCriteria>();
        Integer baseCount = getMatchingAccounts(criteria).size();

        String[] relaxationTypes = new String[]{
            'LOCATION', 'COLLEGE_SETTING', 'COLLEGE_SIZE', 'GPA', 'ACT', 'SAT_MATH', 'SAT_VERBAL', 'TEST_OPTIONAL'
        };

        for (String rt : relaxationTypes) {
            PermutationResult pr = runPermutation(criteria, rt);
            if (pr.matchCount > baseCount && pr.matchCount > 0) {
                SuggestedCriteria sc = new SuggestedCriteria();
                sc.relaxationType = rt;
                sc.label = getRelaxationLabel(rt);
                sc.newMatchCount = pr.matchCount;
                sc.improvement = pr.matchCount - baseCount;
                sc.suggestions = pr.suggestions;
                suggestions.add(sc);
            }
        }
        return suggestions;
    }

    /**
     * Load criteria from Student Match Criteria record
     */
    @AuraEnabled(cacheable=false)
    public static CriteriaInput loadCriteriaFromRecord(Id studentMatchCriteriaId) {
        return loadCriteriaFromRecordInternal(studentMatchCriteriaId);
    }

    /**
     * Diagnostic: returns criteria + match count + generated SOQL for troubleshooting
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getMatchPreviewDiagnostics(Id studentMatchCriteriaId) {
        Map<String, Object> out = new Map<String, Object>();
        CriteriaInput c = loadCriteriaFromRecordInternal(studentMatchCriteriaId);
        out.put('criteria', c);
        List<Account> matches = getMatchingAccounts(c);
        out.put('matchCount', matches.size());
        out.put('hasRegions', c.regions != null && !c.regions.isEmpty());
        out.put('hasSizes', c.sizes != null && !c.sizes.isEmpty());
        out.put('hasCollegeSettings', c.collegeSettings != null && !c.collegeSettings.isEmpty());
        out.put('actLow', c.actLow);
        out.put('actHigh', c.actHigh);
        out.put('gpaLow', c.gpaLow);
        out.put('gpaHigh', c.gpaHigh);
        return out;
    }

    private static CriteriaInput loadCriteriaFromRecordInternal(Id recordId) {
        CriteriaInput c = new CriteriaInput();
        if (recordId == null) {
            return c;
        }
        List<Student_Match_Criteria__c> records = [
            SELECT Low_GPA_of_Accepted_Students__c, High_GPA_Accet__c,
                ACT_Score_Low__c, ACT_Composite_Score__c,
                SAT_Math_Low__c, SAT_Math_High__c, SAT_Verbal_Low__c, SAT_Verbal_High_Score__c,
                Test_Score_Optional_Schools__c, College_Setting__c,
                Rural__c, Town__c, Suburban__c, Urban__c,
                Far_West__c, Great_Lakes__c, Mid_East__c, New_England__c, Plains__c,
                Rocky_Mountains__c, Southeast__c, Southwest__c,
                Small_Less_than_5_000_Students__c, Medium_5_000_to_15_000_Students__c, Large_15_000_Students__c
            FROM Student_Match_Criteria__c WHERE Id = :recordId LIMIT 1
        ];
        if (records.isEmpty()) {
            return c;
        }
        Student_Match_Criteria__c smc = records[0];
        c.gpaLow = parsePicklistNumber(smc.Low_GPA_of_Accepted_Students__c, true);
        c.gpaHigh = parsePicklistNumber(smc.High_GPA_Accet__c, false);
        c.actLow = parsePicklistNumber(smc.ACT_Score_Low__c, true);
        c.actHigh = parsePicklistNumber(smc.ACT_Composite_Score__c, false);
        c.satMathLow = parsePicklistNumber(smc.SAT_Math_Low__c, true);
        c.satMathHigh = parsePicklistNumber(smc.SAT_Math_High__c, false);
        c.satVerbalLow = parsePicklistNumber(smc.SAT_Verbal_Low__c, true);
        c.satVerbalHigh = parsePicklistNumber(smc.SAT_Verbal_High_Score__c, false);
        c.testScoresOptional = smc.Test_Score_Optional_Schools__c == true;
        c.collegeSettings = new List<String>();
        if (smc.Rural__c) c.collegeSettings.add('Rural');
        if (smc.Town__c) c.collegeSettings.add('Town');
        if (smc.Suburban__c) c.collegeSettings.add('Suburban');
        if (smc.Urban__c) c.collegeSettings.add('Urban');
        if (c.collegeSettings.isEmpty() && String.isNotBlank(smc.College_Setting__c)) {
            c.collegeSettings.add(smc.College_Setting__c);
        }
        c.regions = new List<String>();
        if (smc.Far_West__c) c.regions.add('Far West');
        if (smc.Great_Lakes__c) c.regions.add('Great Lakes');
        if (smc.Mid_East__c) c.regions.add('Mid East');
        if (smc.New_England__c) c.regions.add('New England');
        if (smc.Plains__c) c.regions.add('Plains');
        if (smc.Rocky_Mountains__c) c.regions.add('Rocky Mountains');
        if (smc.Southeast__c) c.regions.add('Southeast');
        if (smc.Southwest__c) c.regions.add('Southwest');
        c.sizes = new List<String>();
        if (smc.Small_Less_than_5_000_Students__c) c.sizes.add('Small');
        if (smc.Medium_5_000_to_15_000_Students__c) c.sizes.add('Medium');
        if (smc.Large_15_000_Students__c) c.sizes.add('Large');
        return c;
    }

    // --- Private helpers ---

    private static List<Account> getMatchingAccounts(CriteriaInput c) {
        if (c == null) {
            return new List<Account>();
        }

        List<String> dynamicClauses = new List<String>();

        // Base: RecordType College
        dynamicClauses.add('RecordType.DeveloperName = \'College\'');

        // Color - Right Fit rated schools only (mimics: SEED_College_Matching_Color__c in ('Red', 'Yellow', 'Green'))
        dynamicClauses.add('SEED_College_Matching_Color__c IN (\'Red\', \'Yellow\', \'Green\')');

        // GPA (3 AND 4) - exclude schools with no GPA when user specifies a range
        if (c.gpaLow != null && c.gpaHigh != null) {
            dynamicClauses.add('Median_GPA__c != null AND Median_GPA__c >= ' + c.gpaLow + ' AND Median_GPA__c <= ' + c.gpaHigh);
        }

        // Test scores: (SAT range) OR (ACT range) OR Test Optional - exclude schools with no data when ranges are set
        List<String> testClauses = new List<String>();
        if (c.satMathLow != null && c.satMathHigh != null && c.satVerbalLow != null && c.satVerbalHigh != null) {
            testClauses.add('(Median_SAT_Math__c != null AND Median_SAT_Verbal__c != null AND Median_SAT_Math__c >= ' + c.satMathLow + ' AND Median_SAT_Math__c <= ' + c.satMathHigh +
                ' AND Median_SAT_Verbal__c >= ' + c.satVerbalLow + ' AND Median_SAT_Verbal__c <= ' + c.satVerbalHigh + ')');
        }
        if (c.actLow != null && c.actHigh != null) {
            testClauses.add('(Median_ACT_Composite__c != null AND Median_ACT_Composite__c >= ' + c.actLow + ' AND Median_ACT_Composite__c <= ' + c.actHigh + ')');
        }
        if (c.testScoresOptional == true) {
            testClauses.add('Test_Scores_Optional__c = true');
        }
        if (testClauses.isEmpty()) {
            if (c.diagnosticMode == true) {
                // Diagnostic/simulator: no test filter when user hasn't selected any - show all colleges
                // Skip adding test clause; do not add to dynamicClauses
            } else {
                // Student flow: require at least one test path - if none provided, match test-optional only
                testClauses.add('Test_Scores_Optional__c = true');
                dynamicClauses.add('(' + String.join(testClauses, ' OR ') + ')');
            }
        } else {
            dynamicClauses.add('(' + String.join(testClauses, ' OR ') + ')');
        }

        // Region/Size/Setting - AND logic: each selected category must match
        // Account may store "Far West" or "FarWest", "Small" or "SizeSmall" - expand to match both
        List<String> regionSizeSettingClauses = new List<String>();
        if (c.regions != null && !c.regions.isEmpty()) {
            regionSizeSettingClauses.add('Geographical_Region__c IN ' + buildInClause(expandRegionValuesForAccount(c.regions)));
        }
        if (c.sizes != null && !c.sizes.isEmpty()) {
            regionSizeSettingClauses.add('College_Size_Formula__c IN ' + buildInClause(expandSizeValuesForAccount(c.sizes)));
        }
        if (c.collegeSettings != null && !c.collegeSettings.isEmpty()) {
            regionSizeSettingClauses.add('College_Setting__c IN ' + buildInClause(c.collegeSettings));
        } else if (String.isNotBlank(c.collegeSetting)) {
            regionSizeSettingClauses.add('College_Setting__c = \'' + String.escapeSingleQuotes(c.collegeSetting) + '\'');
        }
        if (c.testScoresOptional == true) {
            regionSizeSettingClauses.add('Test_Scores_Optional__c = true');
        }
        if (regionSizeSettingClauses.isEmpty()) {
            // Flow requires at least one of region/size/setting/test-optional; if none, return empty
            return new List<Account>();
        }
        dynamicClauses.add('(' + String.join(regionSizeSettingClauses, ' AND ') + ')');

        String soql = 'SELECT Id, Name, Right_Fit_Match_Color_Automatic__c, SEED_College_Matching_Color__c, Median_GPA__c, Median_ACT_Composite__c, Median_SAT_Math__c, Median_SAT_Verbal__c, ' +
            'Geographical_Region__c, College_Size_Formula__c, College_Setting__c, Test_Scores_Optional__c ' +
            'FROM Account WHERE ' + String.join(dynamicClauses, ' AND ');

        try {
            return Database.query(soql);
        } catch (QueryException e) {
            return new List<Account>();
        }
    }

    /** Account may store regions as "Far West" or "FarWest" - include both for compatibility */
    private static List<String> expandRegionValuesForAccount(List<String> regions) {
        Map<String, String> spaceToNoSpace = new Map<String, String>{
            'Far West' => 'FarWest', 'Great Lakes' => 'GreatLakes', 'Mid East' => 'MidEast',
            'New England' => 'NewEngland', 'Rocky Mountains' => 'RockyMountains'
        };
        Set<String> expanded = new Set<String>();
        for (String r : regions) {
            if (String.isNotBlank(r)) {
                expanded.add(r.trim());
                if (spaceToNoSpace.containsKey(r.trim())) {
                    expanded.add(spaceToNoSpace.get(r.trim()));
                }
            }
        }
        return new List<String>(expanded);
    }

    /** Account may store sizes as "Small" or "SizeSmall" - include both for compatibility */
    private static List<String> expandSizeValuesForAccount(List<String> sizes) {
        Map<String, String> toSizePrefixed = new Map<String, String>{
            'Small' => 'SizeSmall', 'Medium' => 'SizeMedium', 'Large' => 'SizeLarge'
        };
        Set<String> expanded = new Set<String>();
        for (String s : sizes) {
            if (String.isNotBlank(s)) {
                expanded.add(s.trim());
                if (toSizePrefixed.containsKey(s.trim())) {
                    expanded.add(toSizePrefixed.get(s.trim()));
                }
            }
        }
        return new List<String>(expanded);
    }

    private static String buildInClause(List<String> values) {
        List<String> escaped = new List<String>();
        for (String v : values) {
            if (String.isNotBlank(v)) {
                escaped.add('\'' + String.escapeSingleQuotes(v.trim()) + '\'');
            }
        }
        return '(' + String.join(escaped, ', ') + ')';
    }

    private static List<String> getMatchSuggestions(CriteriaInput criteria, Integer matchCount) {
        List<String> suggestions = new List<String>();
        if (matchCount >= SUGGESTION_THRESHOLD) {
            return suggestions;
        }
        if (criteria == null) {
            suggestions.add('Enter your match criteria to see results and suggestions.');
            return suggestions;
        }

        if (matchCount == 0) {
            suggestions.add('No colleges matched your criteria. Try these adjustments:');
        }

        // SAT / ACT / Test Optional — required; often the main blocker
        Boolean hasTestPath = (criteria.satMathLow != null && criteria.satMathHigh != null && criteria.satVerbalLow != null && criteria.satVerbalHigh != null)
            || (criteria.actLow != null && criteria.actHigh != null)
            || criteria.testScoresOptional == true;
        if (!hasTestPath) {
            suggestions.add('Provide at least one: SAT Math & Verbal ranges, ACT Composite range, or Test Optional. Colleges are matched based on your selection.');
        } else if (criteria.testScoresOptional == true && criteria.actLow == null && criteria.satMathLow == null) {
            suggestions.add('Test-optional only matches colleges that have opted in. If you have SAT or ACT scores, try entering your score ranges to see more matches.');
        } else if (criteria.testScoresOptional != true && (criteria.actLow == null && criteria.satMathLow == null)) {
            suggestions.add('Consider including test-optional schools, or enter your SAT or ACT score ranges to expand your options.');
        } else if ((criteria.satMathLow != null || criteria.actLow != null) && matchCount < SUGGESTION_THRESHOLD) {
            suggestions.add('Broadening your SAT or ACT score ranges may yield more matches.');
        }

        // Region / Size / Setting - skip suggestions when user has selected all in a category
        Boolean hasAllRegions = criteria.regions != null && criteria.regions.size() >= ALL_REGIONS_COUNT;
        Boolean hasAllSizes = criteria.sizes != null && criteria.sizes.size() >= ALL_SIZES_COUNT;
        Boolean hasAllSettings = criteria.collegeSettings != null && criteria.collegeSettings.size() >= ALL_SETTINGS_COUNT;

        if (!hasAllRegions) {
            if (criteria.regions == null || criteria.regions.isEmpty()) {
                suggestions.add('Add at least one region (e.g., Southeast, Mid East) to broaden your search.');
            } else if (criteria.regions.size() < 3) {
                suggestions.add('Try selecting additional regions to include more colleges.');
            }
        }

        if (!hasAllSettings && (criteria.collegeSettings == null || criteria.collegeSettings.isEmpty()) && String.isBlank(criteria.collegeSetting)) {
            suggestions.add('Consider selecting a College Setting preference (Rural, Town, Suburban, Urban), or leave blank to match any setting.');
        }

        if (!hasAllSizes) {
            if (criteria.sizes == null || criteria.sizes.isEmpty()) {
                suggestions.add('Add College Size preferences (Small, Medium, or Large).');
            } else if (criteria.sizes.size() < 3) {
                suggestions.add('Try including more college sizes (Small, Medium, Large).');
            }
        }

        if (criteria.gpaHigh != null && criteria.gpaHigh < 3.5) {
            suggestions.add('Slightly broadening your GPA range may yield more matches.');
        }

        if (suggestions.isEmpty() && matchCount < SUGGESTION_THRESHOLD) {
            suggestions.add('Try relaxing one or more criteria to see more matches.');
        }

        return suggestions;
    }

    private static ZeroMatchFeedback buildZeroMatchFeedback(CriteriaInput c) {
        ZeroMatchFeedback fb = new ZeroMatchFeedback();
        List<String> summaryParts = new List<String>();
        summaryParts.add('Regions: ' + (c.regions != null ? c.regions.size() : 0));
        summaryParts.add('Sizes: ' + (c.sizes != null ? c.sizes.size() : 0));
        summaryParts.add('College Settings: ' + ((c.collegeSettings != null && !c.collegeSettings.isEmpty()) ? c.collegeSettings.size() : (String.isNotBlank(c.collegeSetting) ? 1 : 0)));
        summaryParts.add('GPA: ' + (c.gpaLow != null && c.gpaHigh != null ? c.gpaLow + '–' + c.gpaHigh : 'not set'));
        summaryParts.add('ACT: ' + (c.actLow != null && c.actHigh != null ? c.actLow + '–' + c.actHigh : 'not set'));
        summaryParts.add('SAT: ' + (c.satMathLow != null && c.satVerbalLow != null ? 'set' : 'not set'));
        summaryParts.add('Test Optional: ' + (c.testScoresOptional == true ? 'yes' : 'no'));
        fb.criteriaSummary = String.join(summaryParts, ' | ');

        fb.possibleCauses = new List<String>();
        Boolean hasLocation = (c.regions != null && !c.regions.isEmpty()) || (c.sizes != null && !c.sizes.isEmpty())
            || (c.collegeSettings != null && !c.collegeSettings.isEmpty()) || String.isNotBlank(c.collegeSetting);
        Boolean hasTestPath = (c.satMathLow != null && c.satMathHigh != null && c.satVerbalLow != null && c.satVerbalHigh != null)
            || (c.actLow != null && c.actHigh != null) || c.testScoresOptional == true;

        if (!hasLocation) {
            fb.possibleCauses.add('No regions, sizes, or college settings were loaded. Your selections may not have been saved correctly.');
        }
        if (!hasTestPath) {
            fb.possibleCauses.add('No test score criteria (ACT, SAT, or Test Optional). At least one is required for matching.');
        }
        if (hasLocation && hasTestPath) {
            fb.possibleCauses.add('No Colleges in the database match all criteria. Colleges must be Right Fit rated (Yellow, Green, or Red).');
            fb.possibleCauses.add('College data (Region, Size, Setting, GPA, ACT) may not match your selections.');
            fb.possibleCauses.add('If you selected Test Optional only, few colleges may have opted in.');
        }

        fb.nextSteps = new List<String>();
        fb.nextSteps.add('Go back and adjust your criteria, or try including Test Optional schools if you have scores.');
        fb.nextSteps.add('Your college counselor can help. Ask them to verify College data in the system.');
        return fb;
    }

    private static String getRelaxationLabel(String rt) {
        Map<String, String> labels = new Map<String, String>{
            'LOCATION' => 'Add more regions',
            'COLLEGE_SETTING' => 'Broaden College Setting',
            'COLLEGE_SIZE' => 'Include all college sizes',
            'GPA' => 'Broaden GPA range',
            'ACT' => 'Broaden ACT range',
            'SAT_MATH' => 'Broaden SAT Math range',
            'SAT_VERBAL' => 'Broaden SAT Verbal range',
            'TEST_OPTIONAL' => 'Include test-optional schools'
        };
        return labels.get(rt) != null ? labels.get(rt) : rt;
    }

    // --- Wrapper classes ---

    public class CriteriaInput {
        @AuraEnabled public Double gpaLow;
        @AuraEnabled public Double gpaHigh;
        @AuraEnabled public Double actLow;
        @AuraEnabled public Double actHigh;
        @AuraEnabled public Double satMathLow;
        @AuraEnabled public Double satMathHigh;
        @AuraEnabled public Double satVerbalLow;
        @AuraEnabled public Double satVerbalHigh;
        @AuraEnabled public Boolean testScoresOptional;
        @AuraEnabled public List<String> regions;
        @AuraEnabled public List<String> sizes;
        @AuraEnabled public List<String> collegeSettings;
        @AuraEnabled public String collegeSetting;
        /** When true (diagnostic/simulator), skip test filter when no test criteria provided. */
        @AuraEnabled public Boolean diagnosticMode;

        public CriteriaInput copy() {
            CriteriaInput c = new CriteriaInput();
            c.gpaLow = this.gpaLow;
            c.gpaHigh = this.gpaHigh;
            c.actLow = this.actLow;
            c.actHigh = this.actHigh;
            c.satMathLow = this.satMathLow;
            c.satMathHigh = this.satMathHigh;
            c.satVerbalLow = this.satVerbalLow;
            c.satVerbalHigh = this.satVerbalHigh;
            c.testScoresOptional = this.testScoresOptional;
            c.regions = this.regions != null ? new List<String>(this.regions) : null;
            c.sizes = this.sizes != null ? new List<String>(this.sizes) : null;
            c.collegeSettings = this.collegeSettings != null ? new List<String>(this.collegeSettings) : null;
            c.collegeSetting = this.collegeSetting;
            c.diagnosticMode = this.diagnosticMode;
            return c;
        }

        public void applyRelaxation(String type) {
            if (type == 'LOCATION') {
                regions = new List<String>{ 'Far West', 'Rocky Mountains', 'Southeast', 'Mid East', 'Southwest', 'Plains', 'Great Lakes', 'New England' };
            } else if (type == 'COLLEGE_SETTING') {
                collegeSettings = new List<String>{ 'Rural', 'Town', 'Suburban', 'Urban' };
                collegeSetting = null;
            } else if (type == 'COLLEGE_SIZE') {
                sizes = new List<String>{ 'Small', 'Medium', 'Large' };
            } else if (type == 'GPA' && gpaLow != null) {
                gpaLow = Math.max(0, gpaLow - 0.5);
            } else if (type == 'ACT' && actLow != null) {
                actLow = Math.max(0, actLow - 2);
            } else if (type == 'SAT_MATH' && satMathLow != null) {
                satMathLow = Math.max(0, satMathLow - 50);
            } else if (type == 'SAT_VERBAL' && satVerbalLow != null) {
                satVerbalLow = Math.max(0, satVerbalLow - 50);
            } else if (type == 'TEST_OPTIONAL') {
                testScoresOptional = true;
            }
        }
    }

    private static Double parsePicklistNumber(String val, Boolean useFirst) {
        if (String.isBlank(val)) return null;
        try {
            List<String> parts = val.split('-|–|to');
            String numStr = (useFirst ? parts[0] : parts[parts.size() - 1]).trim().replaceAll('[^0-9.]', '');
            return String.isNotBlank(numStr) ? Double.valueOf(numStr) : null;
        } catch (Exception e) {
            return null;
        }
    }

    public class MatchPreviewResult {
        @AuraEnabled public Integer matchCount;
        @AuraEnabled public Boolean canSubmit;
        @AuraEnabled public List<String> suggestions;
        @AuraEnabled public ZeroMatchFeedback zeroMatchFeedback;
    }

    public class ZeroMatchFeedback {
        @AuraEnabled public String criteriaSummary;
        @AuraEnabled public List<String> possibleCauses;
        @AuraEnabled public List<String> nextSteps;
    }

    public class AccountMatchResult {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String rightFitMatchColor;
        @AuraEnabled public Double medianGpa;
        @AuraEnabled public Double medianAct;
        @AuraEnabled public Double medianSatMath;
        @AuraEnabled public Double medianSatVerbal;
        @AuraEnabled public String geographicalRegion;
        @AuraEnabled public String collegeSizeFormula;
        @AuraEnabled public String collegeSetting;
        @AuraEnabled public Boolean testScoresOptional;
    }

    public class SuggestedCriteria {
        @AuraEnabled public String relaxationType;
        @AuraEnabled public String label;
        @AuraEnabled public Integer newMatchCount;
        @AuraEnabled public Integer improvement;
        @AuraEnabled public List<String> suggestions;
    }

    public class PermutationResult {
        @AuraEnabled public Integer matchCount;
        @AuraEnabled public String relaxationType;
        @AuraEnabled public List<String> suggestions;
    }
}
