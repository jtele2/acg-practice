resource "aws_cloudwatch_log_group" "kinesisfirehose-PUT-S3-acgpractice733" {
  log_group_class = "STANDARD"
  name            = "/aws/kinesisfirehose/PUT-S3-acgpractice733"
  skip_destroy    = "false"
}
