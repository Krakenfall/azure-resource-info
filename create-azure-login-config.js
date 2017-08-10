// Parameters: <1-AzureUser> <2-AzurePasskey> <3-SubscriptionId>
const fs = require('fs');

function config(user, pass, subId) {
    this.user = user;
    this.passkey = pass;
    this.subscriptionId;
}

const create = new config(process.argv[2], process.argv[3], process.argv[4]);

// azure-login.config is in .git ignore
fs.writeFileSync(azure-login.config, JSON.stringify(create, 0, 2));