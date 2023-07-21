./scripts-by-chapter/chapter-1.sh
./scripts-by-chapter/chapter-2.sh
./scripts-by-chapter/chapter-3.sh
./scripts-by-chapter/chapter-4.sh

echo "***************************************************"
echo "********* CHAPTER 5 - STARTED AT $(date) **********"
echo "***************************************************"
echo "--- This could take around 20 minutes"

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text | xargs)

# Create the CodeCommit Repository for each app
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=inventory-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=resource-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=renting-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=clients-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-1-codecommit.yaml \
            --parameter-overrides \
                AppName=front-end ) &

    wait

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
    git config --global user.name "cloud_user"

    

    base_codecommit_url=$(echo $inventory_api_repo_url | grep -Eo '^https?://[^/]+' | xargs)
    codecommit_username_encoded=$(echo -n ${codecommit_username} | jq -sRr @uri)
    codecommit_password_encoded=$(echo -n ${codecommit_password} | jq -sRr @uri)

    echo ${base_codecommit_url/"https://"/"https://${codecommit_username_encoded}:${codecommit_password_encoded}@"} >> ~/.git-credentials
    

# Initial Push to the Git Repositories
    ( cd ./inventory-api && \
        git init && \
        git remote add origin ${inventory_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" && \
        git push origin master )
    ( cd ./renting-api && \
        git init && \
        git remote add origin ${renting_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" && \
        git push origin master )
    ( cd ./resource-api && \
        git init && \
        git remote add origin ${resource_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" && \
        git push origin master )
    ( cd ./clients-api && \
        git init && \
        git remote add origin ${clients_api_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" && \
        git push origin master )
    ( cd ./front-end && \
        git init && \
        git remote add origin ${front_end_repo_url} && \
        git add . && \
        git commit -m "Initial Commit" && \
        git push origin master )


# Install ECR and CodeBuild jobs

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=inventory-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=resource-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=clients-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-2-ecr-and-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=front-end ) &

    wait
        
# # Automatic Building

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-3-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=inventory-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-3-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=resource-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-3-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-3-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=clients-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-3-automatic-build.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=front-end ) &
    wait

# Add the IAM Role to the aws-auth Config Map
    inventory_api_codebuild_iam_role_name=$(aws cloudformation describe-stack-resources --stack inventory-api-codecommit-repo --query "StackResources[?LogicalResourceId=='IamServiceRole'].PhysicalResourceId" --output text | xargs)
    renting_api_codebuild_iam_role_name=$(aws cloudformation describe-stack-resources --stack renting-api-codecommit-repo --query "StackResources[?LogicalResourceId=='IamServiceRole'].PhysicalResourceId" --output text | xargs)
    resource_api_codebuild_iam_role_name=$(aws cloudformation describe-stack-resources --stack resource-api-codecommit-repo --query "StackResources[?LogicalResourceId=='IamServiceRole'].PhysicalResourceId" --output text | xargs)
    clients_api_codebuild_iam_role_name=$(aws cloudformation describe-stack-resources --stack clients-api-codecommit-repo --query "StackResources[?LogicalResourceId=='IamServiceRole'].PhysicalResourceId" --output text | xargs)
    front_end_codebuild_iam_role_name=$(aws cloudformation describe-stack-resources --stack front-end-codecommit-repo --query "StackResources[?LogicalResourceId=='IamServiceRole'].PhysicalResourceId" --output text | xargs)

    inventory_api_codebuild_iam_role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${inventory_api_codebuild_iam_role_name}"
    renting_api_codebuild_iam_role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${renting_api_codebuild_iam_role_name}"
    resource_api_codebuild_iam_role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${resource_api_codebuild_iam_role_name}"
    clients_api_codebuild_iam_role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${clients_api_codebuild_iam_role_name}"
    front_end_codebuild_iam_role_arn="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${front_end_codebuild_iam_role_name}"

    kubectl get cm -n kube-system aws-auth -o yaml

    eksctl create iamidentitymapping --cluster eks-acg --arn ${inventory_api_codebuild_iam_role_arn} --username inventory-api-deployment --group system:masters
    eksctl create iamidentitymapping --cluster eks-acg --arn ${renting_api_codebuild_iam_role_arn} --username renting-api-deployment --group system:masters
    eksctl create iamidentitymapping --cluster eks-acg --arn ${resource_api_codebuild_iam_role_arn} --username resource-api-deployment --group system:masters
    eksctl create iamidentitymapping --cluster eks-acg --arn ${clients_api_codebuild_iam_role_arn} --username clients-api-deployment --group system:masters
    eksctl create iamidentitymapping --cluster eks-acg --arn ${front_end_codebuild_iam_role_arn} --username front-end-deployment --group system:masters

    kubectl get cm -n kube-system aws-auth -o yaml

# Automatic Deployment to Development Environment

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-4-deploy-development.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=inventory-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-4-deploy-development.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=resource-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-4-deploy-development.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-4-deploy-development.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=clients-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-4-deploy-development.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=front-end ) &

    wait

# Updating Development
    ( cd ./inventory-api && \
        sed -i 's/helm-v4/helm-v5/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V4 to Helm V5" && \
        git push origin master
    ) & \
    ( cd ./resource-api && \
        sed -i 's/helm-v4/helm-v5/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V4 to Helm V5" && \
        git push origin master
    ) & \
    ( cd ./clients-api && \
        sed -i 's/helm-v4/helm-v5/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V4 to Helm V5" && \
        git push origin master
    ) & \
    ( cd ./renting-api && \
        sed -i 's/helm-v4/helm-v5/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V4 to Helm V5" && \
        git push origin master
    ) & \
    ( cd ./front-end && \
        sed -i 's/helm-v4/helm-v5/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V4 to Helm V5" && \
        git push origin master
    ) &

    wait


#  Create the Production DynamoDB Tables
    ( cd ./clients-api/infra/cloudformation && ./create-dynamodb-table.sh production ) & \
    ( cd ./inventory-api/infra/cloudformation && ./create-dynamodb-table.sh production ) & \
    ( cd ./renting-api/infra/cloudformation && ./create-dynamodb-table.sh production ) & \
    ( cd ./resource-api/infra/cloudformation && ./create-dynamodb-table.sh production ) &

    wait


# Create IAM Policies of Bookstore Microservices
    ( cd clients-api/infra/cloudformation && ./create-iam-policy.sh production ) & \
    ( cd resource-api/infra/cloudformation && ./create-iam-policy.sh production ) & \
    ( cd inventory-api/infra/cloudformation && ./create-iam-policy.sh production ) & \
    ( cd renting-api/infra/cloudformation && ./create-iam-policy.sh production ) &

    wait

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

    sleep 300 # wait until everything has images. More or less, 5 minutes

    front_end_image_tag=$(aws ecr list-images --repository-name bookstore.front-end --query "imageIds[0].imageTag" --output text | xargs)
    clients_api_image_tag=$(aws ecr list-images --repository-name bookstore.clients-api --query "imageIds[0].imageTag" --output text | xargs)
    renting_api_image_tag=$(aws ecr list-images --repository-name bookstore.renting-api --query "imageIds[0].imageTag" --output text | xargs)
    resource_api_image_tag=$(aws ecr list-images --repository-name bookstore.resource-api --query "imageIds[0].imageTag" --output text | xargs)
    inventory_api_image_tag=$(aws ecr list-images --repository-name bookstore.inventory-api --query "imageIds[0].imageTag" --output text | xargs)

    ( cd ./resource-api/infra/helm-v5 && ./create.sh production ${resource_api_image_tag} ) & \
    ( cd ./clients-api/infra/helm-v5 && ./create.sh production ${clients_api_image_tag} ) & \
    ( cd ./inventory-api/infra/helm-v5 && ./create.sh production ${inventory_api_image_tag} ) & \
    ( cd ./renting-api/infra/helm-v5 && ./create.sh production ${renting_api_image_tag} ) & \
    ( cd ./front-end/infra/helm-v5 && ./create.sh production ${front_end_image_tag} ) &

    wait

# Automatic Deployment to Production Environment

    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name inventory-api-codecommit-repo \
            --template-file cicd-5-deploy-prod.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=inventory-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name resource-api-codecommit-repo \
            --template-file cicd-5-deploy-prod.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=resource-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name renting-api-codecommit-repo \
            --template-file cicd-5-deploy-prod.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=renting-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name clients-api-codecommit-repo \
            --template-file cicd-5-deploy-prod.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=clients-api ) & \
    ( cd Infrastructure/cloudformation/cicd && \
        aws cloudformation deploy \
            --stack-name front-end-codecommit-repo \
            --template-file cicd-5-deploy-prod.yaml \
            --capabilities CAPABILITY_IAM \
            --parameter-overrides \
                AppName=front-end ) &

    wait


echo "*************************************************************"
echo "********* READY FOR CHAPTER 6 - FINISHED AT $(date) *********"
echo "*************************************************************"