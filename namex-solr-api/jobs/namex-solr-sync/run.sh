#!/bin/sh
set -e

# Derive the namex-solr-api service URL dynamically using the GCP metadata server.
# DEPLOYMENT_PROJECT is injected by the Cloud Run Job (from clouddeploy.yaml deploy-project-id).
PROJECT_NUMBER=$(curl -sf -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/project/numeric-project-id)

case "${DEPLOYMENT_PROJECT}" in
  a083gt-dev)         SHORT_ENV="dev" ;;
  a083gt-test)        SHORT_ENV="test" ;;
  a083gt-integration) SHORT_ENV="sandbox" ;;
  a083gt-prod)        SHORT_ENV="prod" ;;
  *)                  SHORT_ENV="${DEPLOYMENT_PROJECT##*-}" ;;
esac

SERVICE_URL="https://namex-solr-api-${SHORT_ENV}-${PROJECT_NUMBER}.northamerica-northeast1.run.app"

echo "Triggering sync: ${SERVICE_URL}/internal/solr/update/sync"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' "${SERVICE_URL}/internal/solr/update/sync")
echo "Response: ${HTTP_CODE}"

if [ "${HTTP_CODE}" != "200" ]; then
  echo "ERROR: Sync returned HTTP ${HTTP_CODE}"
  exit 1
fi
