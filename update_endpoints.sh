#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-${SCRIPT_DIR}}"
MD_FILE="${MD_FILE:-endpoints.md}"
HTML_FILE="${HTML_FILE:-docs/index.html}"
DAGU_SERVICE="${DAGU_SERVICE:-dagu}"
ENV_FILE="${ENV_FILE:-${REPO_DIR}/.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

DAGU_HOST_PORT="${DAGU_HOST_PORT:-3012}"
SELENIUM_VNC_PORT="${SELENIUM_VNC_PORT:-7900}"
REFINEMENT_PORTAL_PORT="${REFINEMENT_PORTAL_PORT:-5002}"
FRONTEND_PORT="${FRONTEND_PORT:-5000}"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -z "$IP" ]; then
  echo "ERROR: Public IP not found"
  exit 1
fi

cd "$REPO_DIR"

mkdir -p "$(dirname "$HTML_FILE")"

cat <<EOF > "$MD_FILE"
# EC2 Service Endpoints

## Dagu
http://${IP}:${DAGU_HOST_PORT}

## Selenium (noVNC)
http://${IP}:${SELENIUM_VNC_PORT}

## RefinementPortal
http://${IP}:${REFINEMENT_PORTAL_PORT}

## Frontend
http://${IP}:${FRONTEND_PORT}
EOF

cat <<EOF > "$HTML_FILE"
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Orbitando Infra Endpoints</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f4f1ea;
      --panel: #fffdf8;
      --ink: #1f2937;
      --muted: #6b7280;
      --accent: #0f766e;
      --accent-dark: #115e59;
      --border: #d6d3d1;
      --shadow: 0 18px 40px rgba(31, 41, 55, 0.12);
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Segoe UI", sans-serif;
      color: var(--ink);
      background:
        radial-gradient(circle at top left, rgba(15, 118, 110, 0.12), transparent 32%),
        linear-gradient(180deg, #f8f5ef 0%, var(--bg) 100%);
    }

    main {
      max-width: 920px;
      margin: 0 auto;
      padding: 48px 20px 64px;
    }

    .hero {
      margin-bottom: 28px;
    }

    h1 {
      margin: 0 0 10px;
      font-size: clamp(2rem, 5vw, 3.4rem);
      line-height: 1;
    }

    .subtitle {
      margin: 0;
      max-width: 56ch;
      color: var(--muted);
      font-size: 1.05rem;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 18px;
    }

    .card {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 20px;
      padding: 22px;
      box-shadow: var(--shadow);
    }

    .card h2 {
      margin: 0 0 10px;
      font-size: 1.25rem;
    }

    .card p {
      margin: 0 0 18px;
      color: var(--muted);
      word-break: break-word;
    }

    .button {
      display: inline-block;
      width: 100%;
      padding: 12px 16px;
      border-radius: 999px;
      text-align: center;
      text-decoration: none;
      font-weight: 700;
      color: #ffffff;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-dark) 100%);
      transition: transform 0.15s ease, box-shadow 0.15s ease;
      box-shadow: 0 10px 24px rgba(15, 118, 110, 0.22);
    }

    .button:hover {
      transform: translateY(-1px);
    }

    footer {
      margin-top: 28px;
      color: var(--muted);
      font-size: 0.95rem;
    }

    code {
      font-family: "SFMono-Regular", Consolas, monospace;
    }
  </style>
</head>
<body>
  <main>
    <section class="hero">
      <h1>Orbitando Infra</h1>
      <p class="subtitle">
        Accesos directos a los servicios publicados en la instancia EC2 actual.
      </p>
    </section>

    <section class="grid">
      <article class="card">
        <h2>Dagu</h2>
        <p><code>http://${IP}:${DAGU_HOST_PORT}</code></p>
        <a class="button" href="http://${IP}:${DAGU_HOST_PORT}" target="_blank" rel="noreferrer">Abrir Dagu</a>
      </article>

      <article class="card">
        <h2>Selenium (noVNC)</h2>
        <p><code>http://${IP}:${SELENIUM_VNC_PORT}</code></p>
        <a class="button" href="http://${IP}:${SELENIUM_VNC_PORT}" target="_blank" rel="noreferrer">Abrir noVNC</a>
      </article>

      <article class="card">
        <h2>Refinement Portal</h2>
        <p><code>http://${IP}:${REFINEMENT_PORTAL_PORT}</code></p>
        <a class="button" href="http://${IP}:${REFINEMENT_PORTAL_PORT}" target="_blank" rel="noreferrer">Abrir Portal</a>
      </article>

      <article class="card">
        <h2>Frontend</h2>
        <p><code>http://${IP}:${FRONTEND_PORT}</code></p>
        <a class="button" href="http://${IP}:${FRONTEND_PORT}" target="_blank" rel="noreferrer">Abrir Frontend</a>
      </article>
    </section>

    <footer>
      Esta pagina se genera automaticamente desde <code>update_endpoints.sh</code>.
    </footer>
  </main>
</body>
</html>
EOF

git config user.email "ec2@infra.local"
git config user.name "EC2 Bootstrap"

git add "$MD_FILE" "$HTML_FILE"
git diff --cached --quiet || git commit -m "Update service endpoints (${IP})"
git push origin main

docker compose restart "$DAGU_SERVICE"
