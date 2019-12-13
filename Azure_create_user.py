import logging
import requests
import json
import jsonify

from msal import ConfidentialClientApplication

user_data = {'user': 'jyoti.3331@gmail.com',
             'group': 'f434eb09-cccf-431d-94d1-e5433a83952c',
             'status': 'Active'}

invitation_data = {'inviteRedirectUrl': 'https://myapps.microsoft.com'}
invitation_data['invitedUserEmailAddress'] = user_data['user']
invitation_data['sendInvitationMessage'] = True
json_data = json.loads(json.dumps(invitation_data))
print("JSON dump is ",  json_data)

directory_data = {}
directory_url = "https://graph.microsoft.com/v1.0/directoryObjects/"

test_user_id = "c6fd86cf-7d0d-4d18-b956-45345688f37a"

app = ConfidentialClientApplication("871d759b-b74e-46b8-81c5-076d7ec70426",
                                    authority="https://login.microsoftonline.com/1d73b912-1284-48b2-be6c-c5121b868d2d",
                                    client_credential="rZU2:.3Zr=lKt/W7ORCG3=Og6UC8V1yN")






result = None
result = app.acquire_token_silent(["https://graph.microsoft.com/.default"], account=None)

if not result:
    logging.info("No suitable token exists in cache. Let's get a new one from AAD.")
    result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])

if "access_token" in result:
    # Calling graph using the access token
    user_data = requests.get(  # Use token to call downstream service
        "https://graph.microsoft.com/v1.0/users/jyoti.3331_gmail.com%23EXT%23@prashantabkarigmailcom.onmicrosoft.com",
        headers={'Authorization': 'Bearer ' + result['access_token']},).json()

    if(not user_data["error"]): # User exists in Azure AD
        #Fetch the user id
        print("User data", user_data)
        user_id = user_data["id"]
        print("User Id is ", user_id)

        directory_url += user_id
        directory_data["@odata.id"] = directory_url
        directory_json = json.loads(json.dumps(directory_data))
        print("directory_json", directory_json)

        #Add the user in the group
        group_data = requests.post(
            headers={'Authorization': 'Bearer ' + result['access_token']},
            url="https://graph.microsoft.com/v1.0/groups/f434eb09-cccf-431d-94d1-e5433a83952c/members/$ref",
            json=directory_json,
        )

        if(not group_data):
            print("Failure to add User to group",group_data.reason)
    else:
        print("User does not exist")
        invite_result = requests.post(url="https://graph.microsoft.com/v1.0/invitations",
                             json=json_data,
                             headers={'Authorization': 'Bearer ' + result['access_token']},
                             )
        print("Invite Result is", invite_result.json())

    #print("Graph API call result: %s" % json.dumps(graph_data, indent=2))
    #print("Graph API call result: %s" % json.dumps(graph_result.json(), indent=2))

else:
    print(result.get("error"))
    print(result.get("error_description"))
    print(result.get("correlation_id"))  # You may need this when reporting a bug
