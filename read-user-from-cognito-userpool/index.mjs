import { CognitoIdentityProviderClient, AdminGetUserCommand } from "@aws-sdk/client-cognito-identity-provider";

export const handler = async (event) => {
  const client = new CognitoIdentityProviderClient();
  const input = {
    UserPoolId: process.env.USER_POOL_ID,
    Username: event.username,
  };
  const command = new AdminGetUserCommand(input);
  const response = await client.send(command);
  return response;
};
