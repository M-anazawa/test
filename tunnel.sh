#!/bin/bash

# 画面に環境リストを表示
echo "1 - AdhYdxDev"
echo "2 - AdhYdxStg"
echo "3 - AdhYdxPrd"
echo "4 - AdhLdcrDev"
echo "5 - AdhLdcrStg"
echo "6 - AdhLdcrPrd"
echo "7 - AdhDcDev"
echo "8 - AdhDcStg"
echo "9 - AdhDcPrd"

# ユーザーから環境番号の入力を受け取る
read -p "環境番号を入力してください: " ENVIRONMENT_NUMBER

# 環境名のリスト
environments=("AdhYdxDev" "AdhYdxStg" "AdhYdxPrd" "AdhLdcrDev" "AdhLdcrStg" "AdhLdcrPrd" "AdhDcDev" "AdhDcStg" "AdhDcPrd")

# 入力された番号に対応する環境名を取得
ENVIRONMENT_NAME="${environments[$((ENVIRONMENT_NUMBER - 1))]}"

# AWS ECSクラスタのARNを取得
CLUSTER_ARN=$(aws ecs list-clusters --region ap-northeast-1 --query "clusterArns[${ENVIRONMENT_NUMBER - 1}]" --output text)

# AWS ECSタスクのARNを取得
TASK_ARN=$(aws ecs list-tasks --region ap-northeast-1 --cluster "$CLUSTER_ARN" --query 'taskArns[0]' --output text)

# コンテナ名に含まれる文字列を指定
CONTAINER_NAME_PATTERN="Webapp"

# コンテナのランタイムIDを取得
CONTAINER_ID=$(aws ecs describe-tasks --region ap-northeast-1 --cluster "$CLUSTER_ARN" --tasks "$TASK_ARN" --query "tasks[0].containers[?contains(name, '$CONTAINER_NAME_PATTERN')].runtimeId" --output text)

# RDSエンドポイントの一覧を取得
RDS_ENDPOINTS=$(aws rds describe-db-instances --region ap-northeast-1 --query 'DBInstances[*].[Endpoint.Address]' --output text)

# 環境名に一致するRDSエンドポイントを抽出
DB_HOST=""
for endpoint in $RDS_ENDPOINTS
do
  if [[ "$endpoint" == *"$ENVIRONMENT_NAME"* ]]; then
    DB_HOST="$endpoint"
    break
  fi
done

# データベースポートの設定
LOCAL_DB_PORT="13306"
REMOTE_DB_PORT="3306"

# ターゲットの設定
TARGET="ecs:${CLUSTER_ARN}_${TASK_ARN}_${CONTAINER_ID}"

# パラメータの設定
PARAMETERS="{\"host\":[\"${DB_HOST}\"],\"portNumber\":[\"${REMOTE_DB_PORT}\"], \"localPortNumber\":[\"${LOCAL_DB_PORT}\"]}"

# AWS Systems Manager Session Managerを使用してポートフォワーディングセッションを開始
aws ssm start-session \
  --target "$TARGET" \
  --document-name "AWS-StartPortForwardingSessionToRemoteHost" \
  --parameters "$PARAMETERS"
