# Description:
#   Team Roles
#
# Dependencies:
#   underscore
#
# Configuration:
#   None
#
# Commands:
#   hubot roles - Show assigned roles
#   hubot roles list - List available roles
#   hubot roles add <roles> - Add role(s)
#   hubot roles rm <roles> - Remove role(s)
#   hubot roles set <roles> - Set all roles at once
#   hubot roles people - List people
#   hubot roles people add <names> - Add people
#   hubot roles people rm <names>- Remove people
#   hubot roles people set <people> - Set all people at once
#   hubot roles shuffle - Randomly assign people to roles
#   hubot roles android - List the people in android
#   hubot roles android add <names> - Add people to android
#   hubot roles android rm <names> - Remove people from android
#   hubot roles android set <roles> - Set all android roles at once
#   hubot roles ios - List the people in ios
#   hubot roles ios add <names> - Add people to iOS
#   hubot roles ios rm <names> - Remove people from iOS
#   hubot roles ios set <roles> - Set all ios roles at once
#   hubot roles androidRole - List the android roles
#   hubot roles androidRole add <names> - Add roles to android roles
#   hubot roles androidRole rm <names> - Remove roles from android roles
#   hubot roles iosRole - List ios roles
#   hubot roles iosRole add <names> - Add roles to iOS
#   hubot roles iosRole rm <names> - Remove roles from iOS
#   hubot roles legend set <url> - sets the legend for the room
#   hubot roles legend - displays the legend
#   hubot roles strategy set <strategy> - sets the shuffle algorithm
#   hubot roles strategy - returns the shuffle algorith
#   hubot roles strategies - lists the shuffle algorithms
#
# Notes:
#   defaults to random shuffle
#
# Author:
#   nwest

_ = require 'underscore'

getRoom = (msg) ->
  msg.envelope.room or msg.envelope.user.id #just in case someone wants to play in their own private world

rolesKey = (msg) ->
  "roles-#{getRoom(msg)}"

peopleKey = (msg) ->
  "roles-people-#{getRoom(msg)}"

androidKey = (msg) ->
  "roles-android-#{getRoom(msg)}"

iOSKey = (msg) ->
  "roles-ios-#{getRoom(msg)}"

currentRolesKey = (msg) ->
  "roles-current-#{getRoom(msg)}"

androidRoleKey = (msg) ->
  "roles-androidRole-#{getRoom(msg)}"

iosRoleKey = (msg) ->
  "roles-iosRole-#{getRoom(msg)}"
  
legendKey = (msg) ->
  "roles-legend-#{getRoom(msg)}"
  
strategyKey = (msg) ->
  "roles-strategy-#{getRoom(msg)}"

prettyObjectString = (object) ->
  _.map(object, (key, value) -> "#{value}: #{key}").join("\n")

quietObjectString = (object) ->
  values = _.map(_.values(object), stripTag)
  cleanedObject = _.object(_.keys(object), values)
  prettyObjectString(cleanedObject)

prettyArrayString = (array) ->
  newArray = _.map(array, stripTag)
  newArray.join(", ")

stripTag = (string) ->
  if string.charAt(0) == '@'
    string = string.slice(1)
  string

parseCommaSeparatedString = (string) ->
  _.map(string.split(/\s*,\s*/), (s) ->
    s.trim())

removeObjects = (source, itemsToRemove) ->
  _.reject(source, (item) ->
    itemsToRemove.indexOf(item) > -1)

strategyForRoom = (msg) ->
  strategy = msg.robot.brain.get strategyKey(msg)
  if !strategy || !(strategy in strategies)
    strategy = strategies[0]
  strategy

strategies = ["random", "roundRobin"]
global = @

@random = (msg) ->
  brain = msg.robot.brain
  roles = brain.get rolesKey(msg)
  people = brain.get peopleKey(msg)
  android = brain.get androidKey(msg)
  androidRole = brain.get androidRoleKey(msg)
  ios = brain.get iOSKey(msg)
  iosRole = brain.get iosRoleKey(msg)

  newRoles = _.object(roles, _.sample(people, roles.length))

  if androidRole
    androidAssignment = _.object(androidRole, _.sample(android, androidRole.length))
    _.extend(newRoles, androidAssignment)

  if iosRole
    iosAssignment = _.object(iosRole, _.sample(ios, iosRole.length))
    _.extend(newRoles, iosAssignment)

  brain.set(currentRolesKey(msg), newRoles)
  newRoles

nextPerson = (currentPerson, people) ->
  index = people.indexOf(currentPerson)
  people[(index+1) % people.length]

@roundRobin = (msg) ->
  brain = msg.robot.brain
  roles = brain.get rolesKey(msg)
  people = brain.get peopleKey(msg)
  android = brain.get androidKey(msg)
  androidRole = brain.get androidRoleKey(msg)
  ios = brain.get iOSKey(msg)
  iosRole = brain.get iosRoleKey(msg)
  
  currentRoles = brain.get(currentRolesKey(msg))
  if !currentRoles # we just started let's make it random
    newRoles = @random(msg)
  else
    newRoles = currentRoles
    for role in _.keys(newRoles)
      roster = people
      if androidRole && role in androidRole
        roster = android
      else if iosRole && role in iosRole
        roster = ios
        
      newRoles[role] = nextPerson(newRoles[role], roster)
  
  brain.set(currentRolesKey(msg), newRoles)
  newRoles

module.exports = (robot) ->
  robot.respond /roles$/i, (msg) ->
    legendUrl = msg.robot.brain.get(legendKey(msg))
    if legendUrl
      msg.send "legend: #{legendUrl}"
    
    currentRoles = robot.brain.get(currentRolesKey(msg))
    msg.send quietObjectString(currentRoles)

  robot.respond /roles list/i, (msg) ->
    msg.send stringWithKey(rolesKey(msg))

  robot.respond /roles add (.*)/i, (msg) ->
    key = rolesKey(msg)
    addObjectsToKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles rm (.*)/i, (msg) ->
    key = rolesKey(msg)
    removeObjectsFromKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles set (.*)/i, (msg) ->
    key = rolesKey(msg)
    robot.brain.set(key, parseCommaSeparatedString(msg.match[1]))
    msg.send stringWithKey(key)

  robot.respond /roles shuffle/i, (msg) ->
    roles = msg.robot.brain.get rolesKey(msg)
    people = msg.robot.brain.get peopleKey(msg)
    
    if roles.length > people.length
      msg.send "Not enough people to cover all roles"
    else
      newRoles = global[strategyForRoom(msg)](msg)
      msg.send prettyObjectString(newRoles)

  robot.respond /roles people$/i, (msg) ->
    msg.send stringWithKey(peopleKey(msg))

  robot.respond /roles people add (.*)/i, (msg) ->
    key = peopleKey(msg)
    addObjectsToKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles people rm (.*)/i, (msg) ->
    key = peopleKey(msg)
    removeObjectsFromKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles people set (.*)/i, (msg) ->
    key = peopleKey(msg)
    robot.brain.set(key, parseCommaSeparatedString(msg.match[1]))
    msg.send stringWithKey(key)

  robot.respond /roles android$/i, (msg) ->
    msg.send stringWithKey(androidKey(msg))

  robot.respond /roles android add (.*)/i, (msg) ->
    key = androidKey(msg)
    addObjectsToKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles android rm (.*)/i, (msg) ->
    key = androidKey(msg)
    removeObjectsFromKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles android set (.*)/i, (msg) ->
    key = androidKey(msg)
    robot.brain.set(key, parseCommaSeparatedString(msg.match[1]))
    msg.send stringWithKey(key)

  robot.respond /roles ios$/i, (msg) ->
    msg.send stringWithKey(iOSKey(msg))

  robot.respond /roles ios add (.*)/i, (msg) ->
    key = iOSKey(msg)
    addObjectsToKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles ios rm (.*)/i, (msg) ->
    key = iOSKey(msg)
    removeObjectsFromKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles ios set (.*)/i, (msg) ->
    key = iOSKey(msg)
    robot.brain.set(key, parseCommaSeparatedString(msg.match[1]))
    msg.send stringWithKey(key)

  robot.respond /roles iosRole$/i, (msg) ->
    msg.send stringWithKey(iosRoleKey(msg))

  robot.respond /roles iosRole add (.*)/i, (msg) ->
    console.log("this works")
    key = iosRoleKey(msg)
    addObjectsToKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles iosRole rm (.*)/i, (msg) ->
    key = iosRoleKey(msg)
    removeObjectsFromKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles androidRole$/i, (msg) ->
    msg.send stringWithKey(androidRoleKey(msg))

  robot.respond /roles androidRole add(.*)/i, (msg) ->
    key = androidRoleKey(msg)
    addObjectsToKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)

  robot.respond /roles androidRole rm (.*)/i, (msg) ->
    key = androidRoleKey(msg)
    removeObjectsFromKey(parseCommaSeparatedString(msg.match[1]), key)
    msg.send stringWithKey(key)
    
  robot.respond /roles legend set ([^\s]+)$/i, (msg) ->
    key = legendKey(msg)
    msg.robot.brain.set(key, msg.match[1])
    msg.send stringWithKey(key)
   
  robot.respond /roles legend$/i, (msg) ->
    msg.send stringWithKey(legendKey(msg))

  strategiesRegex = strategies.join('|')

  robot.respond new RegExp("roles strategy set (#{strategiesRegex})$", 'i'), (msg) ->
    strategy = _.find(strategies, (strategy) ->
      strategy.toLowerCase() == msg.match[1].toLowerCase()
    )
    key = strategyKey(msg)
    msg.robot.brain.set(key, strategy)
    msg.send stringWithKey(key)
    
  robot.respond /roles strategies$/i, (msg) ->
    msg.send prettyArrayString(strategies)
  
  robot.respond /roles strategy$/i, (msg) ->
    msg.send strategyForRoom(msg)

  stringWithKey = (key) ->
    objects = robot.brain.get(key)
    if !objects or _.isEmpty(objects)
      "None"
    else if Array.isArray objects
      prettyArrayString(objects)
    else
      objects

  addObjectsToKey = (objects, key) ->
    existingObjects = robot.brain.get(key)
    if !existingObjects
      existingObjects = []
    existingObjects.push object for object in objects
    robot.brain.set(key, existingObjects)

  removeObjectsFromKey = (objects, key) ->
    existing = robot.brain.get(key)
    newObjects = removeObjects(existing, objects)
    robot.brain.set(key, newObjects)
