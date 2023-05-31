echo "***************************************************"
echo "********* CHAPTER 3 - STARTED AT $(date) **********"
echo "***************************************************"

eksctl utils associate-iam-oidc-provider --cluster=eks-acg --approve

echo "*************************************************************"
echo "********* READY FOR CHAPTER 4 - FINISHED AT $(date) *********"
echo "*************************************************************"