const express = require('express')
const mongoose = require('mongoose')
const cors = require('cors')

// Zugangsdaten nie im Code: Die Verbindung kommt aus der Umgebung (.env, siehe .env.example)
try {
  process.loadEnvFile()
} catch {
  // keine .env-Datei, dann muss MONGODB_URI anders gesetzt sein
}

const mongoUri = process.env.MONGODB_URI
if (!mongoUri) {
  console.error('MONGODB_URI fehlt. Lege AstroBlasterAPI/.env nach dem Muster von .env.example an.')
  process.exit(1)
}

const app = express()
app.use(cors())
app.use(express.json())

mongoose.connect(mongoUri)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err))

const port = Number(process.env.PORT) || 3000
app.listen(port, () => {
  console.log(`API running on port ${port}`)
})

const scoreRoutes = require('./routes/scores')
app.use('/scores', scoreRoutes)
