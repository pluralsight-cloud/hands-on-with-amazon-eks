helm repo add eks https://aws.github.io/eks-charts

aws cloudformation deploy \
    --stack-name aws-load-balancer-iam-policy \
    --template-file iam-policy.yaml \
    --capabilities CAPABILITY_IAM

aws_load_balancer_iam_policy=$(aws cloudformation describe-stacks --stack aws-load-balancer-iam-policy --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
service_account_name="aws-load-balancer-controller-iam-service-account"

eksctl create iamserviceaccount --name ${service_account_name} \
    --namespace kube-system \
    --cluster eks-acg \
    --attach-policy-arn ${aws_load_balancer_iam_policy} --approve

helm upgrade --install \
  -n kube-system \
  --set clusterName=eks-acg \
  --set serviceAccount.create=false \
  --set serviceAccount.name=${service_account_name} \
  aws-load-balancer-controller eks/aws-load-balancer-controller

