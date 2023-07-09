echo "***************************************************"
echo "********* CHAPTER 5 - STARTED AT $(date) **********"
echo "***************************************************"

# Updating Development
    # helm del -n development `helm ls -n development | grep 'development' | awk '{print $1}'` # Delete them first

    # sleep 20

    ( cd ./resource-api/infra/helm-v3 && ./create.sh )
    ( cd ./clients-api/infra/helm-v3 && ./create.sh )
    ( cd ./inventory-api/infra/helm-v3 && ./create.sh )
    ( cd ./renting-api/infra/helm-v3 && ./create.sh )
    ( cd ./front-end/infra/helm-v3 && ./create.sh )


#  Create the Production DynamoDB Tables
    ( cd ./clients-api/infra/cloudformation && ./create-dynamodb-table.sh production )
    ( cd ./inventory-api/infra/cloudformation && ./create-dynamodb-table.sh production )
    ( cd ./renting-api/infra/cloudformation && ./create-dynamodb-table.sh production )
    ( cd ./resource-api/infra/cloudformation && ./create-dynamodb-table.sh production )


# Create IAM Policies of Bookstore Microservices
    ( cd clients-api/infra/cloudformation && ./create-iam-policy.sh production )
    ( cd resource-api/infra/cloudformation && ./create-iam-policy.sh production )
    ( cd inventory-api/infra/cloudformation && ./create-iam-policy.sh production )
    ( cd renting-api/infra/cloudformation && ./create-iam-policy.sh production )

# Create IAM Service Accounts
    resource_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-resource-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
    renting_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-renting-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
    inventory_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-inventory-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
    clients_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-clients-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
    eksctl create iamserviceaccount --name resources-api-iam-service-account \
        --namespace production \
        --cluster eks-acg \
        --attach-policy-arn ${resource_iam_policy} --approve
    eksctl create iamserviceaccount --name renting-api-iam-service-account \
        --namespace production \
        --cluster eks-acg \
        --attach-policy-arn ${renting_iam_policy} --approve
    eksctl create iamserviceaccount --name inventory-api-iam-service-account \
        --namespace production \
        --cluster eks-acg \
        --attach-policy-arn ${inventory_iam_policy} --approve
    eksctl create iamserviceaccount --name clients-api-iam-service-account \
        --namespace production \
        --cluster eks-acg \
        --attach-policy-arn ${clients_iam_policy} --approve

# Installing the Production applications
    ( cd ./resource-api/infra/helm-v3 && ./create.sh )
    ( cd ./clients-api/infra/helm-v3 && ./create.sh )
    ( cd ./inventory-api/infra/helm-v3 && ./create.sh )
    ( cd ./renting-api/infra/helm-v3 && ./create.sh )
    ( cd ./front-end/infra/helm-v3 && ./create.sh )

echo "*************************************************************"
echo "********* READY FOR CHAPTER 6 - FINISHED AT $(date) *********"
echo "*************************************************************"