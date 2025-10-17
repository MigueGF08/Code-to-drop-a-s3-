# Proyecto Terraform - S3 Photo Upload

Proyecto de infraestructura como código usando Terraform para crear una aplicación web que permite subir fotos a S3.

## Requisitos Previos

- Ubuntu/Linux (WSL en Windows)
- Credenciales de AWS configuradas
- Key pair de AWS creado

## Estructura del Proyecto

```
terraform-s3-upload/
├── main.tf              # Configuración principal (S3, IAM, EC2)
├── variables.tf         # Variables del proyecto
├── outputs.tf           # Outputs (URLs, IPs, nombres)
├── terraform.tfvars     # Valores de las variables (se crea automáticamente)
├── index.html           # Aplicación web
├── setup.sh             # Script de instalación automática
└── README.md            # Este archivo
```

## ¿Qué crea este proyecto?

1. **S3 Bucket**: Para almacenar las fotos subidas
2. **IAM Role**: Rol con permisos para que EC2 pueda escribir en S3
3. **Security Group**: Permite tráfico HTTP (80), SSH (22) y puerto 8000
4. **Instancia EC2**: Servidor Ubuntu con Terraform instalado
5. **Elastic IP**: IP pública fija para la instancia

## Instalación Rápida

### Opción 1: Script Automático (Recomendado)

```bash
# 1. Crear directorio del proyecto
mkdir terraform-s3-upload
cd terraform-s3-upload

# 2. Copiar todos los archivos (.tf, .sh, .html)

# 3. Dar permisos de ejecución al script
chmod +x setup.sh

# 4. Ejecutar el script
./setup.sh
```

El script te preguntará:
- Región de AWS (default: us-east-1)
- Nombre de tu key pair

### Opción 2: Manual

```bash
# 1. Crear terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region    = "us-east-1"
key_name      = "tu-key-pair"
instance_type = "t2.micro"
EOF

# 2. Inicializar Terraform
terraform init

# 3. Ver el plan
terraform plan

# 4. Aplicar la configuración
terraform apply

# 5. Obtener el nombre del bucket
BUCKET_NAME=$(terraform output -raw bucket_name)

# 6. Actualizar index.html
sed -i "s/YOUR_BUCKET_NAME/$BUCKET_NAME/g" index.html
```

## Conectarse a la Instancia EC2

```bash
# Obtener la IP pública
EC2_IP=$(terraform output -raw ec2_public_ip)

# Conectarse por SSH
ssh -i ~/.ssh/tu-key-pair.pem ubuntu@$EC2_IP
```

## Configurar la Aplicación Web en EC2

```bash
# 1. Una vez conectado a EC2, crear directorio
mkdir -p ~/app
cd ~/app

# 2. Desde tu máquina local, copiar el archivo HTML
scp -i ~/.ssh/tu-key-pair.pem index.html ubuntu@EC2_IP:~/app/

# 3. En la instancia EC2, iniciar el servidor
cd ~/app
python3 -m http.server 8000
```

## Acceder a la Aplicación

Abre tu navegador en: `http://TU_IP_PUBLICA:8000`

## Comandos Útiles de Terraform

```bash
# Ver outputs
terraform output

# Ver el estado actual
terraform show

# Destruir toda la infraestructura
terraform destroy

# Ver el plan sin aplicar
terraform plan

# Aplicar solo un recurso específico
terraform apply -target=aws_s3_bucket.photo_bucket
```

## ¿Qué es el State File?

El **State File** (`terraform.tfstate`) es un archivo JSON que Terraform usa para:

- Mantener un registro de los recursos creados
- Mapear la configuración del código con los recursos reales en AWS
- Calcular qué cambios aplicar cuando modificas el código
- Evitar duplicar recursos

**Importante:**
- NO lo borres manualmente
- NO lo edites a mano
- Guárdalo en un backend remoto (S3) para trabajo en equipo

## Solución de Problemas

### Error: key pair no existe
```bash
# Crear un nuevo key pair
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > ~/.ssh/my-key-pair.pem
chmod 400 ~/.ssh/my-key-pair.pem
```

### Error: bucket name already exists
El nombre del bucket debe ser único globalmente. Terraform genera uno aleatorio automáticamente.

### No puedo conectarme a EC2
Verifica que:
1. El Security Group permite tráfico en el puerto 22 (SSH)
2. Tu IP pública tiene acceso
3. El key pair es el correcto

### La aplicación no carga fotos
Verifica:
1. El nombre del bucket en `index.html` es correcto
2. El IAM Role está adjunto a la instancia EC2
3. El bucket tiene los permisos correctos

## Outputs del Proyecto

Después de ejecutar `terraform apply`, obtendrás:

- **bucket_name**: Nombre del bucket S3 creado
- **bucket_url**: URL del bucket
- **ec2_public_ip**: IP pública de la instancia EC2
- **web_app_url**: URL completa para acceder a la app
- **iam_role_name**: Nombre del rol IAM creado

## Limpieza

Para eliminar todos los recursos:

```bash
terraform destroy
```

**Nota**: Esto eliminará:
- La instancia EC2
- El bucket S3 (debe estar vacío)
- Los roles IAM
- El Security Group
- La Elastic IP

## Autor

Tu Nombre
Curso: [Nombre del curso]
Profesor: [Nombre del profesor]
Fecha: [Fecha]

## Licencia

Proyecto educativo - UAG