echo "***************************************************"
echo "********* CHAPTER 5 - STARTED AT $(date) **********"
echo "***************************************************"

# Create the CodeCommit Repository for each app
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=inventory-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=resource-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=renting-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=clients-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=front-end )

# Get the CodeCommit credentials for the "cloud_user" IAM user
    codecommit_creds=$(aws iam create-service-specific-credential --user-name cloud_user --service-name codecommit.amazonaws.com)
    codecommit_username=`echo $codecommit_creds | jq -r ".ServiceSpecificCredential.ServiceUserName" | xargs`
    codecommit_password=`echo $codecommit_creds | jq -r ".ServiceSpecificCredential.ServicePassword" | xargs`




# Updating Development
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
    ( cd ./resource-api/infra/helm-v3 && ./create.sh production )
    ( cd ./clients-api/infra/helm-v3 && ./create.sh production )
    ( cd ./inventory-api/infra/helm-v3 && ./create.sh production )
    ( cd ./renting-api/infra/helm-v3 && ./create.sh production )
    ( cd ./front-end/infra/helm-v3 && ./create.sh production )

echo "*************************************************************"
echo "********* READY FOR CHAPTER 6 - FINISHED AT $(date) *********"
echo "*************************************************************"