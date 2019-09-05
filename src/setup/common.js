const { ENVIRONMENT, AWS_REGION } = process.env

const ssm = new (require('aws-sdk/clients/ssm'))({ region: AWS_REGION })
const kms = new (require('aws-sdk/clients/kms'))({ region: AWS_REGION })
const { createConnection } = require('mysql')

const getParameter = async (name) => {
  const params = { Name: name }
  const { Parameter } = await ssm.getParameter(params).promise()
  return Parameter.Value
}

const decrypt = async (encryptedValue) => {
  const params = { CiphertextBlob: Buffer.from(encryptedValue, 'base64') }
  console.log(JSON.stringify(params), 'common.decrypt')

  const { Plaintext } = await kms.decrypt(params).promise()
  return Plaintext.toString('utf-8')
}

const establishConnection = (connection) => {
  console.log('Establish connection', 'common.establishConnection')
  return new Promise((resolve, reject) => {
    connection.connect((error) => {
      if (error) {
        console.error('Error connecting to DB', error.message || JSON.stringify(error))
        return reject(`Could not connect to DB: ${error.code}`)
      }
      console.log('DB connected', 'common.establishConnection')
      return resolve()
    })
  })
}

const getDBConnection = async (host, database, user, password) => {
  const params = { host, user, password, database, timezone: 'Z' }
  console.log(params, 'common.getDBConnection')

  console.log(`Connecting to ${host}:3306/${database} as ${user}`, 'common.getDBConnection')
  const connection = createConnection(params)
  await establishConnection(connection)
  return connection
}

const query = (connection, sql) => {
  console.log(`Doing query with ${sql}`, 'common.query')
  return new Promise((resolve, reject) => {
    connection.query(sql, undefined, (error, results) => {
      console.error(`Done executing query, results: ${results}`, 'common.query')
      return error ? reject(error) : resolve(results)
    })
  })
}

module.exports = {
  getParameter,
  decrypt,
  establishConnection,
  getDBConnection,
  query
}
