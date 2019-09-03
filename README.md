# Persistent Stand Alone Cluster

## Redis Standalone Cluster 

Cloudformation description for The Redis stand alone stack.


Services using the instance:

Service       | Database
------------- | -------------
redis-shared-cluster  | 01  (Default database)


### How to connect to Redis from Lambda
Following is the example CloudFormation template sample to connect Redis:
 
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
## MySQL Stand Alone Cluster
