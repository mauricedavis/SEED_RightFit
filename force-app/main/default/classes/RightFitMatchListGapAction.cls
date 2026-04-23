/**
 * Used by the auto-launched flow "Creating Right Fit Match Records" to avoid running a
 * Get Records on Student Right Fit List inside a loop (1 SOQL per college → 101 limit when
 * many schools match, e.g. after widening GPA criteria with an optional low GPA).
 */
public with sharing class RightFitMatchListGapAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id contactId;

        @InvocableVariable(required=true)
        public List<Account> matchedColleges;
    }

    public class Result {
        @InvocableVariable
        public List<Account> collegesToCreate;
    }

    @InvocableMethod(label='Filter to colleges not yet on Student Right Fit')
    public static List<Result> filterGaps(List<Request> requests) {
        List<Result> out = new List<Result>();
        if (requests == null) {
            return out;
        }
        for (Request req : requests) {
            out.add(gapForRequest(req));
        }
        return out;
    }

    private static Result gapForRequest(Request req) {
        Result r = new Result();
        r.collegesToCreate = new List<Account>();
        if (req == null || req.contactId == null || req.matchedColleges == null || req.matchedColleges.isEmpty()) {
            return r;
        }
        Set<Id> collegeIds = new Set<Id>();
        for (Account a : req.matchedColleges) {
            if (a != null && a.Id != null) {
                collegeIds.add(a.Id);
            }
        }
        if (collegeIds.isEmpty()) {
            return r;
        }
        Set<Id> haveList = new Set<Id>();
        for (Student_Right_Fit_List__c s : [
            SELECT College_Match__c
            FROM Student_Right_Fit_List__c
            WHERE Student__c = :req.contactId AND College_Match__c IN :collegeIds
        ]) {
            if (s.College_Match__c != null) {
                haveList.add(s.College_Match__c);
            }
        }
        List<Id> inOrder = new List<Id>();
        for (Account a : req.matchedColleges) {
            if (a != null && a.Id != null && !haveList.contains(a.Id)) {
                inOrder.add(a.Id);
            }
        }
        if (inOrder.isEmpty()) {
            return r;
        }
        Map<Id, Account> reQuery = new Map<Id, Account>([
            SELECT Id, Name, Common_App_Link__c, Common_App_School__c, School_Application_Info__c
            FROM Account
            WHERE Id IN :inOrder
        ]);
        for (Id colId : inOrder) {
            if (reQuery.containsKey(colId)) {
                r.collegesToCreate.add(reQuery.get(colId));
            }
        }
        return r;
    }
}
