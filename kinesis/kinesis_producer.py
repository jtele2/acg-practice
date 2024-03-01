#!/usr/bin/env python3
"""
TODO:
  - 23FEB: ✅Fix the loop statement so it checks for coordinates and dob keys prior to trimming data
"""

import argparse
import json
import logging

import boto3
import requests
from colored_loggers import PersistentDynamicColorFormatter
from tqdm.auto import tqdm

# Configure logging to use the enhanced persistent dynamic color formatter
handler = logging.StreamHandler()
formatter = PersistentDynamicColorFormatter("%(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)
logging.basicConfig(level=logging.WARNING, handlers=[handler])

# Initialize the argument parser
parser = argparse.ArgumentParser(description="Test script for logging levels.")
parser.add_argument(
    "-v",
    "--verbose",
    action="count",
    default=0,
    help="Increase verbosity level (use -v for INFO level and -vv for DEBUG level).",
)

# Create a mutually exclusive group
group = parser.add_mutually_exclusive_group(required=True)

# Add arguments to the group
group.add_argument(
    "-k",
    "--kinesis",
    action="store_true",
    help="Upload to kinesis",
)
group.add_argument(
    "-d",
    "--data-firehose",
    action="store_true",
    help="Upload to data firehose",
)

# Parse the arguments
args = parser.parse_args()

# Adjust logging level based on verbosity argument
if args.verbose == 1:
    logging.getLogger().setLevel(logging.INFO)
elif args.verbose >= 2:
    logging.getLogger().setLevel(logging.DEBUG)

# Where to PUT to
if args.kinesis:
    client = boto3.client("kinesis", region_name="us-east-1")
elif args.data_firehose:
    client = boto3.client("firehose", region_name="us-east-1")

STREAM_NAME = "put-s3-j7irn"

# Get data records from randomuser.me
i = 0
tot = 1000
if not args.verbose:
    progress = tqdm(colour="GREEN", total=tot)
while i < tot:
    while True:
        random_user = requests.get("https://randomuser.me/api").json()["results"][0]
        username = f"{random_user['name']['first']} {random_user['name']['last']}"
        if (random_user["dob"]["age"] >= 21) and (
            random_user["location"].get("coordinates") is not None
        ):
            i += 1
            if not args.verbose:
                progress.update(1)
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
    # Data Firehose and Kinesis require binary
    test_data_enc = json.dumps(random_user_trim).encode()

    response = client.put_record(
        DeliveryStreamName=STREAM_NAME, Record={"Data": test_data_enc}
    )
    logging.info(json.dumps(response, indent=2))
