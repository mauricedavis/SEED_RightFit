/**
 * Invocable action for Flow: enqueues UserPasswordResetQueueable (after commit) for the set-password email.
 * Queueable prefers resetPasswordWithEmailTemplate for Experience Cloud users when a matching EmailTemplate
 * exists, then falls back to resetPassword. Synchronous reset in the User flow can hit INVALID_ENTITY_FOR_WHATID.
 *
 * Permissions: The enqueueing user must be allowed to reset the target users password
 * (typically Reset User Passwords and Unlock Users / Manage Users).
 */
public with sharing class UserPasswordFlowAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id userId;
    }

    @InvocableMethod(label='Send New User Password Email')
    public static void sendPasswordEmail(List<Request> requests) {
        if (requests == null) {
            return;
        }
        List<Id> userIds = new List<Id>();
        for (Request req : requests) {
            if (req != null && req.userId != null) {
                userIds.add(req.userId);
            }
        }
        if (userIds.isEmpty()) {
            return;
        }
        System.enqueueJob(new UserPasswordResetQueueable(userIds));
    }
}
