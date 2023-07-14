./scripts-by-chapter/chapter-1.sh
./scripts-by-chapter/chapter-2.sh
./scripts-by-chapter/chapter-3.sh

echo "***************************************************"
echo "********* CHAPTER 4 - STARTED AT $(date) **********"
echo "***************************************************"
echo "--- This could take around 10 minutes"

    # Create Spot Instances
    ( cd Infrastructure/eksctl/02-spot-instances && eksctl create nodegroup -f cluster.yaml )
    eksctl get nodegroups --cluster eks-acg

    # Delete previous nodegroup
    eksctl delete nodegroup --cluster eks-acg eks-node-group

    # Termination Handler
    helm repo add eks https://aws.github.io/eks-charts
    helm install aws-node-termination-handler \
                --namespace kube-system \
                eks/aws-node-termination-handler

    # # Create Managed Node Groups
    # ( cd Infrastructure/eksctl/03-managed-nodes && eksctl create nodegroup -f cluster.yaml )
    # eksctl get nodegroups --cluster eks-acg

    # # Delete previous nodegroup
    # eksctl delete nodegroup --cluster eks-acg eks-node-group-spot-instances

    # # Create Fargate Profile
    # eksctl create fargateprofile -f cluster.yaml

echo "*************************************************************"
echo "********* READY FOR CHAPTER 5 - FINISHED AT $(date) *********"
echo "*************************************************************"