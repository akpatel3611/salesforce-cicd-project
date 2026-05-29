public with sharing class DeploymentValidationService {

    @AuraEnabled
    public static String getMessage() {
        return 'Deployment Success';
    }
}