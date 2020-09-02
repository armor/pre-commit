#!/usr/bin/env bash

set -e

# This is a clone of https://github.com/gruntwork-io/pre-commit/blob/master/hooks/terraform-validate.sh
# It adds support for modules that use the Azure Resource Manager provider 2.0+.
# This provider requires an explicit `features` block which in most cases is supplied by a super module.
# See: https://github.com/hashicorp/terraform/pull/24896

function main() {
  local azurerm_provider_version="2.25.0"

  if [[ "$1" = "--azurerm-provider-version"* ]]; then
    azurerm_provider_version="${1//--azurerm-provider-version=/}"
  fi

  for dir in $(echo "$@" | xargs -n1 dirname | sort -u | uniq); do
    pushd "$dir" >/dev/null
    if [ -n "$azurerm_provider_version" ]; then
      cat << EOF > provider.tf
provider "azurerm" {
  version = "$azurerm_provider_version"
  features {}
}
EOF
    fi
    terraform init -backend=false
    terraform validate
    rm provider.tf
    popd >/dev/null
  done
}

main "$@"
