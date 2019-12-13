import logging
import requests
import json
import jsonify

from msal import ConfidentialClientApplication

app = ConfidentialClientApplication("871d759b-b74e-46b8-81c5-076d7ec70426",
                                    authority="https://login.microsoftonline.com/1d73b912-1284-48b2-be6c-c5121b868d2d",
                                    client_credential="rZU2:.3Zr=lKt/W7ORCG3=Og6UC8V1yN")

result = None
result = app.acquire_token_silent(["https://graph.microsoft.com/.default"], account=None)

if not result:
    logging.info("No suitable token exists in cache. Let's get a new one from AAD.")
    result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])

if "access_token" in result:
    print(result['access_token'])
    user_data = requests.get(  # Use token to call downstream service
        "https://graph.microsoft.com/v1.0//auditLogs/directoryaudits",
        headers={'Authorization': 'Bearer ' + result['access_token']}, ).json()

    print(user_data)