global class CustomEmail {

    global static List<User> rep = new List<User>();

    @InvocableMethod
    public static void sendTermsEmail(List<EmailRequest> requests) {

        List<Messaging.SingleEmailMessage> termsEmails = new List<Messaging.SingleEmailMessage>();
        // List<Attachment> atts = new List<Attachment>();
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        List<ContentVersion> termsDocs = [SELECT Title, VersionData, ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE Title LIKE '%2025_terms%'];

        for (EmailRequest request : requests) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // LIVE
            mail.setOrgWideEmailAddressId('0D2Pz0000000l0XKAQ');
            // FALDEV
            // mail.setOrgWideEmailAddressId('0D2Pv0000000mJBKAY');

            if (request.toAddress != null) {
                mail.setToAddresses(new String[] { request.toAddress });
                mail.setBccAddresses(new String[] { 'jjohnston@falconfoodservice.com', 'lfleming@falconfoodservice.com' });

                // FALDEV
                // String EmailTemplateId = '00XPv000002I0ekMAC';
                // LIVE
                String EmailTemplateId = '00XPz000009GAUVMA4';
            
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

                Account accountId = request.accountIds[0];

                // render the email template into an instance of Messaging.SingleEmailMessage
                Messaging.SingleEmailMessage renderResult = Messaging.renderStoredEmailTemplate(
                    EmailTemplateId,
                    NULL,
                    accountId.Id
                );

                mail.setSubject(renderResult.getSubject());
                mail.setHtmlBody(renderResult.getHtmlBody());
                mail.setSaveAsActivity(false);
                
                // List<User> rep = [SELECT Username FROM User WHERE Id = :accountId.OwnerId LIMIT 1];
                if (!CustomEmail.rep.isEmpty()) {
                    mail.setCcAddresses(new String[] { CustomEmail.rep[0].Username });
                }

                List<ContentVersion> doc = new List<ContentVersion>();
                for (ContentVersion terms : termsDocs) {
                    if (terms.FirstPublishLocationId == accountId.Id) {
                        doc.add(terms);
                    }
                }
                if (!doc.isEmpty()) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment(); 
                    String title = doc[0].Title + '.pdf';
                    attachment.setFileName(title);
                    attachment.setBody(doc[0].VersionData);
                    attachment.setContentType('application/pdf');
                    attachments.add(attachment);
                } 
                if (!attachments.isEmpty()) {
                    mail.setFileAttachments(attachments);
                    // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    termsEmails.add(mail);

                    // create email message for tracking
                    EmailMessage emailMessage = new EmailMessage();
                    emailMessage.Subject = renderResult.getSubject();
                    emailMessage.HtmlBody = renderResult.getHtmlBody();
                    emailMessage.ToAddress = request.toAddress;
                    if (!CustomEmail.rep.isEmpty()) {
                        emailMessage.CcAddress = CustomEmail.rep[0].Username;
                    }
                    emailMessage.RelatedToId = accountId.Id;
                    emailMessage.Status = '3'; // status 3 = sent
                    emailMessage.IsTracked = true;

                    emailMessages.add(emailMessage);

                    // Attachment attachment = new Attachment();
                    // attachment.ParentId = emailMessage.Id;
                    // attachment.Name = doc[0].Title + '.pdf';
                    // attachment.ContentType = 'application/pdf';
                    // attachment.Body = doc[0].VersionData;

                    // atts.add(attachment); 
                }
            }
        }
        if (!termsEmails.isEmpty()) {
            Messaging.sendEmail(termsEmails);
            insert emailMessages;
        }
    }

    public static void terms_FullRun(Id UserId) {
        // takes in a user id to get all their account for sending terms 
        List<EmailRequest> requests = new List<EmailRequest>();
        CustomEmail.rep = [SELECT Username FROM User WHERE Id = :UserId LIMIT 1];
        List<Account> accounts = [SELECT Id, Name, OwnerId, Email__c FROM Account WHERE OwnerId = :UserId AND On_Hold__c != 'On Hold' 
                                AND AccountNumber NOT IN ('0000049','0002821','0000778','0000079','0006792','0000666','0001321','0002334'
                                ,'0003370','0003903','0004356','0000250','0001649','0000204','0004847','0000039','0004243','0000517','0000014'
                                ,'0001239','0001986') AND AccountNumber != '' AND Email__c != ''];
        if (!accounts.isEmpty()) {
            for (Account acc : accounts) {
                List<Account> recipients = new List<Account> { acc };
                String toAddress = acc.Email__c;

                EmailRequest req = new EmailRequest(toAddress, null, null, recipients);
                requests.add(req);
            }

            CustomEmail.sendTermsEmail(requests);
        }

    }

    public static void test() {
        System.debug('Hello World');
    }
}