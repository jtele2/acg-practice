# Machine Learning Specialization
_The following should be run from your EC2 instance or multicloud instance, not your local computer (safety)_.

## Changelog

| Date    | Description                                                                                                |
| ------- | ---------------------------------------------------------------------------------------------------------- |
| 18Mar23 | Fixed an issue with IAM permission not letting Firehose communicate with s3                                |
|         | I've now moved all code from the `configs` repo into this repo - only 1 repo to manage! ✨                  |
| 15Mar23 | I've put the Firehose creation into terraform, using terraformer. Now everything should spin up properly ✨ |

## Kinesis Lab

~~Data source to fetch the Firehose stream details. This resource must be created in the console prior to applying. Create a Kinesis Firehose stream with:~~ 
  ~~- Direct PUT~~
  ~~- To s3~~
  ~~- Name: put-s3-j7irn (create an s3 bucket with the same name for target)~~
  ~~- Newline delimiting~~
  ~~- Buffer hints: 10s~~

Everything for this course should be named `acgpractice733`. 

- Run `tfi` then `tfa -auto-approve` to spin up all necessary resources. 
- Run the `1` bash script. This creates a temporary bucket to house the lambda artifacts.
- Run the `2` script - this will build the lamda artifact and publish it to the s3 bucket. 
- Go on to the AWS console and test the lambda function. 
- You can also run the `kinesis_producer.py` function directly, which will function as the kinesis producer instead of the lambda function. This method is probably closer to what the lab wanted. 
- Results are stored in the `acgpractice733` s3 bucket. 

## Data Preparation Lab
Note that the AWS Glue and AWS Athena portions of this lab are console-heavy and will not be included in the Terraform code. 

### Lab Answers
1. Q: What percentage of users are male vs female?  
   A: 49.14
  
2. Q: What are the ages of most of the users?  
   A: 
      | Bin | Age Range | Count |
      | --- | --------- | ----- |
      | 1   | 20-29     | 139   |
      | 2   | 30-39     | 180   |
      | 3   | 40-49     | 209   |
      | 4   | 50-59     | 205   |
      | 5   | 60-69     | 202   |
      | 6   | 70-79     | 212   |
      | 7   | Unknown   | 11    |

