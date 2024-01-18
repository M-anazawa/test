#!/bin/bash

# ログファイルのパスを設定
LOGFILE="tunnel_log.txt"

{
  # 現在の日時をログに記録
  echo "スクリプト実行開始: $(date)"

  # ECSクラスタのリストを取得し、画面に表示
  echo "クラスタのリスト:"
  aws ecs list-clusters --region ap-northeast-1 --query 'clusterArns[*]' --output text | tr ' ' '\n'

  # ユーザーからクラスタ名の入力を受け取る
  read -p "クラスタ名を入力してください: " CLUSTER

  # 選択したクラスタのタスクリストを取得
  TASK_ARN=$(aws ecs list-tasks --region ap-northeast-1 --cluster "$CLUSTER" --query 'taskArns[0]' --output text)

  # タスクの詳細を取得し、特定の名前パターンに一致するコンテナのランタイムIDを取得
  CONTAINER_NAME_PATTERN="Webapp"
  CONTAINER_ID=$(aws ecs describe-tasks --region ap-northeast-1 --cluster "$CLUSTER" --tasks "$TASK_ARN" --query "tasks[0].containers[?contains(name, '$CONTAINER_NAME_PATTERN')].runtimeId" --output text)

  # データベースホストとポートの設定
  DB_HOST="localhost"
  LOCAL_DB_PORT="13306"
  REMOTE_DB_PORT="3306"

  # ターゲットの設定
  TARGET="ecs:${CLUSTER}_${TASK_ARN}_${CONTAINER_ID}"

  # パラメータの設定
  PARAMETERS="{\"host\":[\"${DB_HOST}\"],\"portNumber\":[\"${REMOTE_DB_PORT}\"], \"localPortNumber\":[\"${LOCAL_DB_PORT}\"]}"

  # AWS Systems Manager Session Managerを使用してポートフォワーディングセッションを開始
  aws ssm start-session \
      --target "$TARGET" \
      --document-name "AWS-StartPortForwardingSessionToRemoteHost" \
      --parameters "$PARAMETERS"

  # スクリプト実行終了のログ
  echo "スクリプト実行終了: $(date)"
} | tee -a "$LOGFILE"
