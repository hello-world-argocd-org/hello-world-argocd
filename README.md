# Argo CD ApplicationSet & Project Configuration

This repository contains the configuration for managing application deployments via [Argo CD](https://argo-cd.readthedocs.io/).

It defines:

- **Argo CD AppProject** — a logical grouping of applications, their allowed sources, destinations, and permissions.
- **Argo CD ApplicationSet** — a set of rules to automatically generate one or more `Application` resources, based on patterns such as:
    - Lists of repositories
    - Git directory structures
    - Other supported generators

With this setup:

- All applications are deployed through GitOps — the cluster state is fully driven from Git.
- Environments (e.g., `dev`, `stage`, `prod`) can be managed in a consistent and repeatable way.
- Adding a new application or environment only requires updating the configuration in Git; Argo CD detects and applies the changes.

> **Note:** This repo does not contain application source code — only the Argo CD configuration for managing deployments.

## Flow description

Check the project [documentation](https://hello-world-argocd-org.github.io/hello-world-argocd/) to read more about the proposed flow.