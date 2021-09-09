const github = require("@actions/github");
const { Octokit } = require("octokit");
const core = require("@actions/core");
const openpgp = require("openpgp");
const {sign} = require("openpgp");
module.exports = class PGP {
    privateKey
    publicKey
    passphrase
    pgpMessage
    constructor(publicKey, privateKey, passphrase) {
        this.privateKey = privateKey
        this.publicKey = publicKey
        this.passphrase = passphrase
    }
    async signDetached(data){
        const pgpMessage = await openpgp.createMessage({
            text: data
        })
        const detachedSignature = await openpgp.sign({
            message: pgpMessage, // CleartextMessage or Message object
            signingKeys: this.privateKey,
            detached: true
        });
        return { detachedSignature, pgpMessage }
    }

    async verifySignature(message, signature) {
        const signatureMessage = await openpgp.readSignature({
            armoredSignature: signature // parse detached signature
        });
        const verificationResult = await openpgp.verify({
            message: message, // Message object
            signature: signatureMessage,
            verificationKeys: this.publicKey
        });
        const { verified, keyID } = verificationResult.signatures[0];
        try {
            await verified; // throws on invalid signature
            core.info('Signed by key id ' + keyID.toHex());
            core.info('Signed by: ' + this.privateKey.users.map(user => user.userID.name));
            core.info('Email: ' + this.privateKey.users.map(user => user.userID.email));
        } catch (e) {
            core.error('Signature could not be verified: ' + e.message);
        }
        return verified
    }

}