const { DB_HOST, DB_USER, DB_NAME } = process.env
const { getParameter, decrypt, getDBConnection, query } = require('./common')

exports.handler = async (event) => {
  console.log(JSON.stringify(event), 'handler')

  const { type, dbName } = event

  const encryptedValue = await getParameter('/config/shared-db-cluster/mysql/master-password')
  const decryptedValue = await decrypt(encryptedValue)
  const connection = await getDBConnection(DB_HOST, DB_NAME, DB_USER, decryptedValue)

  if (type === 'createdb') {
    await query(connection, `CREATE DATABASE ${dbName};`)
    return { message: `Database ${dbName} successfully created` }
  }

  await query(connection, 'SELECT now();')
  return { message: 'Query successfully executed' }
}
