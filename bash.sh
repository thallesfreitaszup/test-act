sudo apt install gnupg
echo $OWNER
echo $REPO
echo $PASSPHRASE
RESPONSE=$(curl "https://api.github.com/repos/$OWNER/$REPO/releases" | jq '.[0]')
TARBALL_URL=$(jq '.tarball_url' <<< "$RESPONSE"  | tr -d '"')
RELEASE_ID=$(jq '.id' <<< "$RESPONSE"  | tr -d '"')
TAG_NAME=$(jq '.tag_name' <<< "$RESPONSE"  | tr -d '"')
curl -L "$TARBALL_URL" > "release.tgz"
echo -e "$PRIVATE_KEY" > private.pgp
gpg --pinentry-mode loopback --passphrase $PASSPHRASE --batch --quiet --yes --import private.pgp

gpg --armor --pinentry-mode loopback --passphrase $PASSPHRASE --batch --quiet --yes --detach-sign release.tgz
ASSET_NAME="${REPO}_${TAG_NAME}"
ASSETS_UPLOAD_URL="https://uploads.github.com/repos/$OWNER/$REPO/releases/${RELEASE_ID}/assets?name=$ASSET_NAME.tgz.asc"
echo "curl $ASSETS_UPLOAD_URL -H 'accept: application/vnd.github.v3+json' \
       -H 'Content-Type: application/json' \
       -H  'authorization: token $TOKEN' \
       --data-binary @release.tgz.asc"

curl "$ASSETS_UPLOAD_URL" -H "accept: application/vnd.github.v3+json" \
 -H "Content-Type: application/json" \
 -H  "authorization: token $TOKEN" \
 --data-binary @release.tgz.asc

echo "curl $ASSETS_UPLOAD_URL -H 'accept: application/vnd.github.v3+json' \
       -H 'Content-Type: application/json' \
       -H  'authorization: token $TOKEN' \
       --data-binary @release.tgz"

ASSETS_UPLOAD_URL="https://uploads.github.com/repos/$OWNER/$REPO/releases/${RELEASE_ID}/assets?name=$ASSET_NAME.tgz"
curl "$ASSETS_UPLOAD_URL" -H "accept: application/vnd.github.v3+json" \
 -H "Content-Type: application/json" \
 -H  "authorization: token $TOKEN" \
 --data-binary @release.tgz
