/**
 * Test class for RightFitMatchService
 */
@IsTest
private class RightFitMatchServiceTest {
    @IsTest
    static void testGetMatchPreview() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.gpaLow = 2.5;
        criteria.gpaHigh = 4.0;
        criteria.testScoresOptional = true;
        criteria.regions = new List<String>{ 'Southeast', 'Mid East' };
        criteria.sizes = new List<String>{ 'Medium', 'Large' };
        criteria.collegeSetting = 'Urban';

        Test.startTest();
        RightFitMatchService.MatchPreviewResult result = RightFitMatchService.getMatchPreview(criteria);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.matchCount, 'Match count should not be null');
        System.assertNotEquals(null, result.canSubmit, 'CanSubmit should not be null');
        System.assertNotEquals(null, result.suggestions, 'Suggestions should not be null');
    }

    @IsTest
    static void testGetMatchPreviewNullCriteria() {
        Test.startTest();
        RightFitMatchService.MatchPreviewResult result = RightFitMatchService.getMatchPreview(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.matchCount, 'Match count should be 0 for null criteria');
        System.assertEquals(false, result.canSubmit, 'CanSubmit should be false');
    }

    @IsTest
    static void testGetMatchResults() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.testScoresOptional = true;
        criteria.regions = new List<String>{ 'Southeast' };
        criteria.sizes = new List<String>{ 'Small', 'Medium', 'Large' };

        Test.startTest();
        List<RightFitMatchService.AccountMatchResult> results = RightFitMatchService.getMatchResults(criteria);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @IsTest
    static void testGetMatchResultsBySelections() {
        Test.startTest();
        List<RightFitMatchService.AccountMatchResult> results = RightFitMatchService.getMatchResultsBySelections(
            new List<String>{ 'Far West' }, new List<String>(), new List<String>(), false,
            null, null, null, null, null, null, null, null
        );
        RightFitMatchService.MatchPreviewResult preview = RightFitMatchService.getMatchPreviewBySelections(
            new List<String>{ 'Far West' }, new List<String>(), new List<String>(), false,
            null, null, null, null, null, null, null, null
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertNotEquals(null, preview, 'Preview should not be null');
    }

    @IsTest
    static void testGetMatchResultsBySelectionsWithGpa() {
        Test.startTest();
        List<RightFitMatchService.AccountMatchResult> results = RightFitMatchService.getMatchResultsBySelections(
            new List<String>{ 'Far West' }, new List<String>(), new List<String>(), false,
            2.5, 4.0, null, null, null, null, null, null
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        for (RightFitMatchService.AccountMatchResult r : results) {
            if (r.medianGpa != null) {
                System.assert(r.medianGpa >= 2.5 && r.medianGpa <= 4.0, 'GPA should be in range when filter applied');
            }
        }
    }

    @IsTest
    static void testRunPermutation() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.gpaLow = 3.0;
        criteria.gpaHigh = 4.0;
        criteria.regions = new List<String>{ 'Southeast' };
        criteria.sizes = new List<String>{ 'Medium' };

        Test.startTest();
        RightFitMatchService.PermutationResult result = RightFitMatchService.runPermutation(criteria, 'LOCATION');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('LOCATION', result.relaxationType, 'Relaxation type should match');
    }

    @IsTest
    static void testGetSuggestedCriteria() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.gpaLow = 3.5;
        criteria.gpaHigh = 4.0;
        criteria.regions = new List<String>{ 'New England' };
        criteria.sizes = new List<String>{ 'Small' };

        Test.startTest();
        List<RightFitMatchService.SuggestedCriteria> suggestions = RightFitMatchService.getSuggestedCriteria(criteria);
        Test.stopTest();

        System.assertNotEquals(null, suggestions, 'Suggestions should not be null');
    }

    @IsTest
    static void testLoadCriteriaFromRecordNull() {
        Test.startTest();
        RightFitMatchService.CriteriaInput result = RightFitMatchService.loadCriteriaFromRecord(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void testCriteriaInputCopy() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.gpaLow = 3.0;
        criteria.gpaHigh = 3.5;
        criteria.regions = new List<String>{ 'Southeast' };

        RightFitMatchService.CriteriaInput copy = criteria.copy();

        System.assertNotEquals(null, copy, 'Copy should not be null');
        System.assertEquals(criteria.gpaLow, copy.gpaLow, 'GPA low should match');
        System.assertEquals(criteria.gpaHigh, copy.gpaHigh, 'GPA high should match');
    }

    @IsTest
    static void testRunPermutationAllRelaxationTypes() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.gpaLow = 3.0;
        criteria.gpaHigh = 4.0;
        criteria.actLow = 20.0;
        criteria.actHigh = 30.0;
        criteria.satMathLow = 500.0;
        criteria.satMathHigh = 600.0;
        criteria.satVerbalLow = 500.0;
        criteria.satVerbalHigh = 600.0;
        criteria.regions = new List<String>{ 'Southeast' };
        criteria.sizes = new List<String>{ 'Medium' };
        criteria.collegeSetting = 'Urban';

        for (String rt : new List<String>{ 'GPA', 'ACT', 'SAT_MATH', 'SAT_VERBAL', 'TEST_OPTIONAL', 'COLLEGE_SETTING', 'COLLEGE_SIZE' }) {
            RightFitMatchService.PermutationResult result = RightFitMatchService.runPermutation(criteria, rt);
            System.assertNotEquals(null, result, 'Result for ' + rt + ' should not be null');
            System.assertEquals(rt, result.relaxationType, 'Relaxation type should match');
        }
    }

    @IsTest
    static void testGetMatchSuggestionsViaPreview() {
        RightFitMatchService.CriteriaInput criteria = new RightFitMatchService.CriteriaInput();
        criteria.gpaLow = 2.5;
        criteria.gpaHigh = 4.0;
        criteria.testScoresOptional = true;
        criteria.regions = new List<String>{ 'Southeast' };
        criteria.sizes = new List<String>{ 'Small' };
        criteria.collegeSetting = null;

        RightFitMatchService.MatchPreviewResult result = RightFitMatchService.getMatchPreview(criteria);
        System.assertNotEquals(null, result.suggestions, 'Suggestions should not be null');
    }

    @IsTest
    static void testGetMatchResultsNullCriteria() {
        List<RightFitMatchService.AccountMatchResult> results = RightFitMatchService.getMatchResults(null);
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list for null criteria');
    }

    @IsTest
    static void testLoadCriteriaFromRecordInvalidId() {
        Id nonExistentId = (Id)('a0U000000000001AAA');
        RightFitMatchService.CriteriaInput result = RightFitMatchService.loadCriteriaFromRecord(nonExistentId);
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void testLoadCriteriaFromRecordWithData() {
        Student_Match_Criteria__c smc = new Student_Match_Criteria__c();
        smc.Test_Score_Optional_Schools__c = true;
        smc.College_Setting__c = 'Urban';
        smc.Southeast__c = true;
        smc.Mid_East__c = true;
        smc.Small_Less_than_5_000_Students__c = true;
        smc.Medium_5_000_to_15_000_Students__c = true;
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.Low_GPA_of_Accepted_Students__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.Low_GPA_of_Accepted_Students__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.High_GPA_Accet__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.High_GPA_Accet__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.ACT_Score_Low__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.ACT_Score_Low__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.ACT_Composite_Score__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.ACT_Composite_Score__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.SAT_Math_Low__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.SAT_Math_Low__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.SAT_Math_High__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.SAT_Math_High__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.SAT_Verbal_Low__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.SAT_Verbal_Low__c = pe.getValue(); break; }
        }
        for (Schema.PicklistEntry pe : Student_Match_Criteria__c.SAT_Verbal_High_Score__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { smc.SAT_Verbal_High_Score__c = pe.getValue(); break; }
        }
        insert smc;

        RightFitMatchService.CriteriaInput result = RightFitMatchService.loadCriteriaFromRecord(smc.Id);
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.regions.size(), 'Should have 2 regions');
        System.assertEquals(2, result.sizes.size(), 'Should have 2 sizes');
        System.assertNotEquals(null, result.collegeSettings, 'College settings should not be null');
        System.assertEquals(1, result.collegeSettings.size(), 'Should have 1 college setting');
        System.assertEquals('Urban', result.collegeSettings[0], 'College setting should match');
        System.assertEquals(true, result.testScoresOptional, 'Test optional should be true');
    }

    @IsTest
    static void testGetMatchPreviewByRecordId() {
        Student_Match_Criteria__c smc = new Student_Match_Criteria__c();
        smc.Test_Score_Optional_Schools__c = true;
        smc.Southeast__c = true;
        smc.Small_Less_than_5_000_Students__c = true;
        smc.Urban__c = true;
        insert smc;

        Test.startTest();
        RightFitMatchService.MatchPreviewResult result = RightFitMatchService.getMatchPreviewByRecordId(smc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.suggestions, 'Suggestions should not be null');
    }
}
