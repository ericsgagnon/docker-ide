

apt update
apt install -y apt-transport-https gnupg2 curl lsb-release
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
# Verify the keyring - this should yield "OK"
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list
apt update
apt install -y getenvoy-envoy

mkdir -p /opt/envoy && cd /opt/envoy
touch /opt/envoy/envoy.yaml

docker run -dit -p 1800:80 -p 10000:10000 -p 1900:8080  --name envoy ericsgagnon/ide:dev

docker rm -fv envoy


        
# static_resources:

#   listeners:
#   - name: listener_0
#     address:
#       socket_address:
#         address: 0.0.0.0
#         port_value: 10000
#     filter_chains:
#     - filters:
#       - name: envoy.filters.network.http_connection_manager
#         typed_config:
#           "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
#           stat_prefix: reverse_proxy
#           access_log:
#           - name: envoy.access_loggers.stdout
#             typed_config:
#               "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
#           http_filters:
#           - name: envoy.filters.http.router
#           upgrade_configs:
#           - upgrade_type: websocket
#           route_config:
#             name: local_routes
#             virtual_hosts:
#             - name: local_routes
#               domains: ["*"]
#               routes:
#               - match:
#                   prefix: "/code"
#                 route:
#                   cluster: code_server
#                   prefix_rewrite: "/"
#               - match:
#                   prefix: "/pgadmin"
#                 route:
#                   cluster: pgadmin
#                   #prefix_rewrite: "/"
#               - match:
#                   prefix: "/rstudio"
#                 route:
#                   cluster: 
#                   prefix_rewrite: "/"
#               - match:
#                   prefix: "/"
#                 route:
#                   cluster: 
#                   prefix_rewrite: "/"

#   clusters:
#   - name: code_server
#     connect_timeout: 10s
#     load_assignment:
#       cluster_name: code_server
#       endpoints:
#       - lb_endpoints:
#         - endpoint:
#             address:
#               socket_address:
#                 address: 127.0.0.1
#                 port_value: 8080





static_resources:

  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: reverse_proxy
          use_remote_address: true
          normalize_path: true
          merge_slashes: true
          common_http_protocol_options:
            idle_timeout: 7200s
          access_log:
          - name: envoy.access_loggers.stdout
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
          http_filters:
          - name: envoy.filters.http.router
          upgrade_configs:
          - upgrade_type: websocket
          route_config:
            name: default
            virtual_hosts:
            - name: default
              domains: ["*"]
              routes:
              - match:
                  prefix: "/code"
                route:
                  cluster: code_server
                  prefix_rewrite: "/"

  clusters:
  - name: code_server
    connect_timeout: 60s
    load_assignment:
      cluster_name: code_server
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8080
    #transport_socket:
      #name: envoy.transport_sockets.tls
      #typed_config:
        #"@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
        #sni: www.envoyproxy.io








# https://stackoverflow.com/questions/67347469/envoy-filter-to-intercept-upstream-response
    patch:
      operation: INSERT_AFTER
      value: 
       name: envoy.custom-resp
       typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
          inlineCode: |
            function envoy_on_response(response_handle) 
              if response_handle:headers():get(":status") == "408" then
                -- send message depending on your queue, eg via httpCall()
                -- Overwrite status and body
                response_handle:headers():replace(":status", "202")
              else 
                -- get response body as jsonString
                local body = response_handle:body()
                local jsonString = tostring(body:getBytes(0, body:length()))
                -- do something, eg replace secret by regex 
                jsonString = jsonString:gsub("(foo|bar)", "")
                response_handle:body():set(jsonString)
              end
            end








apt-get update && apt-get install -y apt-transport-https gnupg2 curl lsb-release
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/getenvoy.list
apt-get update && apt-get install -y getenvoy-envoy












