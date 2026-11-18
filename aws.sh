#!/usr/bin/env bash
# Ejecutar desde Git Bash. Cada operación usa solo los recursos registrados aquí.
set -euo pipefail
export MSYS_NO_PATHCONV=1 AWS_PAGER=''
ROOT="$(cd "$(dirname "$0")" && pwd)"
STATE="$ROOT/.streamlab-aws.env"
AWS_REGION="${AWS_REGION:-us-east-2}"
export AWS_REGION AWS_DEFAULT_REGION="$AWS_REGION"
awst() { aws "$@" --output text | tr -d '\r'; }
save_state() { printf 'AWS_REGION=%q\nKEY_NAME=%q\nKEY_FILE=%q\nSG_ID=%q\nINSTANCE_ID=%q\n' "$AWS_REGION" "$KEY_NAME" "$KEY_FILE" "${SG_ID:-}" "${INSTANCE_ID:-}" > "$STATE"; }
load_state() { [ -f "$STATE" ] || { echo 'No hay despliegue registrado en esta carpeta.'; exit 1; }; source "$STATE"; export AWS_REGION AWS_DEFAULT_REGION="$AWS_REGION"; }
get_ip() { awst ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress'; }
case "${1:-ayuda}" in
 crear)
  if [ -e "$STATE" ]; then echo 'Ya hay recursos registrados. Ejecuta bash aws.sh estado. No se crea otra instancia.'; exit 1; fi
  aws sts get-caller-identity
  VPC_ID=$(awst ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId')
  [[ "$VPC_ID" == vpc-* ]] || { echo 'No hay VPC predeterminada en esta región.'; exit 1; }
  SUBNET_ID=$(awst ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" Name=default-for-az,Values=true --query 'Subnets[0].SubnetId')
  [[ "$SUBNET_ID" == subnet-* ]] || { echo 'No hay subred predeterminada disponible.'; exit 1; }
  MY_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '\r\n')
  [[ "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'No se pudo obtener tu IPv4 pública.'; exit 1; }
  KEY_NAME="streamlab-irving-$(date +%Y%m%d%H%M%S)"
  mkdir -p "$HOME/.ssh"
  KEY_FILE="$HOME/.ssh/$KEY_NAME.pem"
  SG_ID=''; INSTANCE_ID=''
  save_state
  awst ec2 create-key-pair --key-name "$KEY_NAME" --key-type ed25519 --query KeyMaterial > "$KEY_FILE"
  chmod 400 "$KEY_FILE"
  SG_ID=$(awst ec2 create-security-group --group-name "$KEY_NAME-sg" --description 'StreamLab practica web RTMP SSH' --vpc-id "$VPC_ID" --query GroupId)
  save_state
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr "$MY_IP/32"
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 1935 --cidr 0.0.0.0/0
  INSTANCE_ID=$(awst ec2 run-instances --image-id resolve:ssm:/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id --instance-type t3.micro --count 1 --key-name "$KEY_NAME" --security-group-ids "$SG_ID" --subnet-id "$SUBNET_ID" --associate-public-ip-address --metadata-options HttpTokens=required --credit-specification CpuCredits=standard --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":10,"VolumeType":"gp3","DeleteOnTermination":true,"Encrypted":true}}]' --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=streamlab-irving}]' --query 'Instances[0].InstanceId')
  save_state
  echo "Instancia creada: $INSTANCE_ID en $AWS_REGION. Esperando comprobaciones de estado..."
  aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"
  echo "IP pública: $(get_ip)"
  echo 'Siguiente: bash aws.sh conectar'
 ;;
 estado)
  load_state
  if [ -n "$INSTANCE_ID" ]; then
   aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].{ID:InstanceId,Estado:State.Name,IP:PublicIpAddress,Tipo:InstanceType}' --output table
  else echo 'La creación no llegó a generar una instancia. Los recursos parciales se pueden revisar con el archivo de estado.'; fi
 ;;
 conectar)
  load_state
  ssh -i "$KEY_FILE" "ubuntu@$(get_ip)"
 ;;
 borrar)
  load_state
  echo "Se eliminará el despliegue StreamLab registrado: ${INSTANCE_ID:-sin instancia} en $AWS_REGION."
  read -r -p 'Escribe borrar-streamlab para confirmar: ' answer
  [ "$answer" = borrar-streamlab ] || exit 1
  if [ -n "$INSTANCE_ID" ]; then
   aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
   aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
   aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].{Instancia:InstanceId,Estado:State.Name}' --output table
   echo 'TOMA LA CAPTURA: el estado anterior debe decir terminated.'
  fi
  if [ -n "$SG_ID" ]; then
   deleted=false
   for attempt in {1..12}; do
    if aws ec2 delete-security-group --group-id "$SG_ID"; then deleted=true; break; fi
    sleep 5
   done
   [ "$deleted" = true ] || { echo 'No se pudo eliminar el grupo. Conserva el archivo de estado y revisa dependencias.'; exit 1; }
   SG_ID=''; save_state
  fi
  aws ec2 delete-key-pair --key-name "$KEY_NAME"
  rm -f "$KEY_FILE" "$STATE"
  echo 'Instancia terminada, disco raíz configurado para borrarse, grupo y par de llaves eliminados.'
 ;;
 *) echo 'Uso: bash aws.sh crear | estado | conectar | borrar';;
esac
