environment=${1}
tag=${2:="latest"}

if [ -z "$environment" ]; then
    echo "No environment specified. Using 'development'"
    environment='development'
fi

base_domain=$(aws route53 list-hosted-zones --query "HostedZones[0].Name" --output text | rev | cut -c2- | rev)
account_id=$(aws sts get-caller-identity --query "Account" --output text | xargs)
region=${AWS_REGION}

helm upgrade --install \
    --namespace ${environment} \
    --create-namespace \
    --set baseDomain=${base_domain} \
    --set aws.region=${region} \
    --set aws.accountId=${account_id} \
    --set image.tag=${tag} \
    inventory-api-${environment} .