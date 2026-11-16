# Rotating GitHub PATs

Steps to take every time the GitHub Personal Access Tokens (PATs) used by Galasa automation expire.

Create each new PAT as the `galasa-team` user (classic PATs) with the scopes below, then follow the steps for that token.

## GitHub Actions secrets (org level)

Set at https://github.com/organizations/galasa-dev/settings/secrets/actions

| Org secret | PAT scopes |
|---|---|
| `GALASA_TEAM_GITHUB_TOKEN` | `repo` |
| `WRITE_GITHUB_PACKAGES_TOKEN` | `write:packages` |
| `DELETE_GITHUB_PACKAGES_TOKEN` | `delete:packages`, `read:packages` |

For each one:

1. Regenerate the PAT with the scopes above.
2. Replace the value of the org secret with the same name.

## Webhook monitor (cicsk8s, `galasa-build`)

The PAT needs the `admin:org_hook` scope. A bad token makes the monitor crash-loop.

1. Regenerate the PAT.
2. Update Vault `galasa-secrets/webhook-monitor`, property `token`.
3. Force the ExternalSecret to sync:
   ```
   kubectl annotate externalsecret webhook-monitor -n galasa-build force-sync=$(date +%s) --overwrite
   ```
4. Check it synced (`STATUS` should be `SecretSynced` and `READY` `True`):
   ```
   kubectl get externalsecret webhook-monitor -n galasa-build
   ```
5. Restart the monitor so it picks up the new token:
   ```
   kubectl rollout restart deployment github-monitor -n galasa-build
   kubectl rollout status deployment github-monitor -n galasa-build
   ```
6. Check the logs show no authentication errors:
   ```
   kubectl logs deployment/github-monitor -n galasa-build --tail=50
   ```
