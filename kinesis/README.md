# Machine Learning Specialization
_The following should be run from your EC2 instance or multicloud instance, not your local computer (safety)_.

## Kinesis Lab

> 15Mar23 Update! I've put the Firehose creation into terraform, using terraformer. Now everything should spin up properly ✨  


~~Data source to fetch the Firehose stream details. This resource must be created in the console prior to applying. Create a Kinesis Firehose stream with:~~ 
  ~~- Direct PUT~~
  ~~- To s3~~
  ~~- Name: put-s3-j7irn (create an s3 bucket with the same name for target)~~
  ~~- Newline delimiting~~
  ~~- Buffer hints: 10s~~

Everything for this course should be named `acgpractice733`. 

- Run `tfi` then `tfp` to spin up all necessary resources. 
- Run the `1` bash script. This creates a temporary bucket to house the lambda artifacts.
- Run the `2` script - this will build the lamda artifact and publish it to the s3 bucket. 
- Go on to the AWS console and test the lambda function. 
- You can also run the `kinesis_producer.py` function directly, which will function as the kinesis producer instead of the lambda function. This method is probably closer to what the lab wanted. 
- Results are stored in the `acgpractice733` s3 bucket. 