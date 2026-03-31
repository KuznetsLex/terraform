#!/bin/bash

set -e

echo "JWT авторизация в Yandex.Cloud"

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform не установлен. Установите с https://terraform.io/downloads"
    exit 1
fi

if ! command -v yc &> /dev/null; then
    echo "❌ Yandex CLI не установлен. Установите с https://cloud.yandex.ru/docs/cli/quickstart"
    exit 1
fi

echo "🔐 Проверяем авторизацию в Yandex Cloud..."
if ! yc config list &> /dev/null; then
    echo "❌ Не настроена авторизация в Yandex Cloud"
    echo "Выполните: yc init"
    exit 1
fi

CLOUD_ID=$(yc config get cloud-id 2>/dev/null)
FOLDER_ID=$(yc config get folder-id 2>/dev/null)

if [ -z "$CLOUD_ID" ] || [ -z "$FOLDER_ID" ]; then
    echo "❌ Не настроены cloud-id или folder-id"
    echo "Выполните: yc init"
    exit 1
fi

# Проверяем доступность API
echo "🔍 Проверяем доступ к Yandex Cloud API..."
if ! yc resource-manager folder get "$FOLDER_ID" &> /dev/null; then
    echo "🔄 Обновляем токен авторизации..."
    if ! yc iam create-token &> /dev/null; then
        echo "❌ Не удалось создать токен. Попробуйте:"
        echo "yc init --reinit-source-authentication"
        exit 1
    fi
fi

# Экспортируем переменные для Terraform
export YC_CLOUD_ID="$CLOUD_ID"
export YC_FOLDER_ID="$FOLDER_ID"
export YC_TOKEN=$(yc iam create-token)

echo "✅ Авторизация настроена"
echo "   Cloud ID: $CLOUD_ID"
echo "   Folder ID: $FOLDER_ID"

if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Файл terraform.tfvars не найден."
    echo "Скопируйте terraform.tfvars.example в terraform.tfvars и заполните переменные:"
    echo "cp terraform.tfvars.example terraform.tfvars"
    exit 1
fi

echo "📋 Проверяем конфигурацию Terraform..."
terraform init

echo "🔍 Планирование изменений..."
terraform plan

echo ""
read -p "❓ Продолжить развертывание? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⚡ Применяем изменения..."
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Развертывание завершено!"
    echo ""
    echo "📝 Результаты:"
    terraform output
    
else
    echo "❌ Развертывание отменено"
fi