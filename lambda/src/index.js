const { Route53 } = require('aws-sdk');

const route53 = new Route53();

// Build API Gateway response.
//
const createResponse = ({statusCode, body}) => {
  return {
    statusCode,
    headers: {},
    isBase64Encoded: false,
    body: JSON.stringify(body)
  };
};

// Check if authenticated via Basic authentication.
//
const isAuthenticated = (headers) => {
  if (!headers.Authorization) return false;

  const credentials = Buffer.from(headers.Authorization.split(' ')[1], 'base64').toString();

  return credentials === process.env.CREDENTIALS;
};

// Get source IP from 'X-Forwarded-For' header
//
const sourceIp = (headers) => {
  const ips = headers['X-Forwarded-For'].split(/[,\s]+/);
  return ips.pop();
};

// Update route53 record.
//
const changeRecord = (ip) => {
  const params = {
    ChangeBatch: {
      Changes: [
        {
          Action: 'UPSERT',
          ResourceRecordSet: {
            Name: process.env.DOMAIN_NAME,
            Type: 'A',
            TTL: 60,
            ResourceRecords: [
              { Value: ip }
            ]
          }
        }
      ]
    },
    HostedZoneId: process.env.ZONE_ID
  };

  return route53.changeResourceRecordSets(params).promise();
};

// Lambda handler.
//
exports.handler = async (event) => {
  const { headers } = event;
  const ip = sourceIp(headers);

  if (!isAuthenticated(headers)) {
    return createResponse({ statusCode: 403, body: { 'message': 'Not authorized' } });
  }
  if (!ip) {
    return createResponse({ statusCode: 500, body: { 'message': 'Missing X-Forwarded-For HTTP header' } });
  }

  response = await changeRecord(ip);
  console.log(JSON.stringify(response));

  return createResponse({ statusCode: 200, body: { 'message': `Sucessfully updated DNS record '${process.env.DOMAIN_NAME}' to '${ip}'` } });
};
