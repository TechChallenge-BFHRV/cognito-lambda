import { CognitoIdentityProviderClient, AdminCreateUserCommand } from "@aws-sdk/client-cognito-identity-provider";

export const handler = async (event) => {
  const client = new CognitoIdentityProviderClient();
  const input = {
    
    UserPoolId: process.env.USER_POOL_ID,
    Username: event.email,
    UserAttributes: [
      {
        Name: "email",
        Value: event.email,
      },
      {
        Name: "custom:cpf",
        Value: event.cpf,
      },
    ],
    ValidationData: [ 
      {
        Name: "email",
        Value: "STRING_VALUE",
      },
    ],
    TemporaryPassword: "STRING_VALUE",
    ForceAliasCreation: true || false,
    MessageAction: "SUPPRESS",
    DesiredDeliveryMediums: [
      "EMAIL",
    ],
    ClientMetadata: { // ClientMetadataType
      "<keys>": "STRING_VALUE",
    },
  };
  const command = new AdminCreateUserCommand(input);
  const response = await client.send(command);
  return response;
};
