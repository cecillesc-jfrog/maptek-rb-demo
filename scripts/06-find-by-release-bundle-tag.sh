#!/usr/bin/env bash
# USE CASE: Find release bundles by tag (e.g. QA-Passed)
# RB v2 tags are stored in the Lifecycle service, not in Artifactory AQL.
# Run via: bash scripts/aql/06-find-by-release-bundle-tag.sh
#
# Requires: TOKEN env var set to a valid JFrog access token

BUNDLE_NAME="${1:-maptek-geo-suite}"
TAG="${2:-QA-Passed}"
JF_URL="https://hts1.jfrog.io"

curl -s \
  -H "Authorization: Bearer $TOKEN" \
  "${JF_URL}/lifecycle/api/v2/release_bundle/records/${BUNDLE_NAME}?tag=${TAG}" | jq .

