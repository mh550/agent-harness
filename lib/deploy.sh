# shellcheck shell=bash
# Usage: source lib/deploy.sh; deploy_status <project dir> [<git ref>]   (hosts that build run branches unguarded: vercel|netlify)
#        deploy_guard <project dir>                                     (harness init: writes the guards, says what it did)
# Vercel and Netlify build a preview for every pushed branch; the driver pushes after every session (E0b, D-H33).
DEPLOY_MJS=$HARNESS_HOME/lib/deploy.mjs

# With <ref>, the files are read from that commit (Vercel reads the deployed commit's vercel.json). .vercel/ is
# gitignored, so it is looked for in the project checkout ($PROJECT_DIR) too. The deployments API is read-only.
deploy_status() {
  local d=$1 ref=${2:-} t f s dot=0 a=()
  t=$(mktemp -d)
  for f in vercel.json netlify.toml; do
    if [[ -n $ref ]]; then git -C "$d" show "$ref:$f" > "$t/$f" 2> /dev/null || rm -f "$t/$f"
    elif [[ -f $d/$f ]]; then cp "$d/$f" "$t/$f"; fi
  done
  [[ -d $d/.vercel || ( -n ${PROJECT_DIR:-} && -d $PROJECT_DIR/.vercel ) ]] && dot=1
  s=$(node "$DEPLOY_MJS" slug "$(git -C "$d" config --get remote.origin.url)") \
    && timeout 30 "${HARNESS_GH:-gh}" api "repos/$s/deployments?per_page=20" > "$t/api" 2> /dev/null || rm -f "$t/api"
  for f in vercel.json netlify.toml api; do [[ -f $t/$f ]] && a+=("$t/$f") || a+=(-); done
  node "$DEPLOY_MJS" status "${a[0]}" "${a[1]}" "$dot" "${a[2]}"
  rm -rf "$t"
}

deploy_guard() {
  local d=$1 hosts
  hosts=$(deploy_status "$d")
  if grep -qx vercel <<< "$hosts"; then
    case $(node "$DEPLOY_MJS" vercel-guard "$d/vercel.json") in
      added) echo "added the deploy guard to vercel.json (git.deploymentEnabled \"harness/**\": false): commit it to main" ;;
      by-hand) echo "vercel.json can't take the guard as it is (not a JSON object, or a true key matches harness/* branches: remove it or set it false): add  \"git\": { \"deploymentEnabled\": { \"harness/**\": false } }  by hand" ;;
    esac
  elif [[ -f $d/vercel.json ]]; then echo "keep    vercel.json (run branches don't deploy)"; fi
  if grep -qx netlify <<< "$hosts"; then
    case $(node "$DEPLOY_MJS" netlify-guard "$d/netlify.toml") in
      added) echo "added the deploy guard to netlify.toml ([build] ignore for harness/* refs): commit it to main" ;;
      own-ignore) echo "netlify.toml has its own ignore ([build], or a deploy-preview/branch-deploy context): add  case \\\"\$BRANCH\\\" in harness/*) exit 0;; esac;  to the front of its string by hand" ;;
      by-hand) echo "netlify.toml sets build without a [build] table: add  ignore = \"case \\\"\$BRANCH\\\" in harness/*) exit 0;; esac; exit 1\"  to it by hand" ;;
    esac
  elif [[ -f $d/netlify.toml ]]; then echo "keep    netlify.toml (run branches don't deploy)"; fi
  return 0
}
