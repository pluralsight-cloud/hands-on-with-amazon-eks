./scripts-by-chapter/chapter-1.sh
./scripts-by-chapter/chapter-2.sh
./scripts-by-chapter/chapter-3.sh
./scripts-by-chapter/chapter-4.sh

echo "***************************************************"
echo "********* CHAPTER 5 - STARTED AT $(date) **********"
echo "***************************************************"
echo "--- This could take around 20 minutes"

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

# Get the Repositories' URLs
    inventory_api_repo_url=$(aws cloudformation describe-stacks --stack inventory-api-codecommit-repo --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text | xargs)
    resource_api_repo_url=$(aws cloudformation describe-stacks --stack resource-api-codecommit-repo --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text | xargs)
    renting_api_repo_url=$(aws cloudformation describe-stacks --stack renting-api-codecommit-repo --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text | xargs)
    clients_api_repo_url=$(aws cloudformation describe-stacks --stack clients-api-codecommit-repo --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text | xargs)
    front_end_repo_url=$(aws cloudformation describe-stacks --stack front-end-codecommit-repo --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text | xargs)

# Init Git config
    git config --global credential.helper store
    git config --global init.defaultBranch master
    git config --global user.email "cloud-user@eks-acg.com"
    git config --global user.name "$codecommit_username"
    git config --global user.password "$codecommit_password"

    

    base_codecommit_url=$(echo $inventory_api_repo_url | grep -Eo '^https?://[^/]+' | xargs)
    codecommit_username_encoded=$(echo -n ${codecommit_username} | jq -sRr @uri)
    codecommit_password_encoded=$(echo -n ${codecommit_password} | jq -sRr @uri)

    echo ${base_codecommit_url/"https://"/"https://${codecommit_username_encoded}:${codecommit_password_encoded}@"} >> ~/.git-credentials
    

# Initial Push to the Git Repositories
    ( cd ./inventory-api && \
        git init && \
        git remote add origin ${inventory_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" &&
        git push origin master )
    
    ( cd ./renting-api && \
        git init && \
        git remote add origin ${renting_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" &&
        git push origin master )
    
    ( cd ./resource-api && \
        git init && \
        git remote add origin ${resource_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" &&
        git push origin master )
    
    ( cd ./clients-api && \
        git init && \
        git remote add origin ${clients_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" &&
        git push origin master )
    
    ( cd ./front-end && \
        git init && \
        git remote add origin ${front_end_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" &&
        git push origin master )

# Install ECR and CodeBuild jobs

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=inventory-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=resource-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=clients-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=front-end )
        
# Automatic Building

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=inventory-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=resource-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=clients-api )
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=front-end )

# Updating Development
#     ( cd ./resource-api/infra/helm-v3 && ./create.sh )
#     ( cd ./clients-api/infra/helm-v3 && ./create.sh )
#     ( cd ./inventory-api/infra/helm-v3 && ./create.sh )
#     ( cd ./renting-api/infra/helm-v3 && ./create.sh )
#     ( cd ./front-end/infra/helm-v3 && ./create.sh )


# #  Create the Production DynamoDB Tables
#     ( cd ./clients-api/infra/cloudformation && ./create-dynamodb-table.sh production )
#     ( cd ./inventory-api/infra/cloudformation && ./create-dynamodb-table.sh production )
#     ( cd ./renting-api/infra/cloudformation && ./create-dynamodb-table.sh production )
#     ( cd ./resource-api/infra/cloudformation && ./create-dynamodb-table.sh production )


# # Create IAM Policies of Bookstore Microservices
#     ( cd clients-api/infra/cloudformation && ./create-iam-policy.sh production )
#     ( cd resource-api/infra/cloudformation && ./create-iam-policy.sh production )
#     ( cd inventory-api/infra/cloudformation && ./create-iam-policy.sh production )
#     ( cd renting-api/infra/cloudformation && ./create-iam-policy.sh production )

# # Create IAM Service Accounts
#     resource_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-resource-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
#     renting_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-renting-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
#     inventory_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-inventory-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
#     clients_iam_policy=$(aws cloudformation describe-stacks --stack production-iam-policy-clients-api --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')
#     eksctl create iamserviceaccount --name resources-api-iam-service-account \
#         --namespace production \
#         --cluster eks-acg \
#         --attach-policy-arn ${resource_iam_policy} --approve
#     eksctl create iamserviceaccount --name renting-api-iam-service-account \
#         --namespace production \
#         --cluster eks-acg \
#         --attach-policy-arn ${renting_iam_policy} --approve
#     eksctl create iamserviceaccount --name inventory-api-iam-service-account \
#         --namespace production \
#         --cluster eks-acg \
#         --attach-policy-arn ${inventory_iam_policy} --approve
#     eksctl create iamserviceaccount --name clients-api-iam-service-account \
#         --namespace production \
#         --cluster eks-acg \
#         --attach-policy-arn ${clients_iam_policy} --approve

# # Installing the Production applications
#     ( cd ./resource-api/infra/helm-v3 && ./create.sh production )
#     ( cd ./clients-api/infra/helm-v3 && ./create.sh production )
#     ( cd ./inventory-api/infra/helm-v3 && ./create.sh production )
#     ( cd ./renting-api/infra/helm-v3 && ./create.sh production )
#     ( cd ./front-end/infra/helm-v3 && ./create.sh production )

echo "*************************************************************"
echo "********* READY FOR CHAPTER 6 - FINISHED AT $(date) *********"
echo "*************************************************************"