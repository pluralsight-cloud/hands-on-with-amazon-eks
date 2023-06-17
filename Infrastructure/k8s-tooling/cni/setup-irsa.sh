service_account_name="aws-node"
iam_role_name="vpc-cni-iam-role"
aws_account_id=$(aws sts get-caller-identity | jq .Account | tr -d '"')

eksctl create iamserviceaccount --name ${service_account_name} \
    --namespace kube-system \
    --cluster eks-acg \
    --role-name ${iam_role_name} \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
    --override-existing-serviceaccounts \
    --approve

kubectl delete pods -n kube-system -l k8s-app=aws-node
# kubectl get pods -n kube-system -l k8s-app=aws-node
