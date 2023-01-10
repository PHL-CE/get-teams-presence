import os
import sys
import json
import requests
import msal
import atexit
import time
import logging
import socket
from azure.servicebus import ServiceBusClient, ServiceBusMessage
from sense_hat import SenseHat

logging.basicConfig(filename='logs/presence.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

### GLOBAL VARIABLES ###
authority = "https://login.microsoftonline.com/common"
endpoint = "https://graph.microsoft.com/beta/me/presence"
scope = ["Presence.Read"]
client_id = os.getenv('client_id')
email = os.getenv('email')
sb_conn_string = os.getenv('sb_conn_string')
queue_name = os.getenv('authqueue')

# Sense Hat stuff:
sense = SenseHat()
sense.low_light = True

# Establish or open token_cache.bin
cache = msal.SerializableTokenCache()
if os.path.exists('token_cache.bin'):
    cache.deserialize(open('token_cache.bin', 'r').read())
atexit.register(lambda:
    open('token_cache.bin', 'w').write(cache.serialize())
    if cache.has_state_changed else None    
    )

# Establish GRAPH connection via MSAL auth library
app = msal.PublicClientApplication(
    client_id, 
    authority=authority,
    token_cache=cache
    )

def checkAuth ():
    result = None

    # We now check the cache to see if we have some end users signed in before.
    accounts = app.get_accounts()
    if accounts:
        # Assume only one account and get first one
        account = accounts[0]
        # Now let's try to find a token in cache for this account
        result = app.acquire_token_silent(scope, account=account)

    # If no accounts with valid token found in cache, prompt user to log in again and get new
    if not result:
        logging.info("No suitable token exists in cache. Let's get a new one from AAD.")

        flow = app.initiate_device_flow(scopes=scope)
        if 'user_code' not in flow:
            e = f'Failed to create device flow. Err: {json.dumps(flow, indent=4)}'
            logging.error(e)
            raise ValueError(e)
        else:
            msg = {}
            msg['message'] = (
                f'Auth Token for {sys.argv[0]} on {socket.gethostname()} is not valid or unavailable. '
                'Please follow the link below and paste in the following code to generate a new token.'
            )
            msg['email'] = email
            msg['user_code'] = flow['user_code']
            msg['verification_uri'] = flow['verification_uri']
            msg_formatted = str(json.dumps(msg))
            message = ServiceBusMessage(msg_formatted)
            try:
                with ServiceBusClient.from_connection_string(sb_conn_string) as client:
                    with client.get_queue_sender(queue_name) as sender:
                        sender.send_messages(message)
                        logging.info('Message sent to SB Queue successfully - check email for auth code.')
            except Exception as e:
                logging.info(f'Error sending message to SB Queue : {e}')
        
        return app.acquire_token_by_device_flow(flow)

def showMessage (message):
    sense.show_message(
        message, 
        text_colour=(0,0,255), 
        scroll_speed=0.2
    )
    sense.clear()

def getPresence ():
    auth_result = checkAuth()
        
    if 'access_token' in auth_result:
        # Calling graph using the access token
        graph_data = requests.get(  # Use token to call downstream service
            endpoint,
            headers={'Authorization': 'Bearer ' + auth_result['access_token']},).json()
    else:
        logging.error(auth_result.get('error'))
        logging.error(auth_result.get('error_description'))
        logging.error(auth_result.get('correlation_id'))  # You may need this when reporting a bug

    # Parse Graph Response to get current User Activity
    return graph_data['activity']

while True:
    presence = getPresence()
    if presence in ['InACall', 'InAConferenceCall', 'Presenting']:
        showMessage("On Air")
    else:
        time.sleep(60)