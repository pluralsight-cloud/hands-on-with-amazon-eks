./scripts-by-chapter/chapter-1.sh
./scripts-by-chapter/chapter-2.sh
./scripts-by-chapter/chapter-3.sh

echo "***************************************************"
echo "********* CHAPTER 4 - STARTED AT $(date) **********"
echo "***************************************************"

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

echo "*************************************************************"
echo "********* READY FOR CHAPTER 5 - FINISHED AT $(date) *********"
echo "*************************************************************"