// DynamoDB access for reminder subscriptions. One item per push subscription.
//
// Item shape:
//   id            sha256(endpoint), hex
//   endpoint      push service URL
//   keys          { p256dh, auth } from PushSubscription.toJSON()
//   timezone      IANA zone, e.g. "Europe/Dublin"
//   times         { morning, afternoon, evening } as "HH:MM" local, or null when off
//   completedDate "YYYY-MM-DD" (local) of the last day the quest was completed
//   lastSent      { morning, afternoon, evening } -> "YYYY-MM-DD" (local) last sent
//   updatedAt     ISO timestamp
//   ttl           epoch seconds; refreshed on every PUT so dead subscriptions expire
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DeleteCommand,
  DynamoDBDocumentClient,
  PutCommand,
  ScanCommand,
  UpdateCommand,
} from '@aws-sdk/lib-dynamodb';
import { createHash } from 'node:crypto';

const TABLE = process.env.TABLE_NAME;
const TTL_DAYS = Number(process.env.SUBSCRIPTION_TTL_DAYS ?? 60);

const doc = DynamoDBDocumentClient.from(new DynamoDBClient({}), {
  marshallOptions: { removeUndefinedValues: true },
});

export const idFor = (endpoint) =>
  createHash('sha256').update(endpoint).digest('hex');

export async function putSubscription({ endpoint, keys, timezone, times }) {
  const now = new Date();
  await doc.send(
    new PutCommand({
      TableName: TABLE,
      Item: {
        id: idFor(endpoint),
        endpoint,
        keys,
        timezone,
        times,
        updatedAt: now.toISOString(),
        ttl: Math.floor(now.getTime() / 1000) + TTL_DAYS * 86400,
      },
    }),
  );
}

export async function markCompleted(endpoint, date) {
  await doc.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { id: idFor(endpoint) },
      UpdateExpression: 'SET completedDate = :d',
      ConditionExpression: 'attribute_exists(id)',
      ExpressionAttributeValues: { ':d': date },
    }),
  );
}

export async function markSent(id, slot, date) {
  await doc.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { id },
      UpdateExpression: 'SET lastSent = if_not_exists(lastSent, :empty)',
      ExpressionAttributeValues: { ':empty': {} },
    }),
  );
  await doc.send(
    new UpdateCommand({
      TableName: TABLE,
      Key: { id },
      UpdateExpression: 'SET lastSent.#slot = :d',
      ExpressionAttributeNames: { '#slot': slot },
      ExpressionAttributeValues: { ':d': date },
    }),
  );
}

export async function deleteSubscription(id) {
  await doc.send(new DeleteCommand({ TableName: TABLE, Key: { id } }));
}

export async function* allSubscriptions() {
  let ExclusiveStartKey;
  do {
    const page = await doc.send(
      new ScanCommand({ TableName: TABLE, ExclusiveStartKey }),
    );
    for (const item of page.Items ?? []) yield item;
    ExclusiveStartKey = page.LastEvaluatedKey;
  } while (ExclusiveStartKey);
}
