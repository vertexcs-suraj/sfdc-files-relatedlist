public with sharing class FileRelatedListController {

    private Account theAccount;
    public ContentVersion[] theFiles{get;set;}
    public ContentDocument[] theDocs{get;set;}
    public Blob fileBody{get;set;}
    public String fileName{get;set;}
    public String fileContentType{get;set;}
    public Map<Id,boolean> hasEditAccessMap{get;set;}
    public String reasonForChange{get;set;}
    
    public FileRelatedListController(ApexPages.StandardController theController){
        theAccount=(Account)theController.getRecord();
    }
    
    public PageReference saveNewFile(){
        try{
            ContentVersion newFile;
            String documentIdUpload=ApexPages.currentPage().getParameters().get('docId');
            reasonForChange=(reasonForChange==null||reasonForChange.trim().length()==0)?'Uploaded New Version':reasonForChange;
            
            if(documentIdUpload==null){
                system.debug('Creating new document');
                newFile=new ContentVersion(Title=fileName,PathOnCLient=fileName,VersionData=fileBody,IsMajorVersion=true);
            }else{
                system.debug('Creating new version');
                newFile=new ContentVersion(Title=fileName,PathOnCLient=fileName,VersionData=fileBody,
                                          ContentDocumentId=documentIdUpload,ReasonForChange=reasonForChange);
            }
        	reasonForChange='';
        	insert newFile;
            if(documentIdUpload==null){
                newFile=[Select ContentDocumentId from ContentVersion where Id=:newfile.Id];
                insert new ContentDocumentLink(ContentDocumentId=newFile.ContentDocumentId,
                                               LinkedEntityId=theAccount.Id,ShareType='I');
                ContentDocument doc = [Select SharingOption from ContentDocument where Id=:newFile.ContentDocumentId];
                doc.SharingOption='R';
                update doc;
            }
            PageReference thisPage=Page.FileRelatedListPage;
            thisPage.getParameters().put('Id',theAccount.Id);
            thisPage.setRedirect(true);
            return thisPage;
        }catch(Exception ex){
            return null;
        }
    }
    
    
    public void showFiles(){
        theAccount = [Select Id, (Select Id,Title,CreatedBy.Name,CreatedDate,ContentDocumentId from attachedcontentdocuments)
                                      from Account where Id=:theAccount.Id];
        Id[] latestVersionIds = new Id[]{};
		for(attachedcontentdocument ad:theAccount.attachedcontentdocuments){
			latestVersionIds.add(ad.ContentDocumentId);
		}
        theDocs=[Select Id,Title,CreatedDate,CreatedBy.Name,LatestPublishedVersion.CreatedDate,LatestPublishedVersion.CreatedBy.Name,
                 LatestPublishedVersionId,LatestPublishedVersion.VersionNumber,LatestPublishedVersion.ReasonforChange,(Select Id,Title,CreatedBy.Name,CreatedDate,VersionNumber, ReasonForChange,IsLatest 
				from ContentVersions where IsLatest=false order by CreatedDate desc) from ContentDocument where Id in :latestVersionIds Order by CreatedDate DESC];
    }
}
