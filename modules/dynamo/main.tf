resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "state_lock"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Eagle-state"
    Environment = "ssh"
  }
}
