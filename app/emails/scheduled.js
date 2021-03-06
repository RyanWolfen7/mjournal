'use strict'

const dailySummary = require('./daily-summary')
const moment = require('moment')

function delay () {
  const now = moment.utc()
  const next = now.clone().add(1, 'day').startOf('day')
  // for debugging, this runs every 20s
  // next = now.clone().add(20, "seconds")
  return next.diff(now)
}

function run () {
  setTimeout(function () {
    dailySummary(run)
  }, delay())
}

exports.run = run
