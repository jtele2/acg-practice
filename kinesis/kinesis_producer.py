"""
TODO:
  - 23FEB: Fix the loop statement so it checks for coordinates and dob keys prior to trimming data
"""

import json
import requests
import logging
import boto3

logging.basicConfig(level=logging.DEBUG)

# Get data from randomuser.me
while True:
    random_user = requests.get("https://randomuser.me/api").json()["results"][0]

    if random_user["dob"]["age"] >= 21:
        random_user_trim = {
            "fname": random_user["name"]["first"],
            "lname": random_user["name"]["last"],
            "age": random_user["dob"]["age"],
            "gender": random_user["gender"],
            "latitude": random_user["coordinates"]["latitude"],
            "longitude": random_user["coordinates"]["longitude"],
        }
        break
    logging.info("user under 21")

# test_data = {"name": "foo", "last_name": "bar"}
test_data_enc = (json.dumps(random_user_trim) + "\n").encode()

client = boto3.client("firehose", region_name="us-east-1")
response = client.put_record(
    DeliveryStreamName="put-s3-j7irn-test", Record={"Data": test_data_enc}
)
print(json.dumps(response, indent=2))
