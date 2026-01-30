const express = require('express')
const mongoose = require('mongoose')
const cors = require('cors')

const app = express()
app.use(cors())
app.use(express.json())

mongoose.connect(
  'mongodb+srv://bymotrixzz_db_user:K5g11mKYltaZkEvf@ccluster0.shxhswg.mongodb.net/?appName=Cluster0')
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err))

mongoose.connection.once('open', () => {
  console.log('MongoDB connected')
})

app.listen(3000, () => {
  console.log('API running on port 3000')
})

const scoreRoutes = require('./routes/scores')
app.use('/scores', scoreRoutes)