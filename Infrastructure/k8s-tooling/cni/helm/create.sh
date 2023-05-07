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