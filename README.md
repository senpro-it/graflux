# graflux
Configuration snippet for NixOS to spin up a graflux Pod using Podman.

## :tada: `Getting started`

Add the following statement to your `imports = [];` in `configuration.nix` and do a `nixos-rebuild`:

```
  <path-to-default-nix> {
    senpro.oci-containers.graflux = {
      grafana = {
        traefik.fqdn = "<your-fqdn>";
      };
      influxdb = {
        traefik.fqdn = "<your-fqdn>";
      };
      prometheus = {
        traefik.fqdn = "<your-prometheus-fqdn>";
      };
    };
  }
```
