export AWS_REGION=us-east-1

helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller \
    --set log.level=debug \
    --set tracing.enabled=true \
    --set tracing.provider=x-ray
