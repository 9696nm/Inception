# 🔧 トラブルシューティングガイド

## よくある問題と解決策

### 1️⃣ WordPress がデータベースに接続できない

#### 症状
```
[WARN] データベース接続待機中... (1/60)
[WARN] データベース接続待機中... (2/60)
...
```

#### 原因
- MariaDB が初期化されていない
- データベースまたはユーザーが作成されていない
- 古いデータが残っている

#### 解決策

```bash
# 1. コンテナを停止
make down

# 2. データをクリア
sudo rm -rf /home/hmori/data/mariadb/*
sudo rm -rf /home/hmori/data/wordpress/*

# 3. 再起動
make up

# 4. ログを確認
make logs
```

#### 確認方法

```bash
# MariaDB のログを確認
docker logs mariadb

# 以下のメッセージが表示されるはず：
# [INFO] データベースとユーザーを作成中...
# [INFO] データベースとユーザーの作成が完了しました

# データベースが作成されているか確認
docker exec mariadb mysql -uroot -p[PASSWORD] -e "SHOW DATABASES;"

# WordPress ユーザーが作成されているか確認
docker exec mariadb mysql -uroot -p[PASSWORD] -e "SELECT User, Host FROM mysql.user;"
```

---

### 2️⃣ PHP-FPM が起動しない

#### 症状
```
ERROR: [/etc/php/8.2/fpm/pool.d/www.conf:1] unknown entry '#'
ERROR: FPM initialization failed
```

#### 原因
- PHP-FPM の設定ファイルで `#` コメントを使用している
- PHP-FPM は `;` でコメントする必要がある

#### 解決策

`www.conf` ファイルのコメントを確認：

```ini
; 正しい: セミコロンを使用
; これはコメントです

# 間違い: ハッシュは使えない
# これはエラーになります
```

すべてのコメントを `;` に変更して再ビルド：

```bash
# WordPress を再ビルド
docker-compose -f srcs/docker-compose.yml build wordpress

# 再起動
make restart
```

---

### 3️⃣ ポート 443 が既に使用されている

#### 症状
```
Error starting userland proxy: listen tcp4 0.0.0.0:443: bind: address already in use
```

#### 原因
- 別のプロセスがポート 443 を使用している

#### 解決策

```bash
# ポートを使用しているプロセスを確認
sudo lsof -i :443

# Apache や別の NGINX が動作している場合は停止
sudo systemctl stop apache2
sudo systemctl stop nginx

# 再度起動
make up
```

---

### 4️⃣ NGINX が WordPress に接続できない

#### 症状
```
502 Bad Gateway
```

#### 原因
- WordPress (PHP-FPM) が起動していない
- ネットワーク設定が間違っている

#### 解決策

```bash
# WordPress のログを確認
docker logs wordpress

# PHP-FPM が起動しているか確認
docker exec wordpress ps aux | grep php-fpm

# WordPress コンテナから MariaDB に接続できるか確認
docker exec wordpress mysql -hmariadb -uwp_user -p[PASSWORD] -e "SELECT 1"

# ネットワークを確認
docker network ls
docker network inspect srcs_inception-network
```

---

### 5️⃣ データベースの初期化が毎回実行される

#### 症状
- コンテナを再起動するたびにデータが消える
- 毎回初期化される

#### 原因
- ボリュームマウントが正しく設定されていない
- データディレクトリの権限が間違っている

#### 解決策

```bash
# ボリュームマウントを確認
docker inspect mariadb | grep -A 20 "Mounts"

# データディレクトリの権限を確認
ls -la /home/hmori/data/mariadb/

# 権限を修正（必要に応じて）
sudo chown -R 999:999 /home/hmori/data/mariadb/
```

---

### 6️⃣ WordPress のインストールが完了しない

#### 症状
- WordPress のダウンロードが永遠に続く
- "WordPress をダウンロード中..." で止まる

#### 原因
- インターネット接続の問題
- WP-CLI のダウンロードに失敗

#### 解決策

```bash
# WordPress コンテナに入る
docker exec -it wordpress bash

# 手動で WordPress をダウンロード
wp core download --allow-root --path=/var/www/html --locale=ja

# ダウンロードが完了したら exit して再起動
exit
docker restart wordpress
```

---

### 7️⃣ /etc/hosts が設定されていない

#### 症状
- ブラウザで `hmori.42.fr` にアクセスできない
- "このサイトにアクセスできません" エラー

#### 解決策

```bash
# /etc/hosts を確認
cat /etc/hosts | grep hmori.42.fr

# 存在しない場合は追加
echo "127.0.0.1    hmori.42.fr" | sudo tee -a /etc/hosts

# 確認
ping -c 2 hmori.42.fr
```

---

### 8️⃣ SSL 証明書の警告が表示される

#### 症状
- ブラウザで "接続がプライベートではありません" 警告

#### 原因
- 自己署名証明書を使用しているため（正常な動作）

#### 解決策

1. ブラウザで「詳細」をクリック
2. 「hmori.42.fr にアクセスする（安全ではありません）」をクリック

**本番環境では Let's Encrypt を使用してください**

---

## 🔍 デバッグコマンド集

### コンテナの状態を確認
```bash
docker ps -a
```

### すべてのログを表示
```bash
make logs

# または個別に
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### コンテナ内に入る
```bash
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```

### データベースを確認
```bash
# MariaDB コンテナ内で
docker exec -it mariadb mysql -uroot -p

# データベース一覧
SHOW DATABASES;

# ユーザー一覧
SELECT User, Host FROM mysql.user;

# WordPress データベースを確認
USE wordpress_db;
SHOW TABLES;
SELECT * FROM wp_users;
```

### ネットワークを確認
```bash
# ネットワーク一覧
docker network ls

# 詳細
docker network inspect srcs_inception-network
```

### ボリュームを確認
```bash
# ボリューム一覧
docker volume ls

# データディレクトリの内容
ls -la /home/hmori/data/mariadb/
ls -la /home/hmori/data/wordpress/
```

---

## 🆘 完全リセット

すべてがうまくいかない場合：

```bash
# 1. すべてを停止して削除
make fclean

# 2. Docker のキャッシュをクリア
docker system prune -af

# 3. データディレクトリを削除
sudo rm -rf /home/hmori/data/mariadb/
sudo rm -rf /home/hmori/data/wordpress/
mkdir -p /home/hmori/data/{mariadb,wordpress}

# 4. 完全に再構築
make re

# 5. ログを確認
make logs
```

---

## 📞 サポート

それでも問題が解決しない場合：

1. `make logs` の出力を保存
2. エラーメッセージをコピー
3. Docker バージョンを確認: `docker --version`
4. Docker Compose バージョンを確認: `docker-compose --version`

頑張ってください！ 🚀

