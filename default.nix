{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.senpro.oci-containers.graflux;

in

{

  options = {
    senpro.oci-containers.graflux = {
      grafana = {
        traefik.fqdn = mkOption {
          type = types.str;
          default = "grafana.local";
          example = "grafana.example.com";
          description = ''
            Defines the FQDN under which the predefined container endpoint should be reachable.
          '';
        };
      };
      influxdb = {
        traefik.fqdn = mkOption {
          type = types.str;
          default = "influxdb.local";
          example = "influxdb.example.com";
          description = ''
            Defines the FQDN under which the predefined container endpoint should be reachable.
          '';
        };
      };
      prometheus = {
        traefik.fqdn = mkOption {
          type = types.str;
          default = "prometheus.local";
          example = "prometheus.example.com";
          description = ''
            Defines the FQDN under which the predefined container endpoint should be reachable.
          '';
        };
      };
    };
  };

  config = {
    virtualisation.oci-containers.containers = {
      grafana = {
        image = "docker.io/grafana/grafana:latest";
        extraOptions = [
          "--net=proxy"
        ];
        volumes = [
          "graflux-grafana-data:/var/lib/grafana"
          "graflux-grafana-prov:/etc/grafana/provisioning"
        ];
        environment = {
          GF_PANELS_DISABLE_SANITIZE_HTML = "true";
          GF_FEATURE_TOGGLES_ENABLE = "internationalization";
        };
        user = "104:104";
        autoStart = true;
      };
      influxdb = {
        image = "docker.io/library/influxdb:latest";
        extraOptions = [
          "--net=proxy"
        ];
        volumes = [
          "graflux-influxdb-conf:/etc/influxdb2"
          "graflux-influxdb-data:/var/lib/influxdb2"
        ];
        autoStart = true;
      };
      prometheus = {
        image = "docker.io/prom/prometheus:latest";
        extraOptions = [
          "--net=proxy"
        ];
        volumes = [
          "graflux-prometheus-conf:/etc/prometheus"
          "graflux-prometheus-data:/prometheus"
        ];
        cmd = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          "--storage.tsdb.retention.time=200h"
          "--web.config.file=/etc/prometheus/web.yml"
          "--web.console.libraries=/etc/prometheus/console_libraries"
          "--web.console.templates=/etc/prometheus/consoles"
          "--web.enable-lifecycle"
          "--web.enable-remote-write-receiver"
        ];
        autoStart = true;
      };
    };
    systemd.services = {
      "podman-grafana" = {
        postStart = ''
          ${pkgs.coreutils-full}/bin/printf '%s\n' "http:" \
          "  routers:"   \
          "    grafana:" \
          "      rule: \"Host(\`${cfg.grafana.traefik.fqdn}\`)\"" \
          "      service: \"grafana\"" \
          "      entryPoints:" \
          "      - \"https2-tcp\"" \
          "      tls: true" \
          "    influxdb:" \
          "      rule: \"Host(\`${cfg.influxdb.traefik.fqdn}\`)\"" \
          "      service: \"influxdb\"" \
          "      entryPoints:" \
          "      - \"https2-tcp\"" \
          "      tls: true" \
          "    prometheus:" \
          "      rule: \"Host(\`${cfg.prometheus.traefik.fqdn}\`)\"" \
          "      service: \"prometheus\"" \
          "      entryPoints:" \
          "      - \"https2-tcp\"" \
          "      tls: true" \
          "  services:" \
          "    grafana:" \
          "      loadBalancer:" \
          "        passHostHeader: true" \
          "        servers:" \
          "        - url: \"http://grafana:3000\"" \
          "    influxdb:" \
          "      loadBalancer:" \
          "        passHostHeader: true" \
          "        servers:" \
          "        - url: \"http://influxdb:8086\"" \
          "    prometheus:" \
          "      loadBalancer:" \
          "        passHostHeader: true" \
          "        servers:" \
          "        - url: \"http://prometheus:9090\"" > $(${pkgs.podman}/bin/podman volume inspect traefik --format "{{.Mountpoint}}")/conf.d/apps-graflux.yml
        '';
      };
    };
  };

}
