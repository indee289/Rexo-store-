#!/bin/bash
export NODE_OPTIONS=""
unset NODE_OPTIONS
exec node test_wallet_rpc_failures.js
