public class EmailRequest {
    @AuraEnabled
    @InvocableVariable
    public String toAddress;
    @AuraEnabled
    @InvocableVariable
    public String subject;
    @AuraEnabled
    @InvocableVariable
    public String body;
    @AuraEnabled
    @InvocableVariable
    public List<Account> accountIds;

    public EmailRequest(String toAddress, String subject, String body, List<Account> accountIds) {
        this.toAddress = toAddress;
        this.subject = subject;
        this.body = body;
        this.accountIds = accountIds;
    }
}