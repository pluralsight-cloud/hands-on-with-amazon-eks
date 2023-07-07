environment=${1}

if [ -z "$environment" ]; then
    echo "No environment specified. Using 'development'"
    environment='development'
fi

base_domain=$(aws route53 list-hosted-zones --query "HostedZones[0].Name" --output text | rev | cut -c2- | rev)

helm upgrade --install \
    --namespace ${environment} \
    --create-namespace \
    --set baseDomain=${base_domain} \
    clients-api-${environment} .