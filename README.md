# ArgoCD application setup

Generate a secret to access GH through API

```bash
kubectl -n argocd create secret generic gh-pat \
--from-literal=token=<YOUR_GITHUB_PAT>
```