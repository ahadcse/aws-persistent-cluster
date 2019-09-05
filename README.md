# Persistent Stand Alone Cluster

## Redis Standalone Cluster 

Services using the instance:

Service       | Database
------------- | -------------
redis-shared-cluster  | 01  (Default database)

### How to connect to Redis from Lambda
Following is the example CloudFormation template sample to connect to Redis:
 
```yaml
Globals:
  Function:
    Runtime: nodejs8.10
    Timeout: 300
    Handler: index.handler
    MemorySize: 1024
    Environment:
      Variables:
        ENVIRONMENT: !Ref Environment
        REDIS_HOST:
          Fn::ImportValue:  RedisElasticacheEndpoint # From redis.yaml
    VpcConfig:
      SecurityGroupIds:
        - Fn::ImportValue: RedisElasticacheSecurityGroup # From redis.yaml
      SubnetIds:
        Fn::FindInMap: [ !Ref Environment, vpc, subnetIds ]
```
VPC and subnetIds can be found in redis.yaml. From the example we can see REDIS_HOST that can be used when creating client.
Following is the example for creating a Redis client:

```javascript
const { REDIS_HOST } = process.env
const Redis = require('ioredis')
const redisClient = new Redis({
  port: 6379,
  host: REDIS_HOST
})
```
And the package.json is:
```json
{
  "dependencies": {
    "ioredis": "^4.9.3"
  },
  "devDependencies": {}
}
```
Unless stated otherwise the connection will be to default database

## MySQL Standalone Cluster

A shared serverless DB (MySQL) cluster.

### How to connect to MySQL from Lmabda

Following is the example CloudFormation template sample to connect to MySQL:

```yaml
Globals:
  Function:
    Runtime: nodejs8.10
    Handler: index.handler
    Timeout: 180
    MemorySize: 640
    Environment:
      Variables:
        ENVIRONMENT: !Ref Environment
        DB_HOST:
          Fn::ImportValue: DbClusterUrl  # From mysql.yaml
        DB_NAME: 'testdb'
        DB_USER: 'user_name'
    VpcConfig:
      SecurityGroupIds:
        - Fn::ImportValue: DbSecurityGroupId  # From vpc.yaml
      SubnetIds:
        Fn::FindInMap: [ !Ref Environment, vpc, subnetIds ]  # From mysql.yaml
```
VPC and subnetIds can be found in mysql.yaml. From the example we can see DB_HOST, DB_USER, DB_NAME that can be used when creating client.
Following is the example of creating a client:

```typescript
import {
  Connection,
  createConnection
} from 'mysql'

export class DBClient {
  private connection: Connection;

  constructor(password: string) {
    this.connection = createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password,
      database: process.env.DB_NAME,
      timezone: 'Z'
    })
  }

  public async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.connection.connect((error) => {
        if (error) {
            console.error('Error connecting to DB', { error: error.message || JSON.stringify(error) });
            return reject(`Could not connect to DB: ${ error.code }`)
        }
        console.log('DB connected');
        return resolve()
      })
    })
  }

  public async disconnect() {
    return this.connection.destroy()
  }

  private async _query(query: string, params: any): Promise<any> {
    return new Promise((resolve, reject) => {
      this.connection.query(query, params, (error, results) => {
        return error ? reject(error) : resolve(results)
      })
    })
  }
}
```

And the package.json is:
```json
{
  "dependencies": {
    "mysql": "^2.16.0"
  },
  "devDependencies": {
    "aws-sdk": "^2.401.0",
    "@types/node": "^11.9.4",
    "@types/mysql": "^2.15.5",
    "typescript": "^3.3.1"
  }
}
```
