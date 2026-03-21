/**
 * Test class for RightFitMatchFunnel - funnel analysis for college matching.
 */
@IsTest
private class RightFitMatchFunnelTest {
    @IsTest
    static void testRun() {
        Test.startTest();
        RightFitMatchFunnel.run();
        Test.stopTest();
    }

    @IsTest
    static void testRunWithDataFullPath() {
        RightFitMatchFunnel.FunnelRow a = new RightFitMatchFunnel.FunnelRow();
        a.name = 'A';
        a.color = 'Yellow';
        a.gpa = 3.5;
        a.act = 24.0;
        a.testOpt = false;
        a.region = 'Southeast';
        a.size = 'SizeMedium';
        a.setting = 'Urban';
        RightFitMatchFunnel.FunnelRow b = new RightFitMatchFunnel.FunnelRow();
        b.name = 'B';
        b.color = 'Green';
        b.gpa = 3.0;
        b.act = null;
        b.testOpt = true;
        b.region = 'Mid East';
        b.size = 'SizeSmall';
        b.setting = 'Suburban';
        List<RightFitMatchFunnel.FunnelRow> rows = new List<RightFitMatchFunnel.FunnelRow>{ a, b };
        Test.startTest();
        RightFitMatchFunnel.runWithData(rows);
        Test.stopTest();
    }

    @IsTest
    static void testRunWithDataColorBottleneck() {
        RightFitMatchFunnel.FunnelRow r = new RightFitMatchFunnel.FunnelRow();
        r.name = 'X';
        r.color = 'Red';
        r.gpa = 3.5;
        r.act = 24.0;
        r.testOpt = false;
        r.region = 'Southeast';
        r.size = 'SizeMedium';
        r.setting = 'Urban';
        Test.startTest();
        RightFitMatchFunnel.runWithData(new List<RightFitMatchFunnel.FunnelRow>{ r });
        Test.stopTest();
    }

    @IsTest
    static void testRunWithDataGpaBottleneck() {
        RightFitMatchFunnel.FunnelRow r = new RightFitMatchFunnel.FunnelRow();
        r.name = 'X';
        r.color = 'Yellow';
        r.gpa = 1.5;
        r.act = null;
        r.testOpt = false;
        r.region = 'Southeast';
        r.size = 'SizeMedium';
        r.setting = 'Urban';
        Test.startTest();
        RightFitMatchFunnel.runWithData(new List<RightFitMatchFunnel.FunnelRow>{ r });
        Test.stopTest();
    }

    @IsTest
    static void testRunWithDataTestBottleneck() {
        RightFitMatchFunnel.FunnelRow r = new RightFitMatchFunnel.FunnelRow();
        r.name = 'X';
        r.color = 'Yellow';
        r.gpa = 3.5;
        r.act = 10.0;
        r.testOpt = false;
        r.region = 'Southeast';
        r.size = 'SizeMedium';
        r.setting = 'Urban';
        Test.startTest();
        RightFitMatchFunnel.runWithData(new List<RightFitMatchFunnel.FunnelRow>{ r });
        Test.stopTest();
    }

    @IsTest
    static void testRunWithDataLocationBottleneck() {
        RightFitMatchFunnel.FunnelRow r = new RightFitMatchFunnel.FunnelRow();
        r.name = 'X';
        r.color = 'Yellow';
        r.gpa = 3.5;
        r.act = 24.0;
        r.testOpt = false;
        r.region = null;
        r.size = null;
        r.setting = null;
        Test.startTest();
        RightFitMatchFunnel.runWithData(new List<RightFitMatchFunnel.FunnelRow>{ r });
        Test.stopTest();
    }
}
