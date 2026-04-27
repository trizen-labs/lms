#!/bin/bash
# ─── Frappe LMS — EC2 Bootstrap Script ──────────────────────────────────────
# Runs on first boot via EC2 user_data (Terraform templatefile substitution).
#
# Two modes:
#   No-domain (testing) — domain_name is empty:
#     Pulls the dev docker-compose from the LMS repo and starts bench.
#     Site available at http://IP:8000/lms  (takes ~10 min to initialise).
#
#   Domain (production) — domain_name is set:
#     Downloads easy-install.py. Deploy is triggered MANUALLY after DNS is
#     pointed at this IP (Let's Encrypt requires DNS to resolve first).
# ────────────────────────────────────────────────────────────────────────────
set -euo pipefail
exec > /var/log/lms-setup.log 2>&1

DOMAIN="${domain_name}"
EMAIL="${admin_email}"
VERSION="${lms_version}"
PROJECT="${project_name}"

echo "=== [$(date)] Bootstrap started ==="
echo "    Mode: $( [ -z "$DOMAIN" ] && echo 'no-domain (test)' || echo "domain ($DOMAIN)" )"

# ── 1. System update ─────────────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -yq
apt-get install -yq \
  curl wget python3 python3-pip \
  ca-certificates gnupg lsb-release \
  dnsutils

# ── 2. Install Docker ─────────────────────────────────────────────────────────
echo "=== [$(date)] Installing Docker ==="
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker
apt-get install -yq docker-compose-plugin
docker --version
docker compose version

# ─────────────────────────────────────────────────────────────────────────────
# BRANCH A — No domain: run dev docker-compose at boot, no SSL needed
# ─────────────────────────────────────────────────────────────────────────────
if [ -z "$DOMAIN" ]; then

  echo "=== [$(date)] No domain — starting dev docker-compose ==="

  WORKDIR="/home/ubuntu/frappe-lms"
  mkdir -p "$WORKDIR"

  wget -q -O "$WORKDIR/docker-compose.yml" \
    https://raw.githubusercontent.com/frappe/lms/develop/docker/docker-compose.yml

  wget -q -O "$WORKDIR/init.sh" \
    https://raw.githubusercontent.com/frappe/lms/develop/docker/init.sh

  chown -R ubuntu:ubuntu "$WORKDIR"

  cd "$WORKDIR"
  sudo -u ubuntu docker compose up -d

  PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

  echo "=== [$(date)] Dev stack started ==="
  echo "    Bench init runs inside the container — takes ~10 minutes."
  echo "    Watch: sudo -u ubuntu docker compose -f $WORKDIR/docker-compose.yml logs -f"
  echo ""
  echo "    Once ready:"
  echo "      LMS portal : http://$PUBLIC_IP:8000/lms"
  echo "      Frappe Desk: http://$PUBLIC_IP:8000/app"
  echo "      Username   : Administrator  |  Password: admin"

# ─────────────────────────────────────────────────────────────────────────────
# BRANCH B — Domain set: prepare files, deploy manually after DNS is ready
# ─────────────────────────────────────────────────────────────────────────────
else

  echo "=== [$(date)] Domain mode — downloading easy-install.py ==="

  cd /home/ubuntu
  wget -q -O easy-install.py https://frappe.io/easy-install.py
  chown ubuntu:ubuntu easy-install.py

  cat > /home/ubuntu/deploy-lms.sh << DEPLOY_SCRIPT
#!/bin/bash
# Run AFTER your DNS A record for $DOMAIN points to this server's Elastic IP.
set -euo pipefail
exec > /var/log/lms-deploy.log 2>&1

echo "=== [\$(date)] Deploying Frappe LMS — $DOMAIN ==="

for i in \$(seq 1 12); do
  if host "$DOMAIN" > /dev/null 2>&1; then
    echo "    DNS OK"
    break
  fi
  if [ "\$i" -eq 12 ]; then
    echo "ERROR: DNS not ready after 3 minutes. Check your A record and retry."
    exit 1
  fi
  echo "    Attempt \$i: DNS not ready, waiting 15 s..."
  sleep 15
done

python3 /home/ubuntu/easy-install.py deploy \\
  --project="$PROJECT" \\
  --email="$EMAIL" \\
  --image=ghcr.io/frappe/lms \\
  --version="$VERSION" \\
  --app=lms \\
  --sitename="$DOMAIN"

echo ""
echo "=== [\$(date)] Done! ==="
echo "    LMS portal : https://$DOMAIN/lms"
echo "    Frappe Desk: https://$DOMAIN/app"
echo "    Username   : Administrator"
DEPLOY_SCRIPT

  chown ubuntu:ubuntu /home/ubuntu/deploy-lms.sh
  chmod 750 /home/ubuntu/deploy-lms.sh

  echo "=== [$(date)] System ready ==="
  echo "    1. Point DNS A record for $DOMAIN to this server's Elastic IP"
  echo "    2. SSH in and run: bash /home/ubuntu/deploy-lms.sh"
  echo "    3. Watch progress: tail -f /var/log/lms-deploy.log"

fi

echo "=== [$(date)] Bootstrap complete ==="
echo "  3. Watch deploy progress: tail -f /var/log/lms-deploy.log"
