# AZDO Agent via melange + apko

This directory now supports a full Wolfi-native package/image flow.

## Files

- `melange.yaml`: builds local package `azdo-agent-tools` (includes `start.sh` and toolchain binaries)
- `apko.yaml`: assembles final image from Wolfi packages + local package repo
- `build-apko.sh`: one-command build wrapper

## Build

```bash
cd /home/brendan/projects/sita/brendan/Dockerfile/azdo_agent
./build-apko.sh
```

Build output:

- `packages/x86_64/azdo-agent-tools-0.1.0-r0.apk`
- `packages/x86_64/APKINDEX.tar.gz`
- `azdo-agent-apko.tar`

## Load and test

```bash
docker load -i azdo-agent-apko.tar
# apko appends arch to the tag on load:
docker run --rm --entrypoint /bin/bash azdo-agent:apko-amd64 -lc 'melange version && az version'
```

## Notes

- `melange` is pinned via runtime dependency: `melange=0.45.3-r1`.
- `start.sh` is installed to `/azp/start.sh` and used as image entrypoint.
- The build script uses `--privileged` for melange due bubblewrap namespace requirements in containerized builds.
