#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


set -eEuo pipefail

upsert_config_entry primary '
Kind = "service-defaults"
Name = "s2"
Protocol = "http"
EnvoyExtensions = [
  {
    Name = "builtin/property-override"
    Arguments = {
      ProxyType = "connect-proxy"
      Patches = [{
        ResourceFilter = {
          ResourceType = "listener"
          TrafficDirection = "inbound"
        }
        Op = "add"
        Path = "/stat_prefix"
        Value = "custom.stats.s2"
      }]
    }
  }
]
'

upsert_config_entry primary '
Kind = "service-defaults"
Name = "s3"
Protocol = "http"
'

upsert_config_entry primary '
Kind = "service-defaults"
Name = "s1"
Protocol = "http"
EnvoyExtensions = [
  {
    Name = "builtin/property-override"
    Arguments = {
      ProxyType = "connect-proxy"
      Patches = [
        {
          ResourceFilter = {
            ResourceType = "cluster"
            TrafficDirection = "outbound"
          }
          Op = "add"
          Path = "/upstream_connection_options/tcp_keepalive/keepalive_probes"
          Value = 1234
        },
        {
          ResourceFilter = {
            ResourceType = "cluster"
            TrafficDirection = "outbound"
            Services = [{
              Name = "s2"
            }]
          }
          Op = "remove"
          Path = "/outlier_detection"
        }
      ]
    }
  }
]
'

register_services primary

gen_envoy_bootstrap s1 19000 primary
gen_envoy_bootstrap s2 19001 primary
