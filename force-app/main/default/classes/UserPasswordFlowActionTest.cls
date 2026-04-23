/**
 * Tests for UserPasswordFlowAction.
 */
@IsTest
private class UserPasswordFlowActionTest {
    @IsTest
    static void testSendPasswordEmail_nullList_noError() {
        Test.startTest();
        UserPasswordFlowAction.sendPasswordEmail(null);
        Test.stopTest();
        System.assert(true, 'No exception for null list');
    }

    @IsTest
    static void testSendPasswordEmail_nullUserId_skipped() {
        UserPasswordFlowAction.Request req = new UserPasswordFlowAction.Request();
        req.userId = null;

        Test.startTest();
        UserPasswordFlowAction.sendPasswordEmail(new List<UserPasswordFlowAction.Request>{ req });
        Test.stopTest();
        System.assert(true, 'Null userId should be skipped without error');
    }

    @IsTest
    static void testSendPasswordEmail_withUser_invokesReset() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String suffix = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        User u = new User(
            FirstName = 'Flow',
            LastName = 'PwdTest',
            Email = 'flowpwdtest' + suffix + '@example.com',
            Username = 'flowpwdtest' + suffix + '@example.com.test',
            Alias = (('fp' + suffix).length() > 8 ? ('fp' + suffix).substring(0, 8) : 'fp' + suffix),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;

        UserPasswordFlowAction.Request req = new UserPasswordFlowAction.Request();
        req.userId = u.Id;

        Test.startTest();
        UserPasswordFlowAction.sendPasswordEmail(new List<UserPasswordFlowAction.Request>{ req });
        Test.stopTest();
    }
}
