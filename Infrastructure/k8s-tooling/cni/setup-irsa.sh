service_account_name="vpc-cni-service-account"
iam_role_name="aws-node"
aws_account_id=$(aws sts get-caller-identity | jq .Account | tr -d '"')

eksctl create iamserviceaccount --name ${service_account_name} \
    --namespace kube-system \
    --cluster eks-acg \
    --role-name ${iam_role_name} \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
    --override-existing-serviceaccounts \
    --approve

# eksctl update addon \
#     --name vpc-cni \
#     --cluster eks-acg \
#     --service-account-role-arn arn:aws:iam::${aws_account_id}:role/${iam_role_name}
