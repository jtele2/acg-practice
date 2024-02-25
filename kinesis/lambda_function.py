import json
import requests
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)
client = boto3.client("firehose", region_name="us-east-1")

STREAM_NAME = "put-s3-j7irn"


def lambda_handler(event, context):
    logger.info(f"CloudWatch logs group: {context.log_group_name}")

    # Get i data records from randomuser.me
    i = 0
    while i < 5:
        while True:
            random_user = requests.get("https://randomuser.me/api").json()["results"][0]
            username = f"{random_user['name']['first']} {random_user['name']['last']}"
            if (random_user["dob"]["age"] >= 21) and (
                random_user["location"].get("coordinates") is not None
            ):
                i += 1
                break
            elif random_user["dob"]["age"] < 21:
                logging.info(f"User {username} has age <21")
            elif random_user["location"].get("coordinates") is None:
                logging.info(f"User {username} has no coordinates")
            else:
                raise ValueError

        random_user_trim = {
            "fname": random_user["name"]["first"],
            "lname": random_user["name"]["last"],
            "age": random_user["dob"]["age"],
            "gender": random_user["gender"],
            "latitude": random_user["location"]["coordinates"]["latitude"],
            "longitude": random_user["location"]["coordinates"]["longitude"],
        }

        # test_data = {"name": "foo", "last_name": "bar"}
        # Data Firehose requires binary
        test_data_enc = json.dumps(random_user_trim).encode()

        response = client.put_record(
            DeliveryStreamName=STREAM_NAME, Record={"Data": test_data_enc}
        )
        logging.info(json.dumps(response, indent=2))

    return {"statusCode": 200, "body": json.dumps("Hello from Lambda!")}
