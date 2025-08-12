# GitOps Suggested Flow

## Glossary

- **GitOps** – [https://opengitops.dev/](https://opengitops.dev/)
- **Project** – A single deliverable (application or library) within a single Git repository.
    - Its build should result in an artifact (e.g., JAR for Java) and a container (e.g., Docker image).
    - This repository should not contain any deployment-related configuration (no Helm, Kubernetes).
    - **Example repo**: `hello-world`
    - **Access**: Developers
    - **Change frequency**: Very frequent (new features, bug fixes)
    - **Change strategy**: Whatever the team decides (e.g., only through PRs, trunk-based, GitFlow, etc.)

- **GitOps Repo** – A single Git repository for an application.
    - Naming pattern: `[nameoftheapplication-delivery]`
    - Contains deployment-related configuration (Helm, Kubernetes)
        - **Does not** contain source code
        - **Does not** contain ArgoCD-related configuration
    - Represents the state of the world
    - Can use base charts (e.g., Helm base charts – [https://github.com/hello-world-argocd-org/base-helm-charts](https://github.com/hello-world-argocd-org/base-helm-charts))
    - **Example repo**: `hello-world-delivery`
    - **Access**: Developers, Ops, GitHub bot
    - **Change frequency**: Frequent (with each application container upload or configuration change)
    - **Change strategy**: **Only** through pull requests

- **ArgoCD Configuration** – Defines how to create Argo applications.

- **ArgoCD Configuration Repository** – Centralized repository containing ArgoCD configurations.
    - **Does not** contain Helm charts or Kubernetes specifics
    - May reference Helm charts for applications
    - Owned by the platform team
    - **Example repo**: `hello-world-argocd`
    - **Access**: Ops
    - **Change frequency**: Rare (e.g., when setting up new applications)
    - **Change strategy**: **Only** through pull requests

---

## Repository Types

1. [Application](https://github.com/hello-world-argocd-org/hello-world)
2. [Application GitOps](https://github.com/hello-world-argocd-org/hello-world-delivery)
3. [ArgoCD Configuration](https://github.com/hello-world-argocd-org/hello-world-argocd)
4. [Helm base chart](https://github.com/hello-world-argocd-org/helm-base-charts)

---

## The Process

### Prerequisites

**GitOps Repo Branch Protection**
- Set rules on `main`:
    - Require PRs
    - Require status checks to pass
    - Require reviews (conditionally via CODEOWNERS)
    - Disallow force pushes

**CODEOWNERS Rules**
- Require manual review for production changes (`/prod/ @sre-team`, `/non-prod/ @ci-bot`)
- In branch protection rules, enable:  
  ✅ “Require review from Code Owners”

**Effect:**
- Changes to `/prod/` require human review
- Changes to `/non-prod/` can be auto-approved if the CI bot is a code owner

---

## Flows

### Application Change

1. Developer makes a source code change and merges to `main`.
2. Application CI pipeline runs:
- Generates a new version (e.g., `10.0.0-202508071234-abcdef12345`)
- Compiles and tests the application
- Uploads a JAR with the new version
- Uploads a Docker image with the new JAR
- Creates a PR to the GitOps repo to update `values.yml` for the dev environment
    - PR auto-merges when the GitOps repo build passes
3. ArgoCD detects the repo change:
- Deploys the application to the dev environment
- Triggers component tests in CI
4. CI tool runs component tests:
- After passing, tags the application and image
- Repeats for other environments until production
- **Continuous delivery**: PR for production version change requires manual merge
- **Continuous deployment**: PR set to auto-merge

---

### Config Change

- **Non-Prod Change:**
- Create a PR with config change
- PR build passes → Auto-merge → ArgoCD deploys

- **Prod Change:**
- Create a PR with config change
- PR build passes → Manual approval required (for continuous delivery) → ArgoCD deploys

---

### New Application

1. Create new application Git repo
2. Ops team updates ArgoCD repo with new application configuration
3. ArgoCD picks it up automatically and creates a new Application

---

## Additional Topics

### Security – Access

- Introduce PR reviews and disable auto-merge for sensitive environments
- Additional safeguard: Disable automatic ArgoCD sync
- Use ArgoCD's sync preview feature
- Fully automated testing for PRs

### Security – Credentials

- Use **SealedSecrets** stored in Git, encrypted with the cluster's public key and decrypted with the private key
- Alternative: Use **ExternalSecrets** with Vault

### Database Schema Updates

- Spring Boot + Flyway/Liquibase: Schema updates happen on app startup
- Alternative: Use a Kubernetes Batch Job for schema upgrades with ArgoCD _presync_ hook

### Configuration – Reloading

- Use a _dynamic annotation_ in Kubernetes deployment based on config checksum (example in `base-helm-charts`)
- Config change updates checksum → K8s restarts application

### Base Chart

- Maintain separately versioned Helm chart, overridden by teams via native Helm mechanisms
- Run `helm lint` and unit tests with Helm plugin
- Optionally run end-to-end tests with Kind

### Observability

- Scrape Argo's built-in Prometheus metrics
- Use ArgoCD Notification Controller for alerts and notifications

---

## Proof of Concept (POC)

- [https://github.com/hello-world-argocd-org](https://github.com/hello-world-argocd-org)

---

## Examples

- [https://github.com/sabre1041/argocd-up-and-running-book](https://github.com/sabre1041/argocd-up-and-running-book)
- [https://github.com/christianh814/example-kubernetes-go-repo](https://github.com/christianh814/example-kubernetes-go-repo)
- [https://github.com/gnunn-gitops/standards](https://github.com/gnunn-gitops/standards)
- [https://platform.cloudogu.com/en/blog/gitops-repository-patterns-part-3-repository-patterns/](https://platform.cloudogu.com/en/blog/gitops-repository-patterns-part-3-repository-patterns/)
- [https://github.com/gitops-bridge-dev/gitops-bridge](https://github.com/gitops-bridge-dev/gitops-bridge)

---

## Books

- [O’Reilly – GitOps](https://learning.oreilly.com/library/view/-/9781098141998/ch14.html) 
