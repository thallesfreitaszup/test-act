const github = require("@actions/github");
const { Octokit } = require("octokit");
const axios = require("axios");
module.exports = class Github {
    token
    actionsKit
    octokit
    repo
    owner
    constructor(token) {
        this.token = token
        this.owner = github.context.repo.owner
        this.repo = github.context.payload.repository.name
    }

    getActionsKit() {
        if (this.actionsKit == null) {
            this.actionsKit =  github.getOctokit(this.token)
        }
        return this.actionsKit;
    }

    getOctokit() {
        if (this.octokit == null) {
            this.octokit = new Octokit({ auth: this.token });
        }
        return this.octokit
    }
    async getLatestRelease() {

        const response  = await this.getActionsKit().request(`GET /repos/${this.owner}/${this.repo}/releases`)
        return response.data[0]
    }

    async getReleaseTgz(url) {
        const response = await axios.get(url)
        return response.data
    }
    async uploadReleaseAsset(data, release_id) {
        return await this.getOctokit().rest.repos.uploadReleaseAsset({
            owner: this.owner,
            repo: this.repo,
            release_id,
            name: 'pgp-signature.asc',
            data
        })
    }
}