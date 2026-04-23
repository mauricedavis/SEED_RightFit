/**
 * Runs after Flow commit. For Experience Cloud (Customer Community) users, Salesforce recommends
 * System.resetPasswordWithEmailTemplate over System.resetPassword — the latter often does not send mail
 * for external users even when it does not throw.
 *
 * Template resolution tries common Experience Cloud forgot-password template DeveloperNames, then
 * plain resetPassword. Uses without sharing so automation can act on community User records.
 */
public without sharing class UserPasswordResetQueueable implements Queueable {
    private static final List<String> TEMPLATE_DEVELOPER_NAMES = new List<String>{
        'CommunityHeadlessForgotPasswordTemplate',
        'CommunityForgotPasswordEmailTemplate',
        /* Optional: clone your site's Forgot Password template with this API name if standards are missing */
        'SEED_Community_Forgot_Password'
    };

    private final List<Id> userIds;

    public UserPasswordResetQueueable(List<Id> userIds) {
        this.userIds = userIds == null ? new List<Id>() : userIds;
    }

    public void execute(QueueableContext context) {
        Map<String, EmailTemplate> templatesByDev = loadCandidateTemplates();
        List<String> attemptNames = buildTemplateApiNameAttempts(templatesByDev);

        for (Id userId : userIds) {
            if (userId == null) {
                continue;
            }
            if (attemptNames.isEmpty()) {
                System.resetPassword(userId, true);
                continue;
            }
            Boolean templateWorked = false;
            Exception templateError;
            for (String apiName : attemptNames) {
                try {
                    System.resetPasswordWithEmailTemplate(userId, true, apiName);
                    templateWorked = true;
                    break;
                } catch (Exception e) {
                    templateError = e;
                }
            }
            if (!templateWorked) {
                try {
                    System.resetPassword(userId, true);
                } catch (Exception e) {
                    throw templateError != null ? templateError : e;
                }
            }
        }
    }

    private static Map<String, EmailTemplate> loadCandidateTemplates() {
        Map<String, EmailTemplate> byDev = new Map<String, EmailTemplate>();
        for (EmailTemplate t : [
            SELECT DeveloperName, FolderName
            FROM EmailTemplate
            WHERE DeveloperName IN :TEMPLATE_DEVELOPER_NAMES AND IsActive = TRUE
        ]) {
            byDev.put(t.DeveloperName, t);
        }
        return byDev;
    }

    /**
     * resetPasswordWithEmailTemplate expects the template "API name", often FolderName/DeveloperName
     * or unfiled$public/DeveloperName. Try several shapes per template row.
     */
    private static List<String> buildTemplateApiNameAttempts(Map<String, EmailTemplate> templatesByDev) {
        List<String> attempts = new List<String>();
        Set<String> seen = new Set<String>();
        for (String dev : TEMPLATE_DEVELOPER_NAMES) {
            EmailTemplate t = templatesByDev.get(dev);
            if (t == null) {
                continue;
            }
            addAttempt(attempts, seen, t.DeveloperName);
            addAttempt(attempts, seen, 'unfiled$public/' + t.DeveloperName);
            if (String.isNotBlank(t.FolderName)) {
                addAttempt(attempts, seen, t.FolderName + '/' + t.DeveloperName);
            }
        }
        return attempts;
    }

    private static void addAttempt(List<String> attempts, Set<String> seen, String name) {
        if (String.isBlank(name) || seen.contains(name)) {
            return;
        }
        seen.add(name);
        attempts.add(name);
    }
}
