/**
 * Right Fit College Data Diagnostic
 * Run in Developer Console → Debug → Open Execute Anonymous Window
 * Paste and Execute to see what College data exists and why matches may fail.
 * Uses manual counting (no GROUP BY) to avoid formula/long-text field restrictions.
 */

List<Account> colleges = [
    SELECT Right_Fit_Match_Color_Automatic__c, Geographical_Region__c, College_Size_Formula__c,
           College_Setting__c, Test_Scores_Optional__c, Median_GPA__c, Name
    FROM Account
    WHERE RecordType.DeveloperName = 'College'
    LIMIT 10000
];

System.debug('=== Total College records: ' + colleges.size() + ' ===');

// Count by Color
Map<String, Integer> colorCounts = new Map<String, Integer>();
for (Account a : colleges) {
    String c = a.Right_Fit_Match_Color_Automatic__c != null ? a.Right_Fit_Match_Color_Automatic__c : '(null)';
    colorCounts.put(c, colorCounts.containsKey(c) ? colorCounts.get(c) + 1 : 1);
}
System.debug('=== Right_Fit_Match_Color_Automatic__c ===');
for (String c : colorCounts.keySet()) {
    System.debug('  [' + c + '] | Count: ' + colorCounts.get(c));
}

// Count by Region
Map<String, Integer> regionCounts = new Map<String, Integer>();
for (Account a : colleges) {
    String r = a.Geographical_Region__c != null ? a.Geographical_Region__c : '(null)';
    regionCounts.put(r, regionCounts.containsKey(r) ? regionCounts.get(r) + 1 : 1);
}
System.debug('=== Geographical_Region__c ===');
for (String r : regionCounts.keySet()) {
    System.debug('  [' + r + '] | Count: ' + regionCounts.get(r));
}

// Count by Size
Map<String, Integer> sizeCounts = new Map<String, Integer>();
for (Account a : colleges) {
    String s = a.College_Size_Formula__c != null ? a.College_Size_Formula__c : '(null)';
    sizeCounts.put(s, sizeCounts.containsKey(s) ? sizeCounts.get(s) + 1 : 1);
}
System.debug('=== College_Size_Formula__c ===');
for (String s : sizeCounts.keySet()) {
    System.debug('  [' + s + '] | Count: ' + sizeCounts.get(s));
}

// Count by Setting
Map<String, Integer> settingCounts = new Map<String, Integer>();
for (Account a : colleges) {
    String s = a.College_Setting__c != null ? a.College_Setting__c : '(null)';
    settingCounts.put(s, settingCounts.containsKey(s) ? settingCounts.get(s) + 1 : 1);
}
System.debug('=== College_Setting__c ===');
for (String s : settingCounts.keySet()) {
    System.debug('  [' + s + '] | Count: ' + settingCounts.get(s));
}

// Count by Test Optional (matchable colleges only)
Integer matchableCount = 0;
Integer testOptTrue = 0;
Integer testOptFalse = 0;
Integer testOptNull = 0;
for (Account a : colleges) {
    if (a.Right_Fit_Match_Color_Automatic__c == 'Yellow' || a.Right_Fit_Match_Color_Automatic__c == 'Green' ||
        a.Right_Fit_Match_Color_Automatic__c == 'SEEDMatchingYellow' || a.Right_Fit_Match_Color_Automatic__c == 'SEEDMatchGreenConstant') {
        matchableCount++;
        if (a.Test_Scores_Optional__c == true) testOptTrue++;
        else if (a.Test_Scores_Optional__c == false) testOptFalse++;
        else testOptNull++;
    }
}
System.debug('=== Matchable (Yellow/Green/SEEDMatchingYellow/SEEDMatchGreenConstant): ' + matchableCount + ' ===');
System.debug('  Test_Scores_Optional__c = true: ' + testOptTrue);
System.debug('  Test_Scores_Optional__c = false: ' + testOptFalse);
System.debug('  Test_Scores_Optional__c = null: ' + testOptNull);

// Sample records that pass color filter
System.debug('=== Sample matchable colleges (first 5) ===');
Integer shown = 0;
for (Account a : colleges) {
    if (shown >= 5) break;
    if (a.Right_Fit_Match_Color_Automatic__c == 'Yellow' || a.Right_Fit_Match_Color_Automatic__c == 'Green' ||
        a.Right_Fit_Match_Color_Automatic__c == 'SEEDMatchingYellow' || a.Right_Fit_Match_Color_Automatic__c == 'SEEDMatchGreenConstant') {
        System.debug(a.Name + ' | Color:' + a.Right_Fit_Match_Color_Automatic__c + ' | Region:' + a.Geographical_Region__c + ' | Size:' + a.College_Size_Formula__c + ' | Setting:' + a.College_Setting__c + ' | TestOpt:' + a.Test_Scores_Optional__c + ' | GPA:' + a.Median_GPA__c);
        shown++;
    }
}
if (matchableCount == 0) {
    System.debug('NO RECORDS pass the color filter. Check Right_Fit_Match_Color_Automatic__c values above.');
}
