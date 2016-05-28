# Description:
#   Finder command for Hubot which pulls from the Yelp API.
#   Can only search in Detroit right now.
#
# Dependencies:
#   yelp
#
# Configuration:
#   None
#
# Commands:
#   "hubot find me..."
#   e.g. —
#     hubot find me a quick lunch
#     hubot find me dinner
#     hubot find me breakfast
#     hubot find me a mechanic
#
# Author:
#   yramocan

# Javascript client for Yelp's API (v2.0)
# Copyright (c) 2012 Olivier Lalonde olalonde@gmail.com
# https://github.com/olalonde/node-yelp
Yelp = require 'yelp'

yelp = new Yelp {
  consumer_key: process.env.YELP_CONSUMER_KEY,
  consumer_secret: process.env.YELP_CONSUMER_SECRET,
  token: process.env.YELP_ACCESS_TOKEN,
  token_secret: process.env.YELP_ACCESS_TOKEN_SECRET
}

module.exports = (robot) ->
  robot.respond /find me a?\s?(.+)/i, (msg) ->
    args = msg.message.text.split " "
    terms = msg.match[1]

    msg.send "Finding " + terms + " in the Detroit area..."

    yelp.search { term: terms, location: 'Detroit' }
    .then (data) ->
      msg.send "— " + result.name + " (" + result.rating + " stars)" for result in data.businesses
    .catch (err) ->
      msg.send "There was an error locating your search results. Blame @nate-west-party-of-one."
