#!/usr/bin/env bash
set -euo pipefail

kubectl delete namespace muchtodo --ignore-not-found
