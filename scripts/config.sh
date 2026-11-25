#!/usr/bin/env bash
# =============================================================================
# config.sh - Politique de filtrage firewalld (moindre privilège)
# Projet : Pare-feu et filtrage réseau sous Linux (Red Hat)
#
# Services autorisés dans la zone publique : ssh, http, https
# Services retirés de la zone publique     : cockpit, dhcpv6-client
#
# Usage : sudo ./config.sh
# =============================================================================

set -euo pipefail

ZONE="public"
ALLOWED_SERVICES=("ssh" "http" "https")
REMOVED_SERVICES=("cockpit" "dhcpv6-client")

# --- Vérifications préalables ------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "Erreur : ce script doit être exécuté avec sudo ou en root." >&2
    exit 1
fi

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "Erreur : firewall-cmd introuvable. Installez firewalld." >&2
    exit 1
fi

if ! systemctl is-active --quiet firewalld; then
    echo "firewalld n'est pas démarré, démarrage en cours..."
    systemctl enable --now firewalld
fi

# --- Ajout des services autorisés --------------------------------------------

echo "== Autorisation des services dans la zone '${ZONE}' =="
for svc in "${ALLOWED_SERVICES[@]}"; do
    if firewall-cmd --permanent --zone="$ZONE" --query-service="$svc" >/dev/null 2>&1; then
        echo "  [déjà actif]  $svc"
    else
        firewall-cmd --permanent --zone="$ZONE" --add-service="$svc" >/dev/null
        echo "  [ajouté]      $svc"
    fi
done

# --- Suppression des services superflus --------------------------------------

echo "== Suppression des services superflus =="
for svc in "${REMOVED_SERVICES[@]}"; do
    if firewall-cmd --permanent --zone="$ZONE" --query-service="$svc" >/dev/null 2>&1; then
        firewall-cmd --permanent --zone="$ZONE" --remove-service="$svc" >/dev/null
        echo "  [retiré]      $svc"
    else
        echo "  [absent]      $svc"
    fi
done

# --- Application et vérification ---------------------------------------------

echo "== Application de la configuration =="
firewall-cmd --reload >/dev/null
echo "  Rechargement effectué."

echo "== Vérification finale =="
firewall-cmd --zone="$ZONE" --list-all

# Contrôle : la liste des services doit correspondre exactement à la politique
current=$(firewall-cmd --permanent --zone="$ZONE" --list-services | tr ' ' '\n' | sort | tr '\n' ' ')
expected=$(printf '%s\n' "${ALLOWED_SERVICES[@]}" | sort | tr '\n' ' ')

if [[ "$current" == "$expected" ]]; then
    echo "OK : services conformes à la politique (${ALLOWED_SERVICES[*]})."
else
    echo "ATTENTION : services inattendus détectés." >&2
    echo "  Attendu : $expected" >&2
    echo "  Trouvé  : $current" >&2
    exit 2
fi
