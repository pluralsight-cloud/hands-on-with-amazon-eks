cluster_stack_name="eksctl-eks-acg-cluster"
cluster_name="eks-acg"
secondary_cidr="100.64.0.0/16"
subnet_a_cidr="100.64.0.0/19"
subnet_b_cidr="100.64.32.0/19"
subnet_c_cidr="100.64.64.0/19"

vpc_id=`aws cloudformation describe-stack-resources --stack-name ${cluster_stack_name} --query "StackResources[?LogicalResourceId=='VPC'].PhysicalResourceId" --output text`
aws ec2 associate-vpc-cidr-block --vpc-id ${vpc_id} --cidr-block ${secondary_cidr}
sleep 5

nat_gateway_id=`aws ec2 describe-nat-gateways --query "NatGateways[?VpcId=='${vpc_id}'].NatGatewayId" | jq .[0] | tr -d '"'`

aws cloudformation deploy \
    --stack-name secondary-subnets \
    --template-file subnets.json \
    --parameter-overrides \
        VPCID=${vpc_id} \
        EKSClusterName=${cluster_name} \
        SubnetACidr=${subnet_a_cidr} \
        SubnetBCidr=${subnet_b_cidr} \
        SubnetCCidr=${subnet_c_cidr} \
        NATGatewayId=${nat_gateway_id}



kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl set env ds aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone

subnet_a=`aws cloudformation describe-stack-resources --stack-name secondary-subnets --query "StackResources[?LogicalResourceId=='SubnetA'].PhysicalResourceId" --output text`
subnet_b=`aws cloudformation describe-stack-resources --stack-name secondary-subnets --query "StackResources[?LogicalResourceId=='SubnetB'].PhysicalResourceId" --output text`
subnet_c=`aws cloudformation describe-stack-resources --stack-name secondary-subnets --query "StackResources[?LogicalResourceId=='SubnetC'].PhysicalResourceId" --output text`

sg1=`aws eks describe-cluster --name eks-acg --query "cluster.resourcesVpcConfig.securityGroupIds[0]" --output text`
sg2=`aws eks describe-cluster --name eks-acg --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text`

region='us-east-1'

helm upgrade --install \
    --namespace kube-system \
    --set az1.name=${region}a \
    --set az1.sg1=${sg1} \
    --set az1.sg2=${sg2} \
    --set az1.subnetId=${subnet_a} \
    --set az2.name=${region}b \
    --set az2.sg1=${sg1} \
    --set az2.sg2=${sg2} \
    --set az2.subnetId=${subnet_b} \
    --set az3.name=${region}c \
    --set az3.sg1=${sg1} \
    --set az3.sg2=${sg2} \
    --set az3.subnetId=${subnet_c} \
    vpc-cni-subnet-crds .