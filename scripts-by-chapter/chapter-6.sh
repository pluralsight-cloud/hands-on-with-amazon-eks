echo "***************************************************"
echo "********* CHAPTER 6 - STARTED AT $(date) **********"
echo "***************************************************"

# Install the AppMesh Controller

    ( cd ./Infrastructure/service-mesh && ./configure-app-mesh.sh )

# Create the Development and Production App Meshes

    ( cd ./Infrastructure/service-mesh && kubectl apply -f development-mesh.yaml )
    ( cd ./Infrastructure/service-mesh && kubectl apply -f production-mesh.yaml )

# Enable Namespace
    kubectl label namespace development mesh=development-mesh
    kubectl label namespace development "appmesh.k8s.aws/sidecarInjectorWebhook"=enabled

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


echo "*************************************************************"
echo "********* READY FOR CHAPTER 7 - FINISHED AT $(date) *********"
echo "*************************************************************"