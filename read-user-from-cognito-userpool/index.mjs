import { CognitoIdentityProviderClient, AdminGetUserCommand } from "@aws-sdk/client-cognito-identity-provider";

export const handler = async (event) => {
  const data = JSON.parse(event.body);
  const client = new CognitoIdentityProviderClient();
  const input = {
    UserPoolId: process.env.USER_POOL_ID,
    Username: data.username,
  };
  const command = new AdminGetUserCommand(input);
  try {
    const cognitoResponse = await client.send(command);
    const response = {
      statusCode: 200,
      body: JSON.stringify(cognitoResponse)
    };
    return response;
  }
  catch (error) {
    return {
      statusCode: 401,
      body: JSON.stringify({
        errorMessage: error.message,
        errorType: "UnauthorizedError"
      }),
      headers: {
        "Content-Type": "application/json"
      }
    };
  }
};
