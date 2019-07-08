#!/bin/bash
#
# Simple base64 encode the string passed as argument
# Can be useful for hand creating K8s secrets in Secrets manifest
echo -n "$1" | base64 -w 0; echo ""