/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CustomEmailTest {

    @isTest
    static void testSendTermsEmail() {
        Account testAccount = new Account(
            Name = 'Test Account',
            ShippingPostalCode = '1234');
        insert testAccount;

        ContentVersion testContent = new ContentVersion(
            Title = '2025_terms_TEST_ACCOUNT_(0000000)',
            VersionData = Blob.valueOf('Test Content'),
            FirstPublishLocationId = testAccount.Id,
            PathOnClient = '2025_terms_TEST_ACCOUNT_(0000000).pdf'
        );
        insert testContent;

        EmailRequest request = new EmailRequest('test@example.com', 'Test Subject', 'Test Body', new List<Account>{testAccount});
        List<EmailRequest> requests = new List<EmailRequest>{request};

        Test.startTest();
        Integer emailInvocationsBefore = Limits.getEmailInvocations();
        CustomEmail.sendTermsEmail(requests);
        Integer emailInvocationsAfter = Limits.getEmailInvocations();
        Test.stopTest();

        // verify email was sent
        System.assertEquals(emailInvocationsBefore + 1, emailInvocationsAfter);

        // verify attachment
        List<ContentVersion> docs = [SELECT Title, VersionData, FileExtension FROM ContentVersion WHERE FirstPublishLocationId = :testAccount.Id AND Title LIKE '%terms%'];
        System.assertEquals(1, docs.size());
        System.assertEquals('2025_terms_TEST_ACCOUNT_(0000000).pdf', docs[0].Title + '.' + docs[0].FileExtension);
        System.assertEquals('Test Content', docs[0].VersionData.toString());
    }

    @isTest
    static void testEmptyRequestList() {
        Test.startTest();
        CustomEmail.sendTermsEmail(new List<EmailRequest>());
        Test.stopTest();
        // verify no emails were sent 
        System.assertEquals(0, Limits.getEmailInvocations());
    }
}