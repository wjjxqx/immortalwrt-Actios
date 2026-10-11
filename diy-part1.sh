#!/bin/bash
set -x
echo "DIY_P1_SH=$DIY_P1_SH"
echo "GITHUB_WORKSPACE=$GITHUB_WORKSPACE"
ls -la "$GITHUB_WORKSPACE/$DIY_P1_SH"
echo "Running script"