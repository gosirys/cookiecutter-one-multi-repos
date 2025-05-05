# {{cookiecutter.project_slug}}

> **Modular Repo Starter** — scaffold a repo that pulls in **your** chosen Git submodules and keeps them up to date automatically.

---

## Rationale

When you manage a project that depends on a collection of independent Git repositories, keeping everything wired together and up to date can become tedious:

- You don’t want to manually `git submodule add` every new dependency.  
- You want a single, uniform place to list your submodules.  
- You want daily automation to pull upstream changes and commit them back.

This **Cookiecutter** template solves all three:

1. **Interactive setup** — choose your submodules at project creation time.  
2. **One-file list** (`submodules.txt`) — edit this list to add/remove dependencies.  
3. **Built-in GitHub Action** — automatically fetch the latest commits of each submodule on your schedule.

---

## Purpose

- **Standardize** how you manage many sub-repos in one “monorepo.”  
- **Simplify** onboarding: teammates or CI systems only run one script.  
- **Automate** daily updates without writing your own workflow from scratch.

---

## Public vs Private Repositories

- **Public repos**: GitHub’s default `GITHUB_TOKEN` provided to Actions is sufficient.  
- **Private repos**: you must supply a PAT (personal access token) with at least `repo` scope:
  1. Upgrade to GitHub Pro (or appropriate plan) if your account requires it.  
  2. In **Settings → Security → Secrets and variables → Actions**, create a repository secret named (for example) `CUSTOM_PAT`.  
  3. In **Settings → Actions → General → Workflow permissions**, ensure “Allow GitHub Actions to create and approve pull requests” is enabled, and under “Access” set  
     _“Allow actions from”_ → _“Reposit- ries you own”_ (or “Selected organizations”) so your private submodules are accessible.

---

## GitHub Token & Secrets

- **`GITHUB_TOKEN`** is automatically available in public repos; no setup needed.  
- **`CUSTOM_PAT`** (or your chosen name) must be added as a _repository secret_ in each repo that uses private submodules.  
- The Actions workflow uses `${{ secrets.CUSTOM_PAT }}` as the checkout token.

---

## How It Works

1. **Generate your project**  
   ```bash
   pip install cookiecutter
   cookiecutter https://github.com/your-org/cookiecutter-modular-repo
   ```
   You’ll be prompted for:
   - **project_slug** — your new folder/repo name  
   - **submodules** — an initial JSON list of URLs (you can edit later)

2. **List your submodules**  
   ```bash
   cd {{cookiecutter.project_slug}}
   cp submodules.txt.example submodules.txt
   # Edit submodules.txt, listing each repo URL you want, one per line
   ```

3. **Bootstrap**  
   ```bash
   chmod +x scripts/init-submodules.sh
   scripts/init-submodules.sh
   git add modules/ submodules.txt
   git commit -m "chore: add initial submodules"
   git push -u origin main
   ```

4. **Daily updates**  
   A workflow file at `.github/workflows/update-submodules.yml` runs on your schedule and will:
   - Checkout your repo **with** submodules  
   - Pull latest commits in each submodule  
   - Commit and push updated pointers back to your `main` branch

---

## GitHub Actions

**Workflow file:** `.github/workflows/update-submodules.yml`

```yaml
name: Pull Submodules & Repackage

on:
  schedule:
    - cron: '58 18 * * *'    # adjust to your preferred UTC time
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo w/ submodules
        uses: actions/checkout@v3
        with:
          submodules: recursive
          token: ${{ secrets.CUSTOM_PAT || secrets.GITHUB_TOKEN }}

      - name: Configure Git
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"

      - name: Pull main repo updates
        run: git pull origin $(git branch --show-current)

      - name: Update submodules
        run: |
          git submodule update --init --recursive --depth=1
          git submodule foreach --recursive '
            git fetch origin \
            && git reset --hard origin/$(git rev-parse --abbrev-ref HEAD) \
            || echo "Failed to reset submodule"'

      - name: Commit changes in submodules
        run: |
          git submodule foreach --recursive '
            if [ -n "$(git status --porcelain)" ]; then
              git add -A
              git commit -m "chore: auto-commit submodule changes in $(basename $PWD)"
              git push --force-with-lease || echo "Push failed in submodule $(basename $PWD)"
            else
              echo "No changes in submodule $(basename $PWD)"
            fi
          '

      - name: Commit & push submodule pointer updates
        run: |
          if ! git diff --quiet || ! git diff --staged --quiet; then
            git add .
            git commit -m "chore: update submodule pointers"
            git push --force-with-lease
          else
            echo "No submodule pointer updates to commit."
          fi
```

> **Note:**  
> - Uses either your private token (`CUSTOM_PAT`) or fallback to `GITHUB_TOKEN`.  
> - To support private submodules, ensure your PAT is configured as a secret as described above.

---

## Customization

- **Change schedule:** edit the `cron:` line in  
  `.github/workflows/update-submodules.yml`.  
- **Add/remove submodules:** edit `submodules.txt` and rerun:  
  ```bash
  scripts/init-submodules.sh
  ```
- **Extend CI:** add more steps (build, test) after the submodule update step.

---

## Summary

1. **Cookiecutter** → interactive scaffolding  
2. **scripts/init-submodules.sh** → single-command add/remove  
3. **update-submodules.yml** → daily GitHub Actions automation  

Enjoy a modular, self-maintaining monorepo without the manual overhead!  
