package test

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

var (
	region     string
	az         string
	vpcID      string
	subnetIDs  string
	sshKeyName string
)

func TestMain(m *testing.M) {
	flag.StringVar(&region, "region", "us-west-1", "Region")
	flag.StringVar(&az, "az", "", "Availability Zone")
	flag.StringVar(&vpcID, "vpc_id", "", "VPC ID")
	flag.StringVar(&subnetIDs, "subnet_ids", "", "Subnet IDs (comma-separated)")
	flag.StringVar(&sshKeyName, "ec2_key_name", "", "SSH Key Name")
	flag.Parse()

	os.Exit(m.Run())
}

func TestEC2InstanceCreation(t *testing.T) {
	if region == "" {
		region = "us-west-1"
	}

	if az == "" {
		az = os.Getenv("TF_VAR_az")
	}

	if vpcID == "" {
		vpcID = os.Getenv("TF_VAR_vpc_id")
	}

	if subnetIDs == "" {
		subnetIDs = os.Getenv("TF_VAR_subnet_ids")
	}

	if sshKeyName == "" {
		sshKeyName = os.Getenv("TF_VAR_ec2_key_name")
	}

	if az == "" || vpcID == "" || subnetIDs == "" || sshKeyName == "" {
		t.Fatal("Environment variables TF_VAR_az, TF_VAR_vpc_id, TF_VAR_subnet_ids, and TF_VAR_ec2_key_name must be set if they're not specified as arguments.")
	}

	t.Log("Using Region:", region)
	t.Log("Using AZ:", az)
	t.Log("Using VPC ID:", vpcID)
	t.Log("Using Subnet IDs:", subnetIDs)
	t.Log("Using SSH Key:", sshKeyName)

	uniqueId := random.UniqueId()
	name := strings.ToLower(fmt.Sprintf("cs-pmod%s-testing", uniqueId))

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"region":       region,
			"name":         name,
			"az":           az,
			"vpc_id":       vpcID,
			"subnet_ids":   []string{subnetIDs},
			"ec2_key_name": sshKeyName,
		},
		// Variables to override from the environment
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Extract instance ID from Terraform output
	instanceID := terraform.Output(t, terraformOptions, "ec2_id")

	// Create a credentials chain
	creds := credentials.NewChainCredentials([]credentials.Provider{
		// First, try to get credentials from the shared config file (which includes both ~/.aws/credentials and ~/.aws/config)
		&credentials.SharedCredentialsProvider{
			Profile: "default",
		},
		// If that fails, fall back to environment variables
		&credentials.EnvProvider{},
	})

	// Create a new session with explicit credentials
	awsSession, err := session.NewSession(&aws.Config{
		Region:      aws.String(region),
		Credentials: creds,
	})
	if err != nil {
		log.Fatalf("Failed to create session: %s", err)
	}

	// Create new EC2 client
	ec2Svc := ec2.New(awsSession)

	// Describe EC2 instance
	descInput := &ec2.DescribeInstancesInput{
		InstanceIds: []*string{aws.String(instanceID)},
	}
	descOutput, err := ec2Svc.DescribeInstances(descInput)
	if err != nil {
		t.Fatalf("Failed to describe EC2 instance: %v", err)
	}

	// Check if the instance is running
	instance := descOutput.Reservations[0].Instances[0]
	assert.Equal(t, ec2.InstanceStateNameRunning, *instance.State.Name, "Instance is not in 'running' state")

	fmt.Printf("Successfully found EC2 Instance: %s\n", name)
}
