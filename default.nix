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
      alertmanager = {
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
      alertmanager = {
        image = "docker.io/prom/alertmanager:latest";
        extraOptions = [
          "--net=proxy"
        ];
        volumes = [
          "graflux-alertmanager-conf:/config"
          "graflux-alertmanager-data:/data"
        ];
        cmd = [
          "--log.level=debug"
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
          "    alertmanager:" \
          "      rule: \"Host(\`${cfg.alertmanager.traefik.fqdn}\`)\"" \
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
          "    alertmanager:" \
          "      loadBalancer:" \
          "        passHostHeader: true" \
          "        servers:" \
          "        - url: \"http://alertmanager:9093\"" > $(${pkgs.podman}/bin/podman volume inspect traefik --format "{{.Mountpoint}}")/conf.d/apps-graflux.yml
          ${pkgs.coreutils-full}/bin/printf '%s\n' "route:" \
          ""   \
          "receivers:" > $(${pkgs.podman}/bin/podman volume inspect graflux-alertmanager-conf --format "{{.Mountpoint}}")/alertmanager.yml
        '';
      };
    };
  };

}
