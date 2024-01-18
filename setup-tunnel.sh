#!/bin/bash
set -eu

# 'tunnel.sh' スクリプトの現在のディレクトリを取得
DIR=$(cd $(dirname $0); pwd)

# 'tunnel.sh' へのシンボリックリンクを /usr/local/bin に作成
ln -s ${DIR}/tunnel.sh /usr/local/bin/tunnel

# 'tunnel.sh' に実行権限を付与
chmod +x ${DIR}/tunnel.sh

# リンク先に実行権限を付与
chmod +x /usr/local/bin/tunnel

echo "tunnel.sh スクリプトへのパスが設定され、実行権限が付与されました。"