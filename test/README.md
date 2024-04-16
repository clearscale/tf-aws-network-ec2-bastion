# Testing

This is the [terratest](https://terratest.gruntwork.io/docs/getting-started/quick-start/) directory which uses [Go](https://go.dev/doc/tutorial/getting-started) to write and perform tests.

```bash
go version go1.21.5 linux/amd64
```

## Prerequisites

1. A VPC.
2. A Private Subnet in the VPC.
3. A SSH Key Pair in AWS (the name of the key is needed).

## Setup

To initialize terratest, install Go and then run the following commands:

```bash
cd test
go mod tidy
go test -args -az="SUBNET_AZ" -vpc_id="VPC_ID" -subnet_ids="SUBNET_ID" -ec2_key_name="SSH_KEY_NAME"
```
### Using Environment Variables

To run terratest using environment variables:

```bash
cd test
go mod tidy
TF_VAR_az="SUBNET_AZ" TF_VAR_vpc_id="VPC_ID" TF_VAR_subnet_ids="SUBNET_ID" TF_VAR_ec2_key_name="SSH_KEY_NAME" go test
```

For verbose output and custom timeout values use the `-v` and `-timeout` flags:

```bash
cd test
go test -v -timeout 30m -args -az="SUBNET_AZ" -vpc_id="VPC_ID" -subnet_ids="SUBNET_ID" -ec2_key_name="SSH_KEY_NAME"
```

## Success Example

```bash
Destroy complete! Resources: 7 destroyed.
PASS
ok      github.com/clearscale/tf-aws-network-ec2-bastion        161.696s
```
