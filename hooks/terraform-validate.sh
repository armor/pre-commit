#!/usr/bin/env bash

# This is a clone of https://github.com/gruntwork-io/pre-commit/blob/master/hooks/terraform-validate.sh
# It adds support for modules that use the Azure Resource Manager provider 2.0+.
# This provider requires an explicit `features` block which in most cases is supplied by a super module.
# See: https://github.com/hashicorp/terraform/pull/24896

function cleanup() {
  if [ -n "$TF_BUILD" ]; then
    # we are in a azure devops pipeline - clean everything
    git clean -fdX;
  fi

  # remove untracked or ignored provider.tf that we may have added during this process
  git --no-pager status --untracked-files=all --ignored=matching "provider.tf" "*/provider.tf" --porcelain=v2 | \
    grep provider.tf | \
    cut -f2- -d' ' | \
    grep -vE /$ | \
    xargs rm -f
}
export -f cleanup;

function main() {
  trap 'cleanup' exit
  local result=0;

  for dir in $(echo "$@" | xargs -n1 dirname | sort -u | uniq); do
    pushd "$dir" >/dev/null || exit 1
    if ! grep -q -R --include='*.tf' -E '^provider "(azurerm|aws)" {' .; then
      tee provider.tf >/dev/null<<_EOF_
provider "azurerm" {
  features {}
}
provider "aws" {
  region = "us-east-1"
}
_EOF_
    fi

    terraform init -backend=false >/dev/null
    terraform validate -json
    if [[ $result -gt 0 ]];
    then result="$?"
    fi
    popd >/dev/null || exit 1
  done

  exit "$result"
}

main "$@"
