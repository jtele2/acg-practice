# Kinesis Lab
- Run the `1` bash script
  - This creates the bucket we upload our lambda artifacts to
- Read through the `2` script - make one update to the `lambda_role` line
- Run the `2` script - this will build the lamda artifact and publish it to the 
  s3 bucket. 
- Go on to the AWS console and test the lambda function. 
  - You should see the lambda function run successfully and if you look into the s3
    bucket, you'll see the results. 
- You can also run the kinesis_producer.py function directly, which will function as
  the kinesis producer instead of the lambda function. 