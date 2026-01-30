const express = require('express')
const ScoreEntry = require('../models/ScoreEntry')
const router = express.Router()

// CREATE — submit score
router.post('/', async (req, res) => {
  const score = await ScoreEntry.create(req.body)
  res.status(201).json(score)
})

// READ — arena highscores
router.get('/arena/:arenaId', async (req, res) => {
  const scores = await ScoreEntry.find({
    arenaId: req.params.arenaId
  })
    .sort({ score: -1 })
    .limit(50)

  res.json(scores)
})

// READ — global leaderboard
router.get('/global', async (_, res) => {
  const scores = await ScoreEntry.find()
    .sort({ score: -1 })
    .limit(100)

  res.json(scores)
})

module.exports = router
