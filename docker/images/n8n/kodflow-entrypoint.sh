#!/bin/sh
set -e

# Kodflow auto-setup: if N8N_DEV_ENTERPRISE_MODE is enabled,
# auto-create the owner account on first boot so the instance
# is immediately ready for API/provider testing.

if [ "$N8N_DEV_ENTERPRISE_MODE" = "true" ]; then
  EMAIL="${N8N_DEFAULT_OWNER_EMAIL:-dev@kodflow.io}"
  FIRST="${N8N_DEFAULT_OWNER_FIRST_NAME:-Dev}"
  LAST="${N8N_DEFAULT_OWNER_LAST_NAME:-Kodflow}"
  PASS="${N8N_DEFAULT_OWNER_PASSWORD:-Kodflow1Dev!}"
  PORT="${N8N_PORT:-5678}"

  # Run auto-setup as a background node script
  # Redirect to /proc/1/fd/1 so logs appear in docker output even after exec
  node -e "
    const http = require('http');
    const PORT = ${PORT};
    const MAX = 120;
    let att = 0;

    function log(msg) {
      try { require('fs').writeSync(1, '[kodflow] ' + msg + '\n'); } catch(e) {}
    }

    function check() {
      if (att++ >= MAX) { log('WARN: n8n not ready in 240s, skipping'); return; }
      http.get('http://127.0.0.1:' + PORT + '/rest/settings', (res) => {
        let d = '';
        res.on('data', c => d += c);
        res.on('end', () => {
          if (d.includes('instanceId')) {
            if (d.includes('\"isInstanceOwnerSetUp\":true')) {
              log('Owner already configured, skipping');
            } else {
              log('n8n ready, creating owner (${EMAIL})...');
              setup(0);
            }
          } else { setTimeout(check, 2000); }
        });
      }).on('error', () => setTimeout(check, 2000));
    }

    function setup(retry) {
      if (retry >= 5) { log('Owner setup failed after 5 attempts'); return; }
      const body = JSON.stringify({email:'${EMAIL}',firstName:'${FIRST}',lastName:'${LAST}',password:'${PASS}'});
      const req = http.request({hostname:'127.0.0.1',port:PORT,path:'/rest/owner/setup',method:'POST',
        headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(body)}
      }, (res) => {
        let d = '';
        res.on('data', c => d += c);
        res.on('end', () => {
          if (d.includes('\"id\"')) { log('Owner created successfully (${EMAIL})'); }
          else { log('Attempt '+(retry+1)+': '+d.substring(0,100)); setTimeout(() => setup(retry+1), 5000); }
        });
      });
      req.on('error', (e) => { log('Request error: '+e.message); setTimeout(() => setup(retry+1), 5000); });
      req.write(body);
      req.end();
    }

    log('Waiting for n8n to be fully ready...');
    setTimeout(check, 3000);
  " > /proc/1/fd/1 2>&1 &
fi

# Delegate to the original entrypoint
exec /docker-entrypoint.sh "$@"
