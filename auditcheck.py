import logging
import requests
import json
import boto3



from msal import ConfidentialClientApplication


def lambda_handler(event, context):
    
    #Get Client ID and Secret
    client = boto3.client('ssm')
    response = client.get_parameters(
            Names=[
                "AzureGraphAPIClientSecret",
                "AzureGraphAPIClientID"
            ],
            WithDecryption=False
        )
    
    for parameter in response['Parameters']:
        if parameter['Name'] == "AzureGraphAPIClientSecret":
            clientsecret = parameter['Value']
        elif parameter['Name'] == "AzureGraphAPIClientID":
            clientid = parameter['Value']
            
    app = ConfidentialClientApplication(clientid,
                                    authority="https://login.microsoftonline.com/1d73b912-1284-48b2-be6c-c5121b868d2d",
                                    client_credential=clientsecret)
                                    
    result = None
    result = app.acquire_token_silent(["https://graph.microsoft.com/.default"], account=None)
    
    if not result:
        logging.info("No suitable token exists in cache. Let's get a new one from AAD.")
        result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])
    if "access_token" in result:
        print(result['access_token'])
        user_data = requests.get("https://graph.microsoft.com/v1.0/users",
                                headers={'Authorization': 'Bearer ' + result['access_token']}, ).json()

    	print(user_data)
                                    
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }

