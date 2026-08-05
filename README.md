<p align="center">
  <img src=".github/assets/logo-lockup.png" width="720" alt="AlienCommons logo">
</p>

[![Licensing](https://img.shields.io/badge/Licensing-see_COPYING.md-blue?style=flat-square)](COPYING.md)
[![Python](https://img.shields.io/badge/Python-3.14-3776AB?style=flat-square&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-6-092E20?style=flat-square&logo=django)](https://djangoproject.com)
[![Vue](https://img.shields.io/badge/Vue-3-4FC08D?style=flat-square&logo=vue.js)](https://vuejs.org)
[![Nuxt](https://img.shields.io/badge/Nuxt-4-00DC82?style=flat-square&logo=nuxt.js)](https://nuxt.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docker.com)

<!-- README-I18N:START -->

**English** | [中文](./README.zh.md)

<!-- README-I18N:END -->

[Overview](#overview) • [Documentation](#documentation) • [Environments](#environments) • [License](#license) 

## Overview

AlienCommons is a community platform built for Technical Minecraft players. It provides a space for players to publish articles and participate in discussions.

The project is currently in its early stages under heavy development.

## Documentation

| Audience     | Description                               | Link                                       |
| ------------ | ----------------------------------------- |--------------------------------------------|
| Users        | Platform usage guide, community rules     | [`docs/users/`](docs/users/)               |
| Contributors | Architecture, setup, development workflow | [`docs/contributors/`](docs/contributors/) |
| AlienMark    | Markdown syntax reference and API         | [`docs/alienmark/`](docs/alienmark/)       |

All documentation is available in English and Chinese (中文) and built with [Zensical](https://zensical.org/).

Please note that some materials may be not fully up-to-date in this stage.

## Environments

AlienCommons uses three environments:

- **`dev`** — local development with Docker Compose
- **`stg`** — staging, hosted on AWS, mirrors production as closely as practical
- **`pro`** — production, hosted on AWS with Cloudflare DNS for `aliencommons.com`

## License

License terms are provided by the `LICENSE` file in each applicable package;
see [COPYING.md](COPYING.md). Any use of AlienCommons branding materials, in
any form or medium, is strictly prohibited without prior express written
permission from Lazy Alien Server; see the
[AlienCommons Branding Materials License](branding/LICENSE).
