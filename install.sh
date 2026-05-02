#!/usr/bin/env bash
# =============================================================================
# jt-glogi18n installer
# Graylog Traditional Chinese UI pack — install / update / uninstall tool
#
# Usage:
#   sudo ./install.sh                install (interactive)
#   sudo ./install.sh update         refresh static assets only
#   sudo ./install.sh uninstall      remove
#        ./install.sh status         check install state
#        ./install.sh doctor         full environment diagnostic
#   sudo ./install.sh rollback       restore previous nginx.conf backup
#        ./install.sh help           full usage
#
# Supports:
#   - Package managers: apt / dnf / yum / zypper / apk / pacman
#   - Init systems:     systemd / OpenRC / sysvinit
#   - SELinux:          enforcing mode (auto-applies httpd_sys_content_t)
#   - Firewalls:        firewalld / ufw (auto-open on request)
#   - Nginx flavors:    nginx / OpenResty / Tengine
#
# VERSION: 1.3.6
#
# Copyright (c) Jason Cheng (Jason Tools) <jason@jason.tools>
# Licensed under the Apache License, Version 2.0.
# https://github.com/jasoncheng7115/jt-glogi18n
# =============================================================================

# ---- bash re-exec guard (allow `sh install.sh`) -----------------------------
if [ -z "${BASH_VERSION:-}" ]; then
    if command -v bash >/dev/null 2>&1; then
        exec bash "$0" "$@"
    else
        echo "ERROR: this script requires bash" >&2
        exit 1
    fi
fi

set -euo pipefail

# ---- constants ---------------------------------------------------------------
readonly INSTALLER_VERSION="1.3.6"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly STATIC_SRC="$SCRIPT_DIR/static"
readonly REQUIRED_FILES=(
    graylog-i18n-zh-tw.js
    graylog-i18n-dict.json
    graylog-i18n-patch.css
    graylog-i18n-locales.json
)

readonly INSTALL_ROOT="/opt/jt-glogi18n"
readonly INSTALL_DIR="$INSTALL_ROOT/static"
readonly BACKUP_ROOT="$INSTALL_ROOT/backups"
readonly NGINX_CONF="/etc/nginx/conf.d/graylog-i18n.conf"
readonly SNIPPET_FILE="/etc/nginx/snippets/graylog-i18n.conf"
readonly LOG_FILE="/var/log/jt-glogi18n-install.log"

# ---- runtime flags / env -----------------------------------------------------
ASSUME_YES="${ASSUME_YES:-0}"
DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"
DOMAIN="${DOMAIN:-}"
BACKEND="${BACKEND:-127.0.0.1:9000}"
SSL_CRT="${SSL_CRT:-}"
SSL_KEY="${SSL_KEY:-}"
OPEN_FIREWALL="${OPEN_FIREWALL:-ask}"   # yes | no | ask
SKIP_PREFLIGHT="${SKIP_PREFLIGHT:-0}"
NO_COLOR="${NO_COLOR:-}"

# ---- output / logging --------------------------------------------------------
if [ -n "$NO_COLOR" ] || [ ! -t 1 ]; then
    C_R=''; C_G=''; C_Y=''; C_B=''; C_BOLD=''; C_0=''
else
    C_R=$'\e[31m'; C_G=$'\e[32m'; C_Y=$'\e[33m'
    C_B=$'\e[34m'; C_BOLD=$'\e[1m'; C_0=$'\e[0m'
fi

_logf() {
    if [ "$(id -u)" -eq 0 ] 2>/dev/null; then
        printf '%s [%s] %s\n' "$(date -Iseconds 2>/dev/null || date)" "$1" "$2" \
            >> "$LOG_FILE" 2>/dev/null || true
    fi
}
info() { printf '%s[i]%s %s\n' "$C_B" "$C_0" "$*"; _logf INFO "$*"; }
ok()   { printf '%s[OK]%s %s\n' "$C_G" "$C_0" "$*"; _logf OK   "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_Y" "$C_0" "$*"; _logf WARN "$*"; }
err()  { printf '%s[x]%s %s\n' "$C_R" "$C_0" "$*" >&2; _logf ERR  "$*"; }
step() { printf '\n%s==>%s %s%s%s\n' "$C_B" "$C_0" "$C_BOLD" "$*" "$C_0"; _logf STEP "$*"; }
vlog() { [ "$VERBOSE" = 1 ] && info "$*" || _logf DBG "$*"; }
die()  { err "$*"; exit 1; }

confirm() {
    local q="$1" def="${2:-y}" ans p
    [ "$ASSUME_YES" = "1" ] && return 0
    if [ "$def" = "y" ]; then p="$q [Y/n] "; else p="$q [y/N] "; fi
    if ! read -rp "$p" ans; then return 1; fi
    ans="${ans:-$def}"
    [[ "$ans" =~ ^[Yy]$ ]]
}

run() {
    if [ "$DRY_RUN" = 1 ]; then
        printf '  [dry-run] %s\n' "$*"
        return 0
    fi
    vlog "exec: $*"
    "$@"
}

# ---- pre-flight helpers ------------------------------------------------------
need_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "Must run as root. Try: sudo $0 $*"
    fi
}

ensure_log_file() {
    [ "$(id -u)" -eq 0 ] || return 0
    : > "$LOG_FILE" 2>/dev/null || return 0
    chmod 0640 "$LOG_FILE" 2>/dev/null || true
}

check_sources() {
    local f missing=0
    [ -d "$STATIC_SRC" ] || die "Source directory not found: $STATIC_SRC (run from project root)"
    for f in "${REQUIRED_FILES[@]}"; do
        [ -f "$STATIC_SRC/$f" ] || { err "Missing source file: $STATIC_SRC/$f"; missing=1; }
    done
    [ "$missing" = 0 ] || die "Source files incomplete, aborting"

    if command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "$STATIC_SRC/graylog-i18n-dict.json"    >/dev/null \
            || die "graylog-i18n-dict.json is not valid JSON"
        python3 -m json.tool "$STATIC_SRC/graylog-i18n-locales.json" >/dev/null \
            || die "graylog-i18n-locales.json is not valid JSON"
        ok "Source files present and JSON is valid"
    else
        warn "python3 not found, skipping JSON validation"
    fi
}

check_disk_space() {
    local avail_kb
    avail_kb="$(df -Pk "$INSTALL_ROOT" 2>/dev/null \
                   || df -Pk /opt 2>/dev/null \
                   || df -Pk / 2>/dev/null | tail -1)"
    avail_kb="$(echo "$avail_kb" | tail -1 | awk '{print $4}' 2>/dev/null || echo "")"
    if [ -n "$avail_kb" ] && [ "$avail_kb" -lt 10240 ] 2>/dev/null; then
        warn "Only ${avail_kb} KB free (< 10MB). Consider freeing disk space."
    fi
}

# ---- environment detection ---------------------------------------------------
detect_os() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_LIKE="${ID_LIKE:-}"
        OS_PRETTY="${PRETTY_NAME:-$OS_ID}"
    else
        OS_ID="$(uname -s)"
        OS_LIKE=""
        OS_PRETTY="$OS_ID"
    fi
    vlog "os: $OS_PRETTY (id=$OS_ID like=$OS_LIKE)"
}

detect_pm() {
    for pm in apt-get dnf yum zypper apk pacman; do
        if command -v "$pm" >/dev/null 2>&1; then
            PM="$pm"
            vlog "package manager: $PM"
            return 0
        fi
    done
    PM=""
    return 1
}

detect_init() {
    if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
        INIT=systemd
    elif command -v rc-service >/dev/null 2>&1; then
        INIT=openrc
    elif command -v service >/dev/null 2>&1; then
        INIT=sysv
    else
        INIT=none
    fi
    vlog "init: $INIT"
}

detect_nginx_flavor() {
    NGINX_FLAVOR="nginx"
    local ver
    ver="$(nginx -v 2>&1 || true)"
    case "$ver" in
        *openresty*) NGINX_FLAVOR="openresty" ;;
        *tengine*)   NGINX_FLAVOR="tengine"   ;;
        *nginx*)     NGINX_FLAVOR="nginx"     ;;
    esac
    vlog "nginx flavor: $NGINX_FLAVOR ($ver)"
}

# returns 0 if a Graylog reverse proxy NOT owned by us is detected.
# If $NGINX_CONF exists (our own full-conf file), we filter its contents
# out of the nginx -T dump before matching so a prior install.sh run does
# not make us think the user installed their own proxy.
detect_existing_graylog_proxy() {
    command -v nginx >/dev/null 2>&1 || return 1
    local dump
    dump="$(nginx -T 2>/dev/null || true)"
    [ -n "$dump" ] || return 1
    if [ -f "$NGINX_CONF" ]; then
        # Drop lines we own: the generated comment marker delimits our block.
        # Fall back to filtering our server_name line if the marker changed.
        local ours
        ours="$(cat "$NGINX_CONF" 2>/dev/null || true)"
        # Remove every line that appears verbatim in our own config.
        dump="$(printf '%s\n' "$dump" | grep -Fvx -f <(printf '%s\n' "$ours") || true)"
    fi
    grep -Eq 'X-Graylog-Server-URL|proxy_pass[[:space:]]+https?://[^;]*:9000\b' <<<"$dump"
}

check_sub_filter() {
    # 1. Compiled-in module (most distros: official nginx.org, Debian nginx-full/extras, RHEL).
    if nginx -V 2>&1 | grep -q -- '--with-http_sub_module'; then
        ok "nginx has http_sub_module (compiled in)"
        return 0
    fi
    # 2. Dynamic module (some Debian/Ubuntu splits ship it as ngx_http_sub_filter_module.so).
    local mod
    for mod in /usr/share/nginx/modules/ngx_http_sub_filter_module.so \
               /usr/lib/nginx/modules/ngx_http_sub_filter_module.so \
               /usr/lib64/nginx/modules/ngx_http_sub_filter_module.so; do
        if [ -e "$mod" ]; then
            ok "nginx has http_sub_module (dynamic: $mod)"
            # Warn if it's not loaded via load_module in the running config.
            if ! (nginx -T 2>/dev/null | grep -Fq "$(basename "$mod")"); then
                warn "Dynamic module present but not loaded — add this to nginx.conf top level:"
                warn "    load_module modules/$(basename "$mod");"
            fi
            return 0
        fi
    done
    err "This nginx build does not include http_sub_module (sub_filter won't work)"
    case "$OS_ID" in
        debian|ubuntu)
            warn "Debian/Ubuntu: install 'nginx-full' or 'nginx-extras'" ;;
        rhel|centos|rocky|almalinux|fedora)
            warn "RHEL-family: enable EPEL or use the official nginx.org repo" ;;
    esac
    die "Please use a distribution package or rebuild nginx with --with-http_sub_module"
}

check_port_conflict() {
    local port="$1" tool="" out=""
    for t in ss netstat; do
        if command -v "$t" >/dev/null 2>&1; then tool="$t"; break; fi
    done
    [ -n "$tool" ] || return 0
    case "$tool" in
        ss)      out="$(ss -lntH 2>/dev/null | awk -v p=":$port$" '$4 ~ p')" ;;
        netstat) out="$(netstat -lnt 2>/dev/null | awk -v p=":$port$" '$4 ~ p')" ;;
    esac
    if [ -n "$out" ]; then
        if command -v nginx >/dev/null 2>&1 \
           && ss -lntp 2>/dev/null | grep -q '"nginx"'; then
            vlog "port $port occupied by nginx itself"
            return 0
        fi
        warn "Port $port is already in use:"
        echo "$out" | sed 's/^/    /'
        return 1
    fi
    return 0
}

# Scan nginx config files for ssl_certificate / ssl_certificate_key
# directives and populate MISSING_SSL_PAIRS with "cert_path|key_path"
# entries for pairs whose files don't exist on disk.
#
# Important: we do NOT use `nginx -T` here, because when the running
# config already fails (e.g. one of the cert files is missing), nginx -T
# emits nothing to stdout — exactly the case we need to handle. Instead
# we walk /etc/nginx with `find -L` (so sites-enabled symlinks are
# followed) and scan every regular file we land on.
#
# Returns 0 when at least one missing pair was found, 1 otherwise.
detect_broken_ssl_in_existing_conf() {
    MISSING_SSL_PAIRS=()
    local conf_root="/etc/nginx"
    [ -d "$conf_root" ] || return 1
    # Concatenate all readable files under /etc/nginx (follow symlinks).
    local dump
    dump="$(find -L "$conf_root" -type f -print 2>/dev/null \
            | while IFS= read -r f; do cat -- "$f" 2>/dev/null; echo; done)"
    [ -n "$dump" ] || return 1
    # Strip lines that are entirely a comment so we don't pick up paths
    # inside disabled examples (basic guard, not a full parser).
    local stripped
    stripped="$(printf '%s\n' "$dump" | sed -e 's/[[:space:]]*#.*$//')"
    local certs keys
    certs="$(printf '%s\n' "$stripped" \
        | awk '/^[[:space:]]*ssl_certificate[[:space:]]/{
                gsub(/^[[:space:]]*ssl_certificate[[:space:]]+/, "");
                gsub(/[";]/, "");
                gsub(/[[:space:]].*$/, "");
                if (length($0)) print
            }')"
    keys="$(printf '%s\n' "$stripped" \
        | awk '/^[[:space:]]*ssl_certificate_key[[:space:]]/{
                gsub(/^[[:space:]]*ssl_certificate_key[[:space:]]+/, "");
                gsub(/[";]/, "");
                gsub(/[[:space:]].*$/, "");
                if (length($0)) print
            }')"
    local cert_arr=() key_arr=()
    while IFS= read -r line; do [ -n "$line" ] && cert_arr+=("$line"); done <<<"$certs"
    while IFS= read -r line; do [ -n "$line" ] && key_arr+=("$line"); done <<<"$keys"
    # NOTE: declaring n/m/max on a single `local` line + inline arithmetic
    # ($((n>m?m:n))) tripped `set -u` in some bash builds (the inner refs
    # to n/m are evaluated before the local bindings settle). Keep these
    # on separate lines.
    local n m max i
    n=${#cert_arr[@]}
    m=${#key_arr[@]}
    if [ "$n" -lt "$m" ]; then max=$n; else max=$m; fi
    for ((i=0; i<max; i++)); do
        local c="${cert_arr[$i]}" k="${key_arr[$i]}"
        if [ ! -f "$c" ] || [ ! -f "$k" ]; then
            MISSING_SSL_PAIRS+=("$c|$k")
        fi
    done
    [ "${#MISSING_SSL_PAIRS[@]}" -gt 0 ]
}

# Generate a 10-year self-signed cert at every path in MISSING_SSL_PAIRS.
# CN defaults to $DOMAIN, falls back to hostname when DOMAIN is "_" or empty.
generate_selfsigned_for_missing() {
    command -v openssl >/dev/null 2>&1 || { err "openssl not found, cannot self-sign"; return 1; }
    local pair cert key cert_dir key_dir cn
    cn="${DOMAIN:-}"
    if [ -z "$cn" ] || [ "$cn" = "_" ]; then
        cn="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo localhost)"
    fi
    for pair in "${MISSING_SSL_PAIRS[@]}"; do
        cert="${pair%|*}"
        key="${pair#*|}"
        cert_dir="$(dirname "$cert")"
        key_dir="$(dirname "$key")"
        run install -d -m 0755 "$cert_dir"
        run install -d -m 0700 "$key_dir"
        info "Generating self-signed cert (10 years, CN=$cn): $cert"
        if [ "$DRY_RUN" = 1 ]; then
            info "[dry-run] would openssl req -x509 -newkey rsa:2048 -days 3650 ..."
            continue
        fi
        if ! openssl req -x509 -newkey rsa:2048 -nodes \
                -days 3650 \
                -keyout "$key" \
                -out "$cert" \
                -subj "/CN=$cn" \
                -addext "subjectAltName=DNS:$cn,DNS:localhost,IP:127.0.0.1" \
                >/dev/null 2>&1; then
            warn "openssl failed at $cert; retrying without -addext (older openssl?)"
            openssl req -x509 -newkey rsa:2048 -nodes \
                -days 3650 \
                -keyout "$key" \
                -out "$cert" \
                -subj "/CN=$cn" \
                >/dev/null 2>&1 \
                || { err "Failed to generate self-signed cert at $cert"; return 1; }
        fi
        chmod 0644 "$cert" 2>/dev/null || true
        chmod 0600 "$key"  2>/dev/null || true
        ok "Self-signed cert written: $cert (10 years, key: $key)"
    done
    return 0
}

check_backend_reachable() {
    local host port
    host="${BACKEND%:*}"; port="${BACKEND##*:}"
    if command -v curl >/dev/null 2>&1; then
        local code
        code="$(curl -sS --max-time 3 -o /dev/null -w '%{http_code}' \
                  "http://$BACKEND/" 2>/dev/null)" || code="000"
        case "$code" in
            200|301|302|401|403) ok "Graylog backend $BACKEND is up (HTTP $code)" ;;
            000)                  warn "Graylog backend $BACKEND is unreachable (curl timeout)" ;;
            *)                    warn "Graylog backend $BACKEND returned HTTP $code (unexpected)" ;;
        esac
    elif command -v nc >/dev/null 2>&1; then
        if nc -z -w 2 "$host" "$port" 2>/dev/null; then
            ok "Graylog backend $BACKEND reachable (TCP)"
        else
            warn "Graylog backend $BACKEND not reachable (TCP)"
        fi
    else
        vlog "Neither curl nor nc available; skipping backend reachability check"
    fi
}

# ---- nginx install -----------------------------------------------------------
install_nginx() {
    detect_pm || die "No supported package manager found (apt/dnf/yum/zypper/apk/pacman)"
    info "Installing nginx via $PM ..."
    case "$PM" in
        apt-get) run env DEBIAN_FRONTEND=noninteractive apt-get update \
                && run env DEBIAN_FRONTEND=noninteractive apt-get install -y nginx ;;
        dnf)     run dnf install -y nginx ;;
        yum)     run yum install -y nginx ;;
        zypper)  run zypper -n install nginx ;;
        apk)     run apk add --no-cache nginx ;;
        pacman)  run pacman -S --noconfirm nginx ;;
    esac
    local started=0
    case "$INIT" in
        systemd)
            if run systemctl enable --now nginx 2>/dev/null; then started=1
            elif run systemctl start nginx 2>/dev/null; then started=1
            fi
            ;;
        openrc)
            run rc-update add nginx default 2>/dev/null || warn "rc-update add nginx failed"
            if run rc-service nginx start 2>/dev/null; then started=1; fi
            ;;
        sysv)
            if run service nginx start 2>/dev/null; then started=1; fi
            ;;
    esac
    if [ "$started" = 0 ] && [ "$DRY_RUN" != 1 ]; then
        warn "Could not start nginx automatically. Start it manually and re-run this installer."
    fi
    ok "nginx installed"
}

ensure_nginx() {
    if command -v nginx >/dev/null 2>&1; then
        detect_nginx_flavor
        ok "Detected $NGINX_FLAVOR: $(nginx -v 2>&1 | head -1)"
        return 0
    fi
    warn "nginx is not installed"
    confirm "Install nginx automatically?" y || die "Aborted (please install nginx and re-run)"
    install_nginx
    detect_nginx_flavor
}

# ---- reload nginx with fallbacks --------------------------------------------
reload_nginx() {
    case "$INIT" in
        systemd)
            if systemctl list-unit-files nginx.service >/dev/null 2>&1; then
                systemctl reload nginx 2>/dev/null && return 0
                systemctl restart nginx 2>/dev/null && return 0
            fi
            ;;
        openrc)
            rc-service nginx reload 2>/dev/null && return 0
            rc-service nginx restart 2>/dev/null && return 0
            ;;
        sysv)
            service nginx reload 2>/dev/null && return 0
            service nginx restart 2>/dev/null && return 0
            ;;
    esac
    nginx -s reload 2>/dev/null && return 0
    nginx 2>/dev/null && return 0
    return 1
}

# ---- backup / rollback -------------------------------------------------------
# backup_file <src> [type-tag]
#   Writes a timestamped copy of <src> under $BACKUP_ROOT and updates
#   $BACKUP_ROOT/LATEST.<type-tag> with the absolute path to that copy.
#   Typed pointers prevent unrelated backups from clobbering the rollback
#   target for a specific artifact (e.g. nginx_conf).
backup_file() {
    local src="$1" type="${2:-generic}" stamp dest
    [ -f "$src" ] || return 0
    if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would back up $src (type=$type)"
        return 0
    fi
    stamp="$(date +%Y%m%d-%H%M%S)"
    dest="$(mktemp -d "$BACKUP_ROOT/${stamp}-XXXXXX")"
    chmod 0700 "$dest"
    cp -a "$src" "$dest/"
    echo "$dest/$(basename "$src")" > "$BACKUP_ROOT/LATEST.$type"
    vlog "backup: $src -> $dest (type=$type)"
}

rollback_latest() {
    local pointer="$BACKUP_ROOT/LATEST.nginx_conf"
    [ -s "$pointer" ] || die "No nginx config backup available to roll back to"
    local path; path="$(cat "$pointer")"
    [ -f "$path" ] || die "Backup file missing: $path"
    local base="$(basename "$path")"
    [ "$base" = "graylog-i18n.conf" ] || die "Unexpected backup type: $base"
    confirm "Restore $path to $NGINX_CONF ?" y || return 0
    if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would restore $NGINX_CONF from $path"
        return 0
    fi
    cp -a "$path" "$NGINX_CONF"
    ok "Restored $NGINX_CONF"
    if nginx -t >/dev/null 2>&1; then
        if reload_nginx; then
            ok "nginx reloaded"
        else
            warn "nginx -t passed but reload failed; try: systemctl restart nginx"
        fi
    else
        warn "Restored config still fails 'nginx -t'; inspect manually:"
        nginx -t 2>&1 | sed 's/^/    /' || true
    fi
}

# ---- SELinux / firewall ------------------------------------------------------
apply_selinux_context() {
    command -v getenforce >/dev/null 2>&1 || return 0
    local state; state="$(getenforce 2>/dev/null || echo Disabled)"
    [ "$state" = "Enforcing" ] || { vlog "SELinux: $state, skipping"; return 0; }
    info "SELinux is Enforcing, applying contexts and booleans"

    # 1. Persistent policy: semanage fcontext survives relabels.
    #    On RHEL 9 derivatives semanage may live in policycoreutils-python-utils.
    local semanage_ok=0
    if command -v semanage >/dev/null 2>&1; then
        semanage_ok=1
    elif [ -n "${PM:-}" ] || detect_pm; then
        info "semanage not found; attempting to install policycoreutils-python-utils"
        case "$PM" in
            dnf|yum)  run "$PM" install -y policycoreutils-python-utils 2>/dev/null && semanage_ok=1 || true ;;
            apt-get)  run env DEBIAN_FRONTEND=noninteractive apt-get install -y policycoreutils 2>/dev/null && semanage_ok=1 || true ;;
            zypper)   run zypper -n install policycoreutils-python-utils 2>/dev/null && semanage_ok=1 || true ;;
        esac
    fi
    if [ "$semanage_ok" = 1 ] && command -v semanage >/dev/null 2>&1; then
        run semanage fcontext -a -t httpd_sys_content_t "${INSTALL_DIR}(/.*)?" 2>/dev/null \
            || run semanage fcontext -m -t httpd_sys_content_t "${INSTALL_DIR}(/.*)?" 2>/dev/null \
            || warn "semanage fcontext failed (non-fatal)"
        if command -v restorecon >/dev/null 2>&1; then
            run restorecon -R "$INSTALL_DIR" 2>/dev/null \
                && ok "SELinux: persistent httpd_sys_content_t applied to $INSTALL_DIR" \
                || warn "restorecon failed"
        fi
    elif command -v chcon >/dev/null 2>&1; then
        # 2. Fallback: transient label. Will be reset by autorelabel / full restorecon.
        run chcon -Rt httpd_sys_content_t "$INSTALL_DIR" 2>/dev/null \
            && warn "SELinux: applied httpd_sys_content_t via chcon (NOT persistent — install policycoreutils-python-utils for durability)" \
            || warn "SELinux chcon failed"
    fi

    if command -v setsebool >/dev/null 2>&1; then
        run setsebool -P httpd_can_network_connect 1 2>/dev/null \
            && ok "SELinux: httpd_can_network_connect=on" \
            || warn "SELinux setsebool failed"
    fi
}

open_firewall() {
    [ "$OPEN_FIREWALL" = "no" ] && { vlog "firewall: skipped (env)"; return 0; }
    local ports=("80/tcp")
    [ -n "$SSL_CRT" ] && ports+=("443/tcp")

    if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
        if [ "$OPEN_FIREWALL" = "yes" ] || confirm "firewalld is active. Open ${ports[*]}?" y; then
            run firewall-cmd --permanent --add-service=http >/dev/null 2>&1 || true
            [ -n "$SSL_CRT" ] && run firewall-cmd --permanent --add-service=https >/dev/null 2>&1 || true
            run firewall-cmd --reload >/dev/null 2>&1 || true
            ok "firewalld: http${SSL_CRT:+/https} opened"
        fi
    elif command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        if [ "$OPEN_FIREWALL" = "yes" ] || confirm "ufw is active. Open ${ports[*]}?" y; then
            run ufw allow 80/tcp  >/dev/null 2>&1 || true
            [ -n "$SSL_CRT" ] && run ufw allow 443/tcp >/dev/null 2>&1 || true
            ok "ufw: 80${SSL_CRT:+/443}/tcp opened"
        fi
    else
        vlog "Neither firewalld nor ufw active; skipping firewall configuration"
    fi
}

# ---- file operations ---------------------------------------------------------
install_static() {
    run install -d -m 0755 "$INSTALL_DIR"
    run install -d -m 0700 "$BACKUP_ROOT"
    local f
    # If the user cloned the repo to $INSTALL_ROOT (so $STATIC_SRC IS
    # $INSTALL_DIR), `install -m 0644 src dst` would error with
    # "are the same file". Detect via -ef (same inode) and skip the copy.
    if [ -d "$STATIC_SRC" ] && [ -d "$INSTALL_DIR" ] && [ "$STATIC_SRC" -ef "$INSTALL_DIR" ]; then
        info "Source dir is the install dir ($STATIC_SRC); files already in place, no copy needed."
        for f in "${REQUIRED_FILES[@]}"; do
            run chmod 0644 "$INSTALL_DIR/$f" 2>/dev/null || true
        done
    else
        for f in "${REQUIRED_FILES[@]}"; do
            run install -m 0644 "$STATIC_SRC/$f" "$INSTALL_DIR/"
        done
    fi
    ok "Static files deployed to $INSTALL_DIR"
    apply_selinux_context
}

# ---- config: prompt / validate ----------------------------------------------
valid_domain() {
    [[ "$1" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]] \
        || [[ "$1" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]
}
valid_backend() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+:[0-9]+$ ]]
}

prompt_config() {
    if [ -z "$DOMAIN" ]; then
        if [ "$ASSUME_YES" = "1" ]; then
            DOMAIN="_"
            info "DOMAIN not set; using catch-all server_name (_) for non-interactive install"
        else
            while :; do
                read -rp "Site domain (e.g. graylog.example.com / IP, blank = catch-all): " DOMAIN
                if [ -z "$DOMAIN" ]; then
                    DOMAIN="_"
                    info "Using catch-all server_name (_) — Nginx will accept requests on any Host header."
                    break
                fi
                valid_domain "$DOMAIN" && break
                warn "Invalid domain format, try again"
            done
        fi
    else
        [ "$DOMAIN" = "_" ] || valid_domain "$DOMAIN" || die "Invalid DOMAIN format: $DOMAIN"
    fi

    if [ "$ASSUME_YES" != "1" ]; then
        local tmp
        read -rp "Graylog backend host:port [$BACKEND]: " tmp || true
        BACKEND="${tmp:-$BACKEND}"
    fi
    valid_backend "$BACKEND" || die "Invalid BACKEND format (expected host:port): $BACKEND"

    if [ -z "$SSL_CRT" ] && [ "$ASSUME_YES" != "1" ]; then
        if confirm "Enable HTTPS? (strongly recommended)" y; then
            read -rp "  SSL certificate path (.crt/.pem): " SSL_CRT
            read -rp "  SSL private key path (.key):     " SSL_KEY
        fi
    fi
    if [ -n "$SSL_CRT" ]; then
        [ -f "$SSL_CRT" ] || die "SSL certificate not found: $SSL_CRT"
        [ -n "$SSL_KEY" ] || die "SSL_KEY is required when HTTPS is enabled"
        [ -f "$SSL_KEY" ] || die "SSL private key not found: $SSL_KEY"
    fi
}

# ---- config writers ----------------------------------------------------------
write_full_conf() {
    local listen_line ssl_block scheme
    if [ -n "$SSL_CRT" ]; then
        listen_line="    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;"
        ssl_block="    ssl_certificate $SSL_CRT;
    ssl_certificate_key $SSL_KEY;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;"
        scheme="https"
    else
        listen_line="    listen 80;
    listen [::]:80;"
        ssl_block=""
        scheme="http"
    fi

    backup_file "$NGINX_CONF" nginx_conf

    local tmp
    tmp="$(mktemp)"
    cat > "$tmp" <<EOF
# jt-glogi18n — generated by install.sh v$INSTALLER_VERSION on $(date -Iseconds 2>/dev/null || date)
# Rerunning install.sh will back up this file before overwriting.
server {
$listen_line
    server_name $DOMAIN;
$ssl_block

    client_max_body_size 50M;

    # Translation static assets
    location /graylog-i18n/ {
        alias $INSTALL_DIR/;
        expires 1h;
        add_header Cache-Control "public, must-revalidate";
        add_header X-Content-Type-Options "nosniff";
    }

    location / {
        proxy_pass http://$BACKEND;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Graylog-Server-URL $scheme://\$server_name/;

        proxy_http_version 1.1;
        proxy_read_timeout 300;
        proxy_connect_timeout 30;

        # Must clear Accept-Encoding so the backend sends plaintext
        # (sub_filter cannot rewrite gzipped content).
        proxy_set_header Accept-Encoding "";

        # Override Graylog's strict CSP to allow the translation script.
        proxy_hide_header Content-Security-Policy;
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; font-src 'self' data:; connect-src 'self' https: wss: ws:; worker-src 'self' blob:; media-src 'self' data: https:;" always;

        # Inject the translation script and CSS just before </head>.
        # sub_filter_types defaults to text/html; redeclaring would warn
        # "duplicate MIME type 'text/html'" on nginx >= 1.25.
        sub_filter_once on;
        sub_filter '</head>' '<link rel="stylesheet" href="/graylog-i18n/graylog-i18n-patch.css"><script src="/graylog-i18n/graylog-i18n-zh-tw.js" defer></script></head>';

        # gzip_types defaults to text/html (see above note).
        gzip on;
        gzip_proxied any;
    }
}
EOF
    if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would write $NGINX_CONF"
        rm -f "$tmp"
    else
        mv "$tmp" "$NGINX_CONF"
        chmod 0644 "$NGINX_CONF"
        ok "Wrote $NGINX_CONF"
    fi
}

write_snippet() {
    run install -d -m 0755 "$(dirname "$SNIPPET_FILE")"
    if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would write $SNIPPET_FILE"
        return 0
    fi
    cat > "$SNIPPET_FILE" <<'EOF'
# jt-glogi18n snippet
# Include this file inside your existing Graylog "location /" block.

proxy_set_header Accept-Encoding "";

proxy_hide_header Content-Security-Policy;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; font-src 'self' data:; connect-src 'self' https: wss: ws:; worker-src 'self' blob:; media-src 'self' data: https:;" always;

sub_filter_once on;
sub_filter '</head>' '<link rel="stylesheet" href="/graylog-i18n/graylog-i18n-patch.css"><script src="/graylog-i18n/graylog-i18n-zh-tw.js" defer></script></head>';

gzip on;
gzip_proxied any;
EOF
    chmod 0644 "$SNIPPET_FILE"
    ok "Wrote snippet to $SNIPPET_FILE"
}

print_snippet_instructions() {
    cat <<EOF

${C_BOLD}An existing Graylog reverse proxy has been detected.${C_0}
To avoid touching your current configuration, this script ${C_BOLD}will NOT
modify your nginx.conf${C_0}. Please complete the following two steps manually:

  ${C_BOLD}Step 1.${C_0} Inside your existing "location / { ... }" block, add:

        include $SNIPPET_FILE;

  ${C_BOLD}Step 2.${C_0} Inside the same server block, add a static-asset location:

        location /graylog-i18n/ {
            alias $INSTALL_DIR/;
            expires 1h;
            add_header Cache-Control "public, must-revalidate";
        }

Then reload nginx:

        sudo nginx -t && sudo systemctl reload nginx

A complete server block example lives at:
    $SCRIPT_DIR/nginx/graylog-i18n.conf
EOF
}

# ---- test / verify / recover -------------------------------------------------
test_nginx_or_restore() {
    step "Testing nginx configuration"
    local out rc
    out="$(nginx -t 2>&1)"; rc=$?
    printf '%s\n' "$out" >> "$LOG_FILE" 2>/dev/null || true
    if [ $rc -eq 0 ]; then
        ok "nginx -t passed"
        return 0
    fi
    err "nginx -t failed:"
    printf '%s\n' "$out" | sed 's/^/    /'
    local pointer="$BACKUP_ROOT/LATEST.nginx_conf"
    if [ -s "$pointer" ]; then
        local bak; bak="$(cat "$pointer")"
        if [ -f "$bak" ] && confirm "Restore the previous backup $bak ?" y; then
            if [ "$DRY_RUN" = 1 ]; then
                info "[dry-run] would restore $NGINX_CONF from $bak"
                return 0
            fi
            cp -a "$bak" "$NGINX_CONF"
            ok "Restored $NGINX_CONF from backup"
            nginx -t >/dev/null 2>&1 && return 0
            warn "Restored config still fails 'nginx -t'"
        fi
    else
        if confirm "Remove the just-written $NGINX_CONF ?" y; then
            if [ "$DRY_RUN" = 1 ]; then
                info "[dry-run] would remove $NGINX_CONF"
                return 0
            fi
            rm -f "$NGINX_CONF"
            ok "Removed $NGINX_CONF"
        fi
    fi
    die "nginx configuration still invalid; please inspect manually"
}

do_reload() {
    step "Reloading nginx"
    if reload_nginx; then
        ok "nginx reloaded"
    else
        warn "reload failed; try manually: systemctl restart nginx"
    fi
}

verify_deployment() {
    command -v curl >/dev/null 2>&1 || { vlog "curl not available, skipping verification"; return 0; }
    step "Verifying deployment"
    local scheme url code host_header_args
    scheme="http"; [ -n "$SSL_CRT" ] && scheme="https"
    # When DOMAIN is the catch-all "_", don't override the Host header
    # (Nginx accepts any Host); otherwise pin it to the configured domain
    # so we hit our own server block during the local probe.
    if [ "$DOMAIN" = "_" ]; then
        host_header_args=()
    else
        host_header_args=(-H "Host: $DOMAIN")
    fi
    url="$scheme://127.0.0.1/graylog-i18n/graylog-i18n-dict.json"
    code="$(curl -sSk --max-time 5 -o /dev/null -w '%{http_code}' \
              "${host_header_args[@]}" "$url" 2>/dev/null)" || code="000"
    if [ "$code" = "200" ]; then
        ok "Static assets reachable: $url (HTTP $code)"
    else
        warn "Static asset returned HTTP $code (check nginx config / firewall)"
    fi

    url="$scheme://127.0.0.1/"
    local body
    body="$(curl -sSk --max-time 5 "${host_header_args[@]}" "$url" 2>/dev/null || true)"
    if grep -q "graylog-i18n-zh-tw.js" <<<"$body"; then
        ok "Injection confirmed: graylog-i18n-zh-tw.js present in HTML"
    else
        warn "Injection not detected. Likely causes: backend sends gzip, Accept-Encoding not cleared, or server_name mismatch"
    fi
}

# ---- commands ----------------------------------------------------------------
cmd_install() {
    need_root
    ensure_log_file
    _logf RUN "install.sh install v$INSTALLER_VERSION"
    detect_os; detect_init

    step "Checking source files"; check_sources
    check_disk_space
    step "Checking / installing nginx"; ensure_nginx; check_sub_filter
    step "Deploying static files"; install_static

    step "Detecting existing Graylog reverse proxy"
    if detect_existing_graylog_proxy; then
        warn "Existing Graylog reverse proxy detected (snippet mode)"
        write_snippet
        print_snippet_instructions
        info "Static files are in place. After manual steps, hard-reload your browser (Cmd+Shift+R / Ctrl+Shift+R)."
        return 0
    fi
    ok "No existing proxy found (full-conf mode)"

    step "Collecting configuration"
    prompt_config

    step "Pre-flight checks"
    check_backend_reachable
    check_port_conflict 80 || warn "Port 80 conflict: if it's nginx itself, ignore"
    [ -n "$SSL_CRT" ] && { check_port_conflict 443 || warn "Port 443 conflict"; }

    # Validate the *existing* nginx config BEFORE we write anything. If the
    # environment is already broken (undefined log_format, missing include,
    # etc.) the post-write 'nginx -t' fails confusingly and rollback triggers
    # even though our new file isn't the cause.
    if [ "$SKIP_PREFLIGHT" = 1 ]; then
        warn "Skipping pre-flight nginx -t (--skip-preflight). Post-write rollback may trigger if your existing config is broken."
    elif ! nginx -t >/dev/null 2>&1; then
        err "'nginx -t' already fails on your existing configuration:"
        nginx -t 2>&1 | sed 's/^/    /' || true
        if detect_broken_ssl_in_existing_conf; then
            info "Detected ${#MISSING_SSL_PAIRS[@]} broken HTTPS cert reference(s) in your existing nginx config:"
            local _pair
            for _pair in "${MISSING_SSL_PAIRS[@]}"; do
                info "  cert: ${_pair%|*}"
                info "  key : ${_pair#*|}"
            done
            if confirm "Generate 10-year self-signed certificates at those exact paths so your existing config validates?" y; then
                if generate_selfsigned_for_missing && nginx -t >/dev/null 2>&1; then
                    ok "Self-signed certs generated; existing nginx config now valid."
                else
                    err "Even after self-signing, nginx -t still fails:"
                    nginx -t 2>&1 | sed 's/^/    /' || true
                    die "Please inspect your existing nginx configuration manually."
                fi
            else
                die "Please fix the existing nginx configuration first, then re-run. (Or re-run with --skip-preflight — not recommended.)"
            fi
        else
            die "Please fix the existing nginx configuration first, then re-run. (Or re-run with --skip-preflight — not recommended.)"
        fi
    else
        ok "Existing nginx configuration is valid"
    fi

    step "Writing nginx configuration"
    write_full_conf

    test_nginx_or_restore
    open_firewall
    do_reload
    verify_deployment

    cat <<EOF

${C_G}${C_BOLD}Installation complete.${C_0}
  URL:      ${SSL_CRT:+https}${SSL_CRT:-http}://$DOMAIN/
  Backend:  $BACKEND
  Dict:     $INSTALL_DIR/graylog-i18n-dict.json
  Backups:  $BACKUP_ROOT/
  Log:      $LOG_FILE

Hard-reload your browser (Cmd+Shift+R / Ctrl+Shift+R) to skip the 1 h cache.

To update the dictionary later:   sudo $0 update
Full environment diagnostic:      $0 doctor
EOF
}

cmd_update() {
    need_root
    ensure_log_file
    detect_os; detect_init
    _logf RUN "install.sh update"
    step "Updating static files (nginx untouched)"
    check_sources
    install_static
    info "Done. Hard-reload your browser (Cmd+Shift+R / Ctrl+Shift+R) or wait up to 1 h for the cache to expire."
}

cmd_uninstall() {
    need_root
    ensure_log_file
    detect_init
    _logf RUN "install.sh uninstall"
    step "Removing jt-glogi18n"
    if [ -d "$INSTALL_DIR" ]; then
        confirm "Delete $INSTALL_DIR (contains the dictionary)?" y && {
            run rm -rf "$INSTALL_DIR"; ok "Deleted $INSTALL_DIR"
        }
    else
        info "$INSTALL_DIR does not exist"
    fi
    if [ -f "$NGINX_CONF" ]; then
        confirm "Delete $NGINX_CONF ?" y && { run rm -f "$NGINX_CONF"; ok "Deleted $NGINX_CONF"; }
    fi
    if [ -f "$SNIPPET_FILE" ]; then
        confirm "Delete $SNIPPET_FILE ?" y && {
            run rm -f "$SNIPPET_FILE"
            ok "Deleted $SNIPPET_FILE"
            warn "If you 'include'd this snippet, remove that include line from your server block"
        }
    fi
    if [ -d "$BACKUP_ROOT" ]; then
        confirm "Delete backup directory $BACKUP_ROOT ?" n && run rm -rf "$BACKUP_ROOT"
    fi
    if command -v nginx >/dev/null 2>&1 && [ -f /etc/nginx/nginx.conf ]; then
        if nginx -t 2>/dev/null; then
            reload_nginx && ok "nginx reloaded" || warn "reload failed"
        else
            warn "nginx -t reported errors; please clean up residual config manually"
        fi
    fi
    ok "Uninstall complete"
}

cmd_status() {
    detect_os; detect_init
    step "jt-glogi18n status (installer v$INSTALLER_VERSION)"
    echo "  OS:         $OS_PRETTY"
    echo "  Init:       $INIT"
    if command -v nginx >/dev/null 2>&1; then
        detect_nginx_flavor
        echo "  Nginx:      $NGINX_FLAVOR ($(nginx -v 2>&1 | head -1))"
    else
        echo "  Nginx:      ${C_R}not installed${C_0}"
    fi
    echo

    if [ -d "$INSTALL_DIR" ]; then
        ok "$INSTALL_DIR"
        (cd "$INSTALL_DIR" && ls -lh graylog-i18n-* 2>/dev/null | sed 's/^/    /')
        if [ -f "$INSTALL_DIR/graylog-i18n-dict.json" ] && command -v python3 >/dev/null 2>&1; then
            local ver
            ver="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["_meta"]["version"])' \
                      "$INSTALL_DIR/graylog-i18n-dict.json" 2>/dev/null || true)"
            [ -n "$ver" ] && ok "Dictionary version: $ver"
        fi
    else
        warn "$INSTALL_DIR does not exist (not installed)"
    fi
    [ -f "$NGINX_CONF" ]   && ok "$NGINX_CONF exists"   || info "$NGINX_CONF does not exist"
    [ -f "$SNIPPET_FILE" ] && ok "$SNIPPET_FILE exists (snippet mode)" || info "$SNIPPET_FILE does not exist"
    if [ -d "$BACKUP_ROOT" ]; then
        local n; n="$(ls "$BACKUP_ROOT" 2>/dev/null | grep -vE '^LATEST(\.|$)' | wc -l | tr -d ' ')"
        ok "Backups: $n"
    fi
    echo
    if command -v nginx >/dev/null 2>&1; then
        nginx -t 2>&1 | sed 's/^/    /' || true
    fi
}

cmd_doctor() {
    detect_os; detect_init
    step "Environment diagnostic"
    echo "  OS:               $OS_PRETTY"
    echo "  Init system:      $INIT"
    detect_pm && echo "  Package manager:  $PM" || echo "  Package manager:  ${C_R}not detected${C_0}"

    if command -v nginx >/dev/null 2>&1; then
        detect_nginx_flavor
        echo "  Nginx:            $NGINX_FLAVOR ($(nginx -v 2>&1 | head -1))"
        if nginx -V 2>&1 | grep -q -- '--with-http_sub_module'; then
            echo "  http_sub_module:  ${C_G}yes${C_0}"
        else
            echo "  http_sub_module:  ${C_R}NO (sub_filter unavailable)${C_0}"
        fi
        if nginx -t 2>/dev/null; then
            echo "  nginx -t:         ${C_G}OK${C_0}"
        else
            echo "  nginx -t:         ${C_R}FAIL${C_0}"
        fi
    else
        echo "  Nginx:            ${C_R}not installed${C_0}"
    fi

    if command -v getenforce >/dev/null 2>&1; then
        echo "  SELinux:          $(getenforce)"
    else
        echo "  SELinux:          n/a"
    fi
    if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
        echo "  Firewall:         firewalld (active)"
    elif command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        echo "  Firewall:         ufw (active)"
    else
        echo "  Firewall:         none / inactive"
    fi

    echo
    check_port_conflict 80  && echo "  Port 80:          free / self" || true
    [ -n "${SSL_CRT:-}" ] && { check_port_conflict 443 && echo "  Port 443:         free / self" || true; }

    if [ -n "${BACKEND:-}" ]; then
        echo
        echo "  Backend ${BACKEND}:"
        check_backend_reachable
    fi

    echo
    if detect_existing_graylog_proxy 2>/dev/null; then
        warn "Existing Graylog reverse proxy detected (install would use snippet mode)"
    else
        ok "No existing proxy detected (install would use full-conf mode)"
    fi

    echo
    if [ -d "$INSTALL_DIR" ]; then ok "Installed at $INSTALL_DIR"; else info "Not yet installed"; fi
}

cmd_rollback() {
    need_root
    ensure_log_file
    detect_init
    _logf RUN "install.sh rollback"
    step "Rolling back to the previous nginx config backup"
    rollback_latest
}

cmd_help() {
    cat <<EOF
jt-glogi18n installer v$INSTALLER_VERSION

Usage:
  sudo $0 [flags]              default = install (interactive)
  sudo $0 install  [flags]     install
  sudo $0 update   [flags]     refresh static files only (everyday upgrade)
  sudo $0 uninstall            remove installation
       $0 status               show install state
       $0 doctor               full environment diagnostic (run first!)
  sudo $0 rollback             restore the previous nginx.conf backup
       $0 help                 this help
       $0 version              print installer version

Flags:
  -y, --yes                    assume yes to all prompts
  -v, --verbose                verbose / debug output
  -n, --dry-run                print actions only, do not modify anything
      --domain=DOMAIN          site domain
      --backend=HOST:PORT      Graylog backend (default 127.0.0.1:9000)
      --ssl-crt=/path          TLS certificate (setting this enables HTTPS)
      --ssl-key=/path          TLS private key
      --open-firewall=yes|no   force / skip firewall opening (default: ask)
      --skip-preflight         do NOT run 'nginx -t' on the existing config
                               before writing ours (use only if you know
                               your config has unrelated pre-existing issues
                               you can't fix right now)
      --no-color               disable ANSI colors

Environment variables (equivalent to flags):
  ASSUME_YES, DRY_RUN, VERBOSE, DOMAIN, BACKEND, SSL_CRT, SSL_KEY,
  OPEN_FIREWALL, SKIP_PREFLIGHT, NO_COLOR

Install modes (auto-selected):
  A) nginx not installed        -> installed via apt/dnf/yum/zypper/apk/pacman
  B) nginx present, no proxy    -> writes $NGINX_CONF
  C) nginx already proxies GL   -> emits snippet for you to include (your conf untouched)

Unattended install example:
  sudo ./install.sh -y \\
       --domain=graylog.example.com \\
       --backend=127.0.0.1:9000 \\
       --ssl-crt=/etc/ssl/certs/graylog.crt \\
       --ssl-key=/etc/ssl/private/graylog.key

More documentation:
  README.md / README_zh-TW.md
  TROUBLESHOOTING.md / TROUBLESHOOTING_zh-tw.md
  CHANGELOG.md / CHANGELOG_zh-tw.md
EOF
}

# ---- arg parsing -------------------------------------------------------------
CMD=""
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help|help)       CMD="help"       ;;
        -V|--version|version) echo "jt-glogi18n installer v$INSTALLER_VERSION"; exit 0 ;;
        -y|--yes)             ASSUME_YES=1     ;;
        -v|--verbose)         VERBOSE=1        ;;
        -n|--dry-run)         DRY_RUN=1        ;;
        --no-color)           NO_COLOR=1; C_R=''; C_G=''; C_Y=''; C_B=''; C_BOLD=''; C_0='' ;;
        --domain)             shift; DOMAIN="${1:-}" ;;
        --domain=*)           DOMAIN="${1#*=}" ;;
        --backend)            shift; BACKEND="${1:-}" ;;
        --backend=*)          BACKEND="${1#*=}" ;;
        --ssl-crt)            shift; SSL_CRT="${1:-}" ;;
        --ssl-crt=*)          SSL_CRT="${1#*=}" ;;
        --ssl-key)            shift; SSL_KEY="${1:-}" ;;
        --ssl-key=*)          SSL_KEY="${1#*=}" ;;
        --open-firewall)      shift; OPEN_FIREWALL="${1:-ask}" ;;
        --open-firewall=*)    OPEN_FIREWALL="${1#*=}" ;;
        --skip-preflight)     SKIP_PREFLIGHT=1 ;;
        install|update|uninstall|status|doctor|rollback) CMD="$1" ;;
        --) shift; break ;;
        -*) err "Unknown flag: $1"; echo; cmd_help; exit 1 ;;
        *)  err "Unknown command: $1"; echo; cmd_help; exit 1 ;;
    esac
    shift
done
CMD="${CMD:-install}"

# One-line version banner at the top of every actionable run
case "$CMD" in
    help|version) ;;
    *) printf '%sjt-glogi18n installer v%s%s\n' "$C_BOLD" "$INSTALLER_VERSION" "$C_0" ;;
esac

case "$CMD" in
    install)   cmd_install   ;;
    update)    cmd_update    ;;
    uninstall) cmd_uninstall ;;
    status)    cmd_status    ;;
    doctor)    cmd_doctor    ;;
    rollback)  cmd_rollback  ;;
    help)      cmd_help      ;;
    *)         cmd_help; exit 1 ;;
esac
