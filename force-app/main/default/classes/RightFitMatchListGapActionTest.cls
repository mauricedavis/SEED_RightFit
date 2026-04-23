/**
 * Tests for RightFitMatchListGapAction (bulk SRL de-dupe for the Creating Right Fit match flow).
 */
@IsTest
private class RightFitMatchListGapActionTest {
    @IsTest
    static void testNullRequestGivesEmpty() {
        List<RightFitMatchListGapAction.Result> res = RightFitMatchListGapAction.filterGaps(
            new List<RightFitMatchListGapAction.Request>{ null }
        );
        System.assertEquals(1, res.size());
        System.assertNotEquals(null, res[0].collegesToCreate, 'List should be initialized');
        System.assertEquals(0, res[0].collegesToCreate.size());
    }

    @IsTest
    static void testEmptyInputCollegesGivesEmpty() {
        Contact c = new Contact(FirstName = 'RFGap', LastName = 'RFGapT');
        insert c;
        RightFitMatchListGapAction.Request q = new RightFitMatchListGapAction.Request();
        q.contactId = c.Id;
        q.matchedColleges = new List<Account>();
        List<RightFitMatchListGapAction.Result> res = RightFitMatchListGapAction.filterGaps(
            new List<RightFitMatchListGapAction.Request>{ q }
        );
        System.assertEquals(0, res[0].collegesToCreate.size());
    }

    @IsTest
    static void testReturnsUnmatchedColleges() {
        Contact c = new Contact(FirstName = 'RFGap2', LastName = 'RFGapT2');
        insert c;
        Account a1 = new Account(Name = 'RFGap College 1');
        Account a2 = new Account(Name = 'RFGap College 2');
        insert new List<Account>{ a1, a2 };
        // No SRL yet — should get both
        RightFitMatchListGapAction.Request q = new RightFitMatchListGapAction.Request();
        q.contactId = c.Id;
        q.matchedColleges = new List<Account>{ a1, a2 };
        List<RightFitMatchListGapAction.Result> res = RightFitMatchListGapAction.filterGaps(
            new List<RightFitMatchListGapAction.Request>{ q }
        );
        System.assertEquals(2, res[0].collegesToCreate.size(), 'Both colleges should be returned when no SRL exists');
    }
}
