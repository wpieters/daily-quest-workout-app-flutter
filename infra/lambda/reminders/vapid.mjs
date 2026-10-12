// VAPID keys are derived from a single P-256 private key that Terraform
// generates and stores in SSM. web-push wants both keys as base64url: the
// public key as the 65-byte uncompressed point, the private key as the
// 32-byte scalar. Both fall out of the JWK export.
import { GetParameterCommand, SSMClient } from '@aws-sdk/client-ssm';
import { createPrivateKey } from 'node:crypto';

export function vapidKeysFromPem(pem) {
  const jwk = createPrivateKey(pem).export({ format: 'jwk' });
  if (jwk.kty !== 'EC' || jwk.crv !== 'P-256') {
    throw new Error(`VAPID key must be EC P-256, got ${jwk.kty}/${jwk.crv}`);
  }
  const point = Buffer.concat([
    Buffer.from([0x04]),
    Buffer.from(jwk.x, 'base64url'),
    Buffer.from(jwk.y, 'base64url'),
  ]);
  return { publicKey: point.toString('base64url'), privateKey: jwk.d };
}

let cached;

/** Loads the keys from SSM once per container. */
export async function vapidKeys() {
  if (!cached) {
    const ssm = new SSMClient({});
    const { Parameter } = await ssm.send(
      new GetParameterCommand({
        Name: process.env.VAPID_PARAMETER_NAME,
        WithDecryption: true,
      }),
    );
    cached = vapidKeysFromPem(Parameter.Value);
  }
  return cached;
}
