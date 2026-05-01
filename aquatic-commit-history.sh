#!/usr/bin/env zsh
set -euo pipefail

###############################################################################
# Script Name : aquatic-commit-history.sh
# Description : Visualises commit history by tag.
#
# Author      : Varun Chawla
# Created On  : October 19, 2025
# Last Updated: May 1, 2026
# Usage       : aquatic commit-history [--tags <n>] [--commits <n>] [--branch <b>]
# Requirements: gh (GitHub CLI), jq
###############################################################################

NUM_TAGS="2"
COMMITS="10"
BASE_BRANCH="develop"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tags) NUM_TAGS="$2"; shift 2 ;;
        --commits) COMMITS="$2"; shift 2 ;;
        --branch|-b) BASE_BRANCH="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: aquatic commit-history [--tags <n>] [--commits <n>] [--branch <b>]"
            echo ""
            echo "Options:"
            echo "  --tags <n>      Number of tags to display (default: 2)"
            echo "  --commits <n>   Commits per tag (default: 10)"
            echo "  --branch <b>    Base branch (default: develop)"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) shift ;;
    esac
done

# Lists latest tags with recent commits; aligned columns; bold headers; colored verdicts; local time with "Nov." month style.

OWNER="owner"
REPO="repo"

# ANSI styles
BOLD=$'\033[1m'; RESET=$'\033[0m'
RED=$'\033[31m'; GREEN=$'\033[32m'; FGRESET=$'\033[39m'

# Column widths for commit rows
INDENT="  "               # header indent
COMMIT_PREFIX="        "  # extra left indent for commit rows to show hierarchy
W1=9                      # first column width used by commit rows before the first bar (SHA-7 area)
W2=26                     # "Nov. 05, 2025 04:07 AM IST"
W3=22                     # author
W4=72                     # subject

# Latest commit on base branch
BASE_SHA=$(gh api "repos/$OWNER/$REPO/branches/$BASE_BRANCH" --jq '.commit.sha')

# Fetch top tags; include author for symmetry
TAGS_DATA=$(
  gh api graphql \
    -f owner="$OWNER" -f name="$REPO" \
    -f query='
      query($owner:String!, $name:String!){
        repository(owner:$owner, name:$name){
          refs(refPrefix:"refs/tags/", first:'"$NUM_TAGS"',
                orderBy:{field:TAG_COMMIT_DATE, direction:DESC}){
            nodes{
              name
              target{
                ... on Commit {
                  oid
                  history(first:'"$COMMITS"'){
                    nodes{ abbreviatedOid committedDate messageHeadline author { name user { login } } }
                  }
                }
                ... on Tag {
                  target{
                    ... on Commit {
                      oid
                      history(first:'"$COMMITS"'){
                        nodes{ abbreviatedOid committedDate messageHeadline author { name user { login } } }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }'
)


# Latest tag tip; and whether base is ahead of latest tag
LATEST_TAG_OID=$(jq -r '.data.repository.refs.nodes[0] | (.target.oid // .target.target.oid)' <<<"$TAGS_DATA")
AHEAD_BY=$(gh api "repos/$OWNER/$REPO/compare/$LATEST_TAG_OID...$BASE_SHA" --jq '.ahead_by' 2>/dev/null || echo 0)

# Determine shared first-column width C1 so header bars and commit-row bars align
MAX_NAME_LEN=$(
  { jq -r '.data.repository.refs.nodes[].name' <<<"$TAGS_DATA"; echo "$BASE_BRANCH"; } \
  | awk '{print length($0)}' | sort -nr | head -n1
)
[ -z "$MAX_NAME_LEN" ] && MAX_NAME_LEN=0
C1=$(( W1 > MAX_NAME_LEN ? W1 : MAX_NAME_LEN ))

# jq time formatter; local tz; "Nov. 05, 2025 04:07 AM IST"
JQ_TIME_FN='
  def to_local_abbrev:
    (strptime("%Y-%m-%dT%H:%M:%SZ") | mktime | localtime) as $t
    | ($t | strftime("%b")) as $m
    | ($t | strftime("%d, %Y %I:%M %p %Z")) as $rest
    | ($m + ". " + $rest);
'

# Format helpers
fmt4() { 
  awk -v IND="$INDENT" -v PFX="$COMMIT_PREFIX" -v PFXL="${#COMMIT_PREFIX}" \
      -v W1="$C1" -v W2="$W2" -v W3="$W3" -v W4="$W4" 'BEGIN{FS="\t"}
    function clip(s,w){ gsub(/[[:space:]]+$/,"",s); return (length(s)>w ? substr(s,1,w-1)"…" : s) }
    function pad(s,w){ return sprintf("%-*s", w, s) }
    {
      w1e = W1 - PFXL; if (w1e < 1) w1e = 1;
      printf "%s%s%s | %s | %s | %s\n",
        IND, PFX, pad(clip($1,w1e),w1e),
        pad(clip($2,W2),W2), pad(clip($3,W3),W3), pad(clip($4,W4),W4)
    }'
}

header_bold() { 
  local name="$1" right="$2"
  if [ -n "$right" ]; then
    printf "%s%s%-*s | %s%s\n" "$INDENT" "$BOLD" "$C1" "$name" "$right" "$RESET"
  else
    printf "%s%s%-*s |%s\n" "$INDENT" "$BOLD" "$C1" "$name" "$RESET"
  fi
}

if [ "$AHEAD_BY" -eq 0 ]; then
  base_right="${GREEN}NO NEW${FGRESET} commit(s)"
else
  base_right="${RED}AHEAD${FGRESET} of the latest tag by the following commit(s)"
fi
header_bold "$BASE_BRANCH" "$base_right"

if [ "$AHEAD_BY" -ne 0 ]; then
  gh api "repos/$OWNER/$REPO/compare/$LATEST_TAG_OID...$BASE_SHA" \
    | jq -r "$JQ_TIME_FN
        .commits
        | reverse
        | .[]
        | [
            .sha[0:7],
            (.commit.committer.date | to_local_abbrev),
            (.commit.author.name // .author.login // \"Unknown\"),
            (.commit.message | split(\"\n\")[0])
          ] | @tsv" \
    | fmt4
fi

jq -c --argjson nt "$NUM_TAGS" --argjson nc "$COMMITS" '
  .data.repository.refs.nodes[:$nt]
  | map({
      name,
      oid: (.target.oid // .target.target.oid),
      commits: ((.target.history.nodes // .target.target.history.nodes // [])[:$nc])
    })
  | .[]' <<<"$TAGS_DATA" \
| {
  i=0
  while IFS= read -r item; do
    i=$((i+1)); num=$(printf "%02d" "$i")
    name=$(jq -r '.name' <<<"$item")

    if [ "$i" -eq 1 ]; then
      if [ "$AHEAD_BY" -eq 0 ]; then
        verdict="${GREEN}INCLUDES${FGRESET} the latest commit(s) from $BASE_BRANCH"
      else
        verdict="${RED}DOES NOT${FGRESET} include the latest commit(s) from $BASE_BRANCH"
      fi
      header_bold "$name" "$num | Latest Tag | $verdict"
    else
      header_bold "$name" "$num"
    fi

    jq -r "$JQ_TIME_FN
      .commits[]
      | [
          .abbreviatedOid,
          (.committedDate | to_local_abbrev),
          (.author.name // .author.user.login // \"Unknown\"),
          (.messageHeadline // \"\")
        ] | @tsv" <<<"$item" \
    | fmt4
  done
}
