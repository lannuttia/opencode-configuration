# opencode-configuration (Archived)

> **This repository has been archived.** The agents, skills, and commands previously bundled here are now available as an [OCX](https://github.com/kdcokenny/ocx) registry at [codeberg.org/lannuttia/ocx-registry](https://codeberg.org/lannuttia/ocx-registry). Please use the OCX registry going forward.

## Migrating to OCX

Install [OCX](https://github.com/kdcokenny/ocx):

```sh
curl -fsSL https://ocx.kdco.dev/install.sh | sh
```

Add the registry and install components:

```sh
ocx init
ocx registry add https://lannuttia.codeberg.page/ocx-registry/ --name lannuttia
ocx add lannuttia/workspace
```

See the [OCX registry README](https://codeberg.org/lannuttia/ocx-registry) for full documentation on available components and usage.

## License

[MIT](LICENSE)
