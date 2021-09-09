
const core = require("@actions/core");
const PGP = require("./pgp");
const Github = require('./github');
const openpgp = require("openpgp");
(async () => {
    try {
        core.info("Start reading input...")
        const token = core.getInput("token")
        const passphrase = core.getInput("passphrase")
        const publicKey = await openpgp.readKey({ armoredKey: core.getInput("public_key") });
        const privateKey =  await openpgp.decryptKey({
            privateKey: await openpgp.readPrivateKey({ armoredKey: core.getInput("private_key")  }),
            passphrase: passphrase
        })
        console.info("Finish reading input")
        const github = new Github(token);
        const pgp = new PGP(publicKey, privateKey, passphrase)
        const { tarball_url, id } = await github.getLatestRelease()
        console.info("Got release... ", {tarball_url, id})
        const tgzRelease = await github.getReleaseTgz(tarball_url)
        console.info("Signing release... ")
        const { detachedSignature, pgpMessage } = await pgp.signDetached(tgzRelease)
        console.info("Uploading signature... ")
        const result = await github.uploadReleaseAsset(detachedSignature, id)
        console.info("Uploaded signature asset: ", { url: result.data.url, name: result.data.name})
        const verified = pgp.verifySignature(pgpMessage, detachedSignature)
        if(!verified) {
            core.error(`Failed to verify signature`)
        }
    }catch( error) {
        const errorMessage = error.message || error.err || error
        core.error(`Error running action `, errorMessage)
        core.setFailed(`Error: ${errorMessage}`)
    }
})()