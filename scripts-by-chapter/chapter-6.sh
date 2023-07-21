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

echo "*************************************************************"
echo "********* READY FOR CHAPTER 7 - FINISHED AT $(date) *********"
echo "*************************************************************"