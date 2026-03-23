#!/bin/bash

missing=()

for tool in trivy gitleaks cloc gh; do
  if ! command -v "$tool" &> /dev/null; then
    missing+=("$tool")
  else
    version=$("$tool" --version 2>/dev/null | head -1)
    echo "  $tool: $version"
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "WARNING: Missing software: ${missing[*]}"
  echo "Please install the missing tools before proceeding."
else
  echo "All required security/analysis tools are installed."
fi
