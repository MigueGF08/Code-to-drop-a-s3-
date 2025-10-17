#!/bin/bash

# Script de configuración para el proyecto Terraform S3 Upload

echo "=========================================="
echo "   Setup Terraform S3 Photo Upload"
echo "=========================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${YELLOW}Terraform no está instalado. Instalando...${NC}"
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update && sudo apt-get install -y terraform
else
    echo -e "${GREEN}✓ Terraform ya está instalado${NC}"
fi

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}AWS CLI no está instalado. Instalando...${NC}"
    sudo apt-get install -y awscli
else
    echo -e "${GREEN}✓ AWS CLI ya está instalado${NC}"
fi

echo ""
echo "=========================================="
echo "   Configuración del proyecto"
echo "=========================================="
echo ""

# Pedir datos al usuario
read -p "Ingresa tu región de AWS (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Ingresa el nombre de tu key pair: " KEY_NAME

if [ -z "$KEY_NAME" ]; then
    echo -e "${RED}Error: Debes proporcionar el nombre de tu key pair${NC}"
    exit 1
fi

# Crear terraform.tfvars
echo "Creando terraform.tfvars..."
cat > terraform.tfvars <<EOF
aws_region    = "$AWS_REGION"
key_name      = "$KEY_NAME"
instance_type = "t2.micro"
EOF

echo -e "${GREEN}✓ Archivo terraform.tfvars creado${NC}"
echo ""

# Inicializar Terraform
echo "=========================================="
echo "   Inicializando Terraform"
echo "=========================================="
terraform init

if [ $? -ne 0 ]; then
    echo -e "${RED}Error al inicializar Terraform${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo "   Plan de Terraform"
echo "=========================================="
terraform plan

echo ""
read -p "¿Deseas aplicar esta configuración? (yes/no): " APPLY

if [ "$APPLY" == "yes" ]; then
    echo ""
    echo "=========================================="
    echo "   Aplicando configuración..."
    echo "=========================================="
    terraform apply -auto-approve
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=========================================="
        echo "   ✓ Configuración aplicada exitosamente"
        echo "==========================================${NC}"
        echo ""
        
        # Obtener outputs
        BUCKET_NAME=$(terraform output -raw bucket_name)
        EC2_IP=$(terraform output -raw ec2_public_ip)
        WEB_URL=$(terraform output -raw web_app_url)
        
        echo "INFORMACIÓN IMPORTANTE:"
        echo "----------------------"
        echo "Bucket S3: $BUCKET_NAME"
        echo "IP Pública EC2: $EC2_IP"
        echo "URL de la app: $WEB_URL"
        echo ""
        
        # Actualizar el HTML con el nombre del bucket
        echo "Actualizando index.html con el nombre del bucket..."
        sed -i "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" index.html
        sed -i "s/us-east-1/$AWS_REGION/g" index.html
        echo -e "${GREEN}✓ index.html actualizado${NC}"
        echo ""
        
        echo "=========================================="
        echo "   PRÓXIMOS PASOS:"
        echo "=========================================="
        echo "1. Espera 2-3 minutos a que la instancia termine de configurarse"
        echo "2. Conéctate a tu instancia EC2:"
        echo "   ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$EC2_IP"
        echo ""
        echo "3. En la instancia, ejecuta:"
        echo "   mkdir -p ~/app"
        echo "   cd ~/app"
        echo ""
        echo "4. Copia el archivo index.html a la instancia"
        echo ""
        echo "5. Inicia el servidor web:"
        echo "   python3 -m http.server 8000"
        echo ""
        echo "6. Abre en tu navegador: $WEB_URL"
        echo "=========================================="
        
    else
        echo -e "${RED}Error al aplicar la configuración${NC}"
        exit 1
    fi
else
    echo "Configuración cancelada"
fi