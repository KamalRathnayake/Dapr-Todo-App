$grp = "DaprContainerAppDemo"
$loc = "eastus"
$environment = "cne-dpr"
$STORAGE_ACCOUNT = "stdpr2022514432"

# creating resource group
az group create --name $grp `
                --location $loc

# creating storage account
az storage account create --name $STORAGE_ACCOUNT `
                --resource-group $grp `
                --location $loc `
                --sku Standard_RAGRS `
                --kind StorageV2

$storageKey = (az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $grp --output json --query "[0].value")
(Get-Content "components\statestore.yml") -Replace '"STORAGE_ACCOUNT_KEY"', $storageKey | Set-Content "components\statestore.yml"
(Get-Content "components\statestore.yml") -Replace 'STORAGE_NAME', $STORAGE_ACCOUNT | Set-Content "components\statestore.yml"

# creating environment
az containerapp env create --name $environment `
                           --resource-group $grp `
                           --internal-only false `
                           --location $loc

# setting dapr state store
az containerapp env dapr-component set `
--name $environment --resource-group $grp `
--dapr-component-name statestore `
--yaml '.\components\statestore.yml'

az containerapp env dapr-component list --resource-group $grp --name $environment --output json

# rebuild images
docker build -t kamalrathnayake/todoappbackend -f 'TodoApp.Backend\Dockerfile' .
docker push kamalrathnayake/todoappbackend

docker build -t kamalrathnayake/todoappfrontend -f 'TodoApp.Frontend\Dockerfile' .
docker push kamalrathnayake/todoappfrontend

# creating the backend
az containerapp create `
  --name todo-back `
  --resource-group $grp `
  --environment $environment `
  --image kamalrathnayake/todoappbackend:latest `
  --target-port 80 `
  --ingress 'internal' `
  --min-replicas 1 `
  --max-replicas 5 `
  --enable-dapr `
  --env-vars ASPNETCORE_ENVIRONMENT="Development" `
  --dapr-app-port 80 `
  --dapr-app-id todo-back

# creating the frontend
az containerapp create `
  --name todo-front `
  --resource-group $grp `
  --environment $environment `
  --image kamalrathnayake/todoappfrontend:latest `
  --target-port 80 `
  --ingress 'external' `
  --min-replicas 0 `
  --max-replicas 5 `
  --enable-dapr `
  --env-vars ASPNETCORE_ENVIRONMENT="Development" `
  --dapr-app-port 80 `
  --dapr-app-id todo-front



