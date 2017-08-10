const Azure = require('azure');
const MsRest = require('ms-rest-azure');

// log into azure
MsRest.loginWithUsernamePassword(process.env.AZURE_USER, process.env.AZURE_PASS, (err, credentials) => {
  if (err) throw err;

  let storageClient = Azure.createARMStorageManagementClient(credentials, 'subscription-id');

  // ..use the client instance to manage service resources.
});