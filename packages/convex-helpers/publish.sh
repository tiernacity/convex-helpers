#! /bin/bash

set -e

npm run clean
npm run build

cat <<EOF
Test it:
  - Add some example usage to the outer convex-helpers repo.
  - Install from another project via \`npm link\`.
  - Run \`npm pack\` and install it elsewhere from the .tgz file.
EOF
echo "Current version:"
grep '"version":' package.json || {
  echo "No version number found in package.json"
  exit 1
}
read -r -p "Enter the new version number: " version

if [ -n "$version" ]; then
  sed -i '' "s/\"version\": \".*\"/\"version\": \"$version\"/g" package.json
else
  version=$(grep '"version":' package.json | sed 's/.*"\(.*\)",.*/\1/')
fi
npm i

npm publish --dry-run
echo "^^^ DRY RUN ^^^"
read -r -p "Publish $version to npm? (y/n): " publish
if [ "$publish" = "y" ]; then
  git add package.json package-lock.json

  pushd "../.." >/dev/null
  npm i ./packages/convex-helpers
  git add package.json package-lock.json
  popd >/dev/null

  # If there's nothing to commit, continue
  git commit -m "npm $version" || true
  if (echo "$version" | grep alpha >/dev/null); then
    npm publish --tag alpha
  else
    npm publish
  fi
  git tag "npm/$version"
  git push "npm/$version"
fi
