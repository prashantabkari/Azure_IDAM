
REGION="us-east-1"

# Role or user that will have permission over new AWS KMS CMK
PRINCIPALARN="arn:aws:iam::972585204640:user/cloud_user"
CLIENTID="871d759b-b74e-46b8-81c5-076d7ec70426"
CLIENTSECRET="rZU2:.3Zr=lKt/W7ORCG3=Og6UC8V1yN"
PYTHON_PATH="python/lib/python3.7/site-packages"



mkdir -p msal_lambda_layers/$PYTHON_PATH
pip install msal --target msal_lambda_layers/$PYTHON_PATH/.
cd msal_lambda_layers
zip -r9 ../msal_package.zip *

aws lambda publish-layer-version \
    --layer-name Azure_msal \
    --description "Microsoft Azure MSAL package layer" \
    --zip-file fileb://../msal_package.zip \
    --compatible-runtimes python3.7


## Execute CloudFormation
##
aws cloudformation create-stack --stack-name azureidamops  --template-body file://Azure_IDAMcftemplate.yaml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=KMSAdminArn,ParameterValue=$PRINCIPALARN 


echo "Waiting for stack to complete.."
aws cloudformation wait stack-create-complete --stack-name azureidamops --region $REGION


## Create secure parameters
##

aws ssm put-parameter --name AzureGraphAPIClientID \
--description "Azure AD Client ID " \
--type "SecureString" --value $CLIENTID \
--key-id "alias/azureopskey" --region $REGION

aws ssm put-parameter --name AzureGraphAPIClientSecret \
--description "Azure AD Client Secret " \
--type "SecureString" --value $CLIENTSECRET \
--key-id "alias/azureopskey" --region $REGION



RESULT=`aws iam get-role --role-name Custom-Lambda-AzureADLogs --query Role.Arn`
ROLE=`echo $RESULT | sed 's/"//g'`
REGION="us-east-1"

aws lambda create-function --function-name azureidamfunction \
--role $ROLE --handler auditcheck.lambda_handler \
--runtime python3.7 --timeout 300 --zip-file fileb://lambda_function.zip --region $REGION \
--layers "arn:aws:lambda:us-east-1:972585204640:layer:Azure_msal:2" "arn:aws:lambda:us-east-1:972585204640:layer:httprequests:2"
