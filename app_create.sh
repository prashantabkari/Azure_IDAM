
REGION="us-east-1"

# Role or user that will have permission over new AWS KMS CMK
PRINCIPALARN="arn:aws:iam::443372633997:user/cloud_user"
CLIENTID="871d759b-b74e-46b8-81c5-076d7ec70426"
CLIENTSECRET="rZU2:.3Zr=lKt/W7ORCG3=Og6UC8V1yN"


## Execute CloudFormation
##
aws cloudformation create-stack --stack-name azureidamops  --template-body file://Azure_IDAMcftemplate.yaml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=KMSAdminArn,ParameterValue=$PRINCIPALARN 


echo "Waiting for stack to complete.."
aws cloudformation wait stack-create-complete --stack-name azureidamops --region $REGION


## Create secure parameters
##

aws ssm put-parameter --name AzureGraphAPIClientID \
--description "Azure AD Client ID used for Azure AD Log Lambdas" \
--type "SecureString" --value $CLIENTID \
--key-id "alias/azureopskey" --region $REGION

aws ssm put-parameter --name AzureGraphAPIClientSecret \
--description "Azure AD Client Secret used for Azure AD Log Lambdas" \
--type "SecureString" --value $CLIENTSECRET \
--key-id "alias/azureopskey" --region $REGION



RESULT=`aws iam get-role --role-name Custom-Lambda-AzureADLogs --query Role.Arn`
ROLE=`echo $RESULT | sed 's/"//g'`
REGION="us-east-1"

aws lambda create-function --function-name azureidamfunction\
--role $ROLE --handler auditcheck.lambda_handler \
--runtime python3.7 --timeout 300 --zip-file fileb://lambda_function.zip --region $REGION
