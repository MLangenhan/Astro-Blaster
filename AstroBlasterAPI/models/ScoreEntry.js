const mongoose = require('mongoose')

// score is dependant on difficulty since lower difficulty makes it easier to reach higher scores
const ScoreEntrySchema = new mongoose.Schema({
  playerName: { type: String, required: true },
  arenaId: { type: String, required: true },
  arenaName: { type: String, required: true },
  score: { type: Number, required: true },
  maxDifficulty: { type: Number, required: true },
  createdAt: { type: Date, default: Date.now }
})

module.exports = mongoose.model('ScoreEntry', ScoreEntrySchema)
