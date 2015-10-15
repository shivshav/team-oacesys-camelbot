# Description:
#   A personal Hubot instance created for the oacesys
#
# Dependencies:
#   None as far as I can tell
#
# Configuration:
#   HUBOT_SLACK_TOKEN set as an environment variable
#
# Commands:
#   hubot who has trash duty - Returns the slack user who has been assigned trash duty
#
# Author: 
#   shivshav


# Slack Setup
SlackClient = require('slack-node')
slackToken = process.env.HUBOT_SLACK_TOKEN
if not slackToken
    console.log "ERROR: HUBOT_SLACK_TOKEN was not set as an environment variable"
    return
slack = new SlackClient(slackToken)

# Cron setup
TIMEZONE='America/Los_Angeles'
TRASH_ASSIGNMENT_TIME='* /1 * * * *' # Sec, Min, Hr, Day, Mon, DayOfWeek
#TRASH_ASSIGNMENT_TIME = "askjdaslkdj"
#cronJob = require('cron').CronJob
schedule = require('node-schedule')
arrayEqual = (a, b) ->
    a.length is b.length and a.every (elem, i) -> elem is b[i]


# Debugging
util = require('util')

module.exports = (robot) ->

    garbageGuy = robot.brain.get('trashDuty')

    # Get firstime trash person
    # Note: This means that if the app crashes, trash duty goes to someone else, so this is my incentive to not have it crash...or to crash it, depending ;)
    if not garbageGuy
        slack.api "users.list", (err, res) ->
            throw err if err
            names = res.members
                        .filter (user) ->
                            return not user.is_bot
                        .map (user) ->
                            return user.name
                        .sort()
            console.log "Names: #{names}"
            chosenIdx = Math.floor(Math.random() * (names.length))
            console.log "Idx is: #{chosenIdx}"
            first = names[chosenIdx]
            console.log "First time trash duty goes to: #{first}"
            garbageGuy = first
            robot.brain.set 'currentMembers', names
            robot.brain.set 'trashDuty', garbageGuy

    scheduledJob = schedule.scheduleJob '/5 * * * * *', () ->
                        # Get list of api users
                        slack.api "users.list", (err, res) ->
                            throw err if err
                            names = res.members
                                        .filter (user) ->
                                            return not user.is_bot
                                        .map (user) ->
                                            return user.name
                                        .sort()
                            # Compare to saved list
                            garbageMen = robot.brain.get 'currentMembers'
                            chosenIdx = 0
                            if garbageMen and garbageGuy
                                # find indexOf current trash dude
                                if garbageGuy in garbageMen
                                    chosenIdx = names.indexOf garbageGuy
                                    console.log "garbage guy is in old list at #{chosenIdx}"
                                if not arrayEqual garbageMen, names
                                    console.log "New array is #{names} with length #{names.length}"
                            else
                                chosenIdx = Math.floor(Math.random() * (names.length))
                            # select index + 1 as new trash person                     
                            chosenPerson = names[(chosenIdx+1)%names.length]
                            # Send message about new trash person
                            console.log "Chosen Person: #{chosenPerson}"
                            garbageGuy = chosenPerson
                            # save new trash guy
                            robot.brain.set 'trashDuty', garbageGuy
                            # save new list
                            robot.brain.set 'currentMembers', names
                        date = new Date()
                        time = date.getHours() + ':' + date.getMinutes() + ':' + date.getSeconds()
                        console.log "#{time} Tick"
    

    robot.hear /trash duty goes to (%\S+)/, (slackRes) ->
        chosenOne = slackRes.match[1]
        garbageGuy = robot.brain.get 'trashDuty'
        sender = slackRes.message.user.name
        # If someone already has trash duty assigned
        if garbageGuy and sender
            slackRes.send "Nice try #{sender}, #{garbageGuy} already has trash duty"
        # Otherwise NOTE: This should NEVER happen in the current state
        else
            # Get a list of real slack users
            [symbol, name] = chosenOne.split "%"
            isRealUser = false
            console.log "Symbol is: #{symbol}, name is: #{name}"
            slack.api "users.list", (err, res) ->
                # Handle errors first and foremost
                throw err if err
                # We got a response back
                for user in res.members
                    # And check if the user being assigned to trash is a viable user
                    if not user.is_bot and name == user.name
                        console.log "Found him!!"
                        isRealUser = true
                        break
                # If so, assign the user trash duty
                if isRealUser
                    garbageGuy = chosenOne
                    robot.brain.set 'trashDUty', garbageGuy
                    console.log "#{chosenOne} has been assigned trash duty"
                # Otherwise, tell the user how stupid they've been
                else
                    console.log "#{chosenOne} is not a real user dummy"

    robot.hear /[Ww]ho has trash duty\??/i, (slackRes) ->
        garbageGuy = robot.brain.get 'trashDuty'
        if garbageGuy
            slackRes.send "#{garbageGuy} is on trash duty"
        else
            slack.api "users.list", (err, res) ->
                throw err if err
                names = res.members
                            .filter (user) ->
                                return not user.is_bot
                            .map (user) ->
                                return user.name
                            .sort()
                chosenIdx = Math.floor(Math.random() * (names.length - 0) + 0)
                console.log "Idx is: #{chosenIdx}"
                first = names[chosenIdx]
                console.log "First name is: #{first}"
                garbageGuy = first
                robot.brain.set 'trashDuty', garbageGuy
                slackRes.send "#{garbageGuy} is on trash duty"
