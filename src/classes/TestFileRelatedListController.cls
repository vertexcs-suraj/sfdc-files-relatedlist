/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestFileRelatedListController {

    @testsetup static void setupTestData() {
    
         Account acct = new Account(Name='Test Account',Account_Legal_Name__c = 'Test Legal Account',Industry='Energy');
         insert acct;
         
         
         
         Blob fileBody = Blob.valueOf('TestFileAttachement.xls');
         
         ContentVersion cv = new ContentVersion(title='TestFile2',PathOnCLient='TestFile2',VersionData=fileBody,isMajorVersion=true);
         insert cv;
         
         cv=[Select ContentDocumentId from ContentVersion where Id=:cv.Id];
         
         ContentDocumentLink cdl=  new ContentDocumentLink(ContentDocumentId=cv.ContentDocumentId,
                                               LinkedEntityId=acct.Id,ShareType='I');
         insert cdl;
         
        
         
          cv = new ContentVersion(title='TestFile3',PathOnCLient='TestFile3',VersionData=fileBody,ReasonForChange='New version');
         insert cv;
         
           cv=[Select ContentDocumentId from ContentVersion where Id=:cv.Id];
           
           List<ContentVersion> cvlist = [Select contentDocumentId, title from ContentVersion];
           
           System.Debug(cvlist);  
            
        
          cdl=  new ContentDocumentLink(ContentDocumentId=cv.contentDocumentId,
                                               LinkedEntityId=acct.Id,ShareType='I');
         insert cdl;
         
         
    }
    
    static testMethod void testShowFiles() {
    
         Account acct  = [Select Id, (Select Id,Title,CreatedBy.Name,CreatedDate,ContentDocumentId from attachedcontentdocuments)
                                      from Account where Name='Test Account' LIMIT 1];
         ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(acct);
         FileRelatedListController frlc = new FileRelatedListController(sc);
         
         
         System.Debug('acct = '+acct+' '+acct.attachedcontentdocuments);
         
          Id[] latestVersionIds = new Id[]{};
        for(attachedcontentdocument ad:acct.attachedcontentdocuments){
              System.Debug('ad = ' +ad);
        }
         
         frlc.showFiles();
         
         //System.assert(frlc.theFiles.size() > 0);
         //System.assert(frlc.theDocs.size() > 0);
    
    }
    
    static testMethod void testsaveNewFile() {
        // TO DO: implement unit test 
        
         
         
         Account acct  = [Select Id, (Select Id,Title,CreatedBy.Name,CreatedDate,ContentDocumentId from attachedcontentdocuments)
                                      from Account where Name='Test Account' LIMIT 1];
         
          
         ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(acct);
         FileRelatedListController frlc = new FileRelatedListController(sc);
         
         // Test Case Scenario - Create new document.The docid parameter will not be passed to the method to indicate that
         // the incoming request is for creating a new document.Expected result is that the method creates new content version
         // and new document link along with sharing set to Inferred (Set by Record).
         frlc.fileName = 'Test File.xls';
         frlc.fileBody = Blob.valueOf('Test Attachment'); 
         frlc.reasonForChange = null;        
         String retURL = frlc.saveNewFile().getURL();
         System.assertEquals('/apex/filerelatedlistpage?Id='+acct.id,retURL);
        
         ContentVersion newFile = [Select ContentDocumentId,Title,PathOnclient,VersionData,isMajorVersion,ReasonForChange from ContentVersion where title='Test File.xls'];
         
         // Assert that the new file has been uploaded and has a content version
         System.assertEquals('Test File.xls',newFile.PathOnClient);         
         System.assertEquals(true,newFile.isMajorVersion);
      
         
         ContentDocumentLink newFileLink = [Select ContentDocumentId,LinkedEntityId,ShareType from ContentDocumentLink where ContentDocumentId = :newFile.ContentDocumentId and linkedEntityId = :acct.id];
         
         System.Debug('newFileLink = '+newFileLink);
          
         
         // Assert that the document has a valid link along with Inferred sharing type assigned to it 
         System.assertEquals(acct.id,newFileLink.LinkedEntityId); 
         System.assertEquals('I',newFileLink.ShareType);
         
         ContentDocument doc = [Select SharingOption from ContentDocument where id = :newFile.ContentDocumentId];
         
         // Assert that the document sharing option is set to Restricted 
         System.assertEquals('R',doc.SharingOption);
         
         
         frlc.reasonForChange = 'New Updated Version';
         ApexPages.currentPage().getParameters().put('docId',newFile.ContentDocumentId);
         retURL = frlc.saveNewFile().getURL();
         System.assertEquals('/apex/filerelatedlistpage?Id='+acct.id,retURL);
        
         ContentVersion versionFile = [Select ContentDocumentId,Title,PathOnclient,VersionData,isMajorVersion,VersionNumber from ContentVersion where title='Test File.xls' and VersionNumber = '2'];
         System.assertEquals('2',versionFile.VersionNumber);
         
         
         
        
    }
}
