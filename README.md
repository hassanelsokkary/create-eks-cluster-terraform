# create-eks-cluster-terraform
Terraform code to create an EKS cluster.

# Usage
1- Export your AWS access key id and secret key as this example: <br/>
>     $ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
>     $ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  or add them to providers.tf file. <br/>
<br/>

2- Set your region in providers.tf file.

3- Add AWS user's ARN in main.tf to authorize 'kubectl' command admin access: <br/>
>      principal_arn     = "###### USER ARN to authorize in Cluster#########" <br/>
      
3- Execute 'terraform init' to initialize directory.<br/>

4- Execute 'terraform plan' to check resources to be provisioned. <br/>

5- Execute 'terraform apply' to apply and create EKS cluster.
