echo "***************************************************"
echo "********* CHAPTER 6 - STARTED AT $(date) **********"
echo "***************************************************"

# Install the AppMesh Controller

    ( cd ./Infrastructure/service-mesh && ./configure-app-mesh.sh )
    sleep 60

# Create the Development and Production App Meshes

    ( cd ./Infrastructure/service-mesh && kubectl apply -f development-mesh.yaml )

# Enable Namespace
    kubectl label namespace development mesh=development-mesh
    kubectl label namespace development "appmesh.k8s.aws/sidecarInjectorWebhook"=enabled

# Updating IAM resources - Specially for FrontEnd - Required to make the envoy container to work

    ( cd ./resource-api/infra/cloudformation && ./create-iam-policy-app-mesh.sh ) &\
    ( cd ./clients-api/infra/cloudformation && ./create-iam-policy-app-mesh.sh ) &\
    ( cd ./inventory-api/infra/cloudformation && ./create-iam-policy-app-mesh.sh ) &\
    ( cd ./renting-api/infra/cloudformation && ./create-iam-policy-app-mesh.sh ) &\
    ( cd ./front-end/infra/cloudformation && ./create-iam-policy-app-mesh.sh ) &

    wait

    front_end_iam_policy=$(aws cloudformation describe-stacks --stack development-iam-policy-front-end --query "Stacks[0].Outputs[0]" | jq .OutputValue | tr -d '"')

    eksctl create iamserviceaccount --name front-end-iam-service-account \
        --namespace development \
        --cluster eks-acg \
        --attach-policy-arn ${front_end_iam_policy} --approve

# Install Helm Charts with Mesh Components

    front_end_image_tag=$(aws ecr list-images --repository-name bookstore.front-end --query "imageIds[0].imageTag" --output text | xargs)
    clients_api_image_tag=$(aws ecr list-images --repository-name bookstore.clients-api --query "imageIds[0].imageTag" --output text | xargs)
    renting_api_image_tag=$(aws ecr list-images --repository-name bookstore.renting-api --query "imageIds[0].imageTag" --output text | xargs)
    resource_api_image_tag=$(aws ecr list-images --repository-name bookstore.resource-api --query "imageIds[0].imageTag" --output text | xargs)
    inventory_api_image_tag=$(aws ecr list-images --repository-name bookstore.inventory-api --query "imageIds[0].imageTag" --output text | xargs)

    ( cd ./resource-api/infra/helm-v6 && ./create.sh development ${resource_api_image_tag} ) & \
    ( cd ./clients-api/infra/helm-v6 && ./create.sh development ${clients_api_image_tag} ) & \
    ( cd ./inventory-api/infra/helm-v6 && ./create.sh development ${inventory_api_image_tag} ) & \
    ( cd ./renting-api/infra/helm-v6 && ./create.sh development ${renting_api_image_tag} ) & \
    ( cd ./front-end/infra/helm-v6 && ./create.sh development ${front_end_image_tag} ) &

    wait

    # kubectl delete pods -n development $(kubectl get pods -n development | grep Running | awk '{print $1}')

# Updating deployment script to use Helm V& charts
    ( cd ./inventory-api && \
        sed -i 's/helm-v5/helm-v6/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V5 to Helm V6" && \
        git push origin master
    ) & \
    ( cd ./resource-api && \
        sed -i 's/helm-v5/helm-v6/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V5 to Helm V6" && \
        git push origin master
    ) & \
    ( cd ./clients-api && \
        sed -i 's/helm-v5/helm-v6/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V5 to Helm V6" && \
        git push origin master
    ) & \
    ( cd ./renting-api && \
        sed -i 's/helm-v5/helm-v6/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V5 to Helm V6" && \
        git push origin master
    ) & \
    ( cd ./front-end && \
        sed -i 's/helm-v5/helm-v6/' infra/codebuild/deployment/buildspec.yml && \
        git add . && \
        git commit -m "From Helm V5 to Helm V6" && \
        git push origin master
    ) &

    wait


# Enable X-Ray

    # appmesh_controller_iam_role_name=$(eksctl get iamserviceaccount --cluster eks-acg | grep appmesh-controller | awk '{print $3}' | xargs | cut -d "/" -f 2)
    # aws iam attach-role-policy --role-name ${appmesh_controller_iam_role_name} --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess

    ( cd ./resource-api/infra/cloudformation && ./create-iam-policy-x-ray.sh ) &\
    ( cd ./clients-api/infra/cloudformation && ./create-iam-policy-x-ray.sh ) &\
    ( cd ./inventory-api/infra/cloudformation && ./create-iam-policy-x-ray.sh ) &\
    ( cd ./renting-api/infra/cloudformation && ./create-iam-policy-x-ray.sh ) &\
    ( cd ./front-end/infra/cloudformation && ./create-iam-policy-x-ray.sh ) &

    wait

    ( cd ./Infrastructure/service-mesh && ./x-ray-setup.sh )
    
    # kubectl delete pods -n development $(kubectl get pods -n development | grep Running | awk '{print $1}')


# Retry Policies

    # kubectl scale deploy -n development resource-api-development-acg-resource-api --replicas=0
    
    front_end_image_tag=$(aws ecr list-images --repository-name bookstore.front-end --query "imageIds[0].imageTag" --output text | xargs)
    clients_api_image_tag=$(aws ecr list-images --repository-name bookstore.clients-api --query "imageIds[0].imageTag" --output text | xargs)
    renting_api_image_tag=$(aws ecr list-images --repository-name bookstore.renting-api --query "imageIds[0].imageTag" --output text | xargs)
    resource_api_image_tag=$(aws ecr list-images --repository-name bookstore.resource-api --query "imageIds[0].imageTag" --output text | xargs)
    inventory_api_image_tag=$(aws ecr list-images --repository-name bookstore.inventory-api --query "imageIds[0].imageTag" --output text | xargs)

    ( cd ./resource-api/infra/helm-v7 && ./create.sh development ${resource_api_image_tag} ) & \
    ( cd ./clients-api/infra/helm-v7 && ./create.sh development ${clients_api_image_tag} ) & \
    ( cd ./inventory-api/infra/helm-v7 && ./create.sh development ${inventory_api_image_tag} ) & \
    ( cd ./renting-api/infra/helm-v7 && ./create.sh development ${renting_api_image_tag} ) & \
    ( cd ./front-end/infra/helm-v7 && ./create.sh development ${front_end_image_tag} ) &

    wait

    kubectl delete pods -n development $(kubectl get pods -n development | grep Running | awk '{print $1}')

echo "*************************************************************"
echo "********* READY FOR CHAPTER 7 - FINISHED AT $(date) *********"
echo "*************************************************************"