aws cloudformation deploy \
    --stack-name appmesh-controller-iam-policy \
    --template-file iam-policy.yaml \
    --capabilities CAPABILITY_NAMED_IAM

account_id=$(aws sts get-caller-identity --query "Account" --output text | xargs)    
appmesh_controller_policy_arn="arn:aws:iam::${account_id}:policy/AppMeshControllerPolicy"

export CLUSTER_NAME=eks-acg
export AWS_REGION=us-east-1

eksctl create iamserviceaccount \
    --cluster eks-acg \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn ${appmesh_controller_policy_arn} \
    --approve

helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"
# kubectl create ns appmesh-system


helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller \
    --set log.level=debug
    # --set tracing.enabled=true \
    # --set tracing.provider=x-ray
