#Note : Prequisites : A sample application should be registered with Azure AD prior to running this script


REGION="REGION"

# Role or user that will have permission over new AWS KMS CMK
PRINCIPALARN="arn:aws:iam::<<ACCOUNT_ID>:user/<user>"
CLIENTID="CLIENTID_VALUE" #Fill the Client ID value from Azure AD
CLIENTSECRET="CLIENTSECRET_VALUE"
PYTHON_PATH="python/lib/python3.7/site-packages"



## Create Lambda Function Artefact
zip -r9 lambda_function.zip auditcheck.py


mkdir -p msal_lambda_layers/$PYTHON_PATH
pip install msal --target msal_lambda_layers/$PYTHON_PATH/.
cd msal_lambda_layers
zip -r9 ../msal_package.zip *
cd ..

aws lambda publish-layer-version \
    --layer-name Azure_msal \
    --description "Microsoft Azure MSAL package layer" \
    --zip-file fileb://../msal_package.zip \
    --compatible-runtimes python3.7



MSAL_VERSION_ARN=`aws lambda get-layer-version --layer-name Azure_msal --query LayerVersionArn`

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

aws lambda create-function --function-name azureidamfunction \
--role $ROLE --handler auditcheck.lambda_handler \
--runtime python3.7 --timeout 300 --zip-file fileb://lambda_function.zip --region $REGION \
--layers $MSAL_VERSION_ARN
