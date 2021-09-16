sudo apt install gnupg
RESPONSE=$(curl  "https://api.github.com/repos/$OWNER/$REPO/releases" | jq '.[0]')
RELEASE_ID=$(jq '.id' <<< "$RESPONSE"  | tr -d '"')
TAG_NAME=$(jq '.tag_name' <<< "$RESPONSE"  | tr -d '"')

TARBALL_URL="https://github.com/$OWNER/$REPO/archive/refs/tags/$TAG_NAME.tar.gz"
ZIP_URL="https://github.com/$OWNER/$REPO/archive/refs/tags/$TAG_NAME.zip"

REPO_TAG="${REPO}-${TAG_NAME}"

echo -e $PRIVATE_KEY > private.key
curl -fL "$TARBALL_URL" > "$REPO_TAG.tar.gz"
curl -fL "$ZIP_URL" > "$REPO_TAG.zip"

gpg --pinentry-mode loopback --passphrase $PASSPHRASE --batch --quiet --yes --import private.key
gpg --armor --pinentry-mode loopback --passphrase $PASSPHRASE --batch --quiet --yes --detach-sign "$REPO_TAG.tar.gz"
gpg --armor --pinentry-mode loopback --passphrase $PASSPHRASE --batch --quiet --yes --detach-sign "$REPO_TAG.zip"

ASSETS_UPLOAD_URL="https://uploads.github.com/repos/$OWNER/$REPO/releases/$RELEASE_ID/assets?name=$REPO_TAG.tar.gz.asc"
curl "$ASSETS_UPLOAD_URL" -H "accept: application/vnd.github.v3+json" \
 -H "Content-Type: application/json" \
 -H  "authorization: token  $TOKEN" \
 --data-binary @"$REPO_TAG.tar.gz.asc"

ASSETS_UPLOAD_URL="https://uploads.github.com/repos/$OWNER/$REPO/releases/$RELEASE_ID/assets?name=$REPO_TAG.zip.asc"
curl "$ASSETS_UPLOAD_URL" -H "accept: application/vnd.github.v3+json" \
 -H "Content-Type: application/json" \
 -H  "authorization: token  $TOKEN" \
 --data-binary @"$REPO_TAG.zip.asc"
