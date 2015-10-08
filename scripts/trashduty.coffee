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


# Setup
SlackClient = require('slack-node')
slackToken = process.env.HUBOT_SLACK_TOKEN
if not slackToken
    console.log "ERROR: HUBOT_SLACK_TOKEN was not set as an environment variable"
    return
slack = new SlackClient(slackToken)

TIMEZONE='America/Los_Angeles'
TRASH_ASSIGNMENT_TIME='5 0 0 * * *' # Sec, Min, Hr, Day, Mon, DayOfWeek
#TRASH_ASSIGNMENT_TIME = "askjdaslkdj"
cronJob = require('cron').CronJob
        


util = require('util')

module.exports = (robot) ->

    # Get firstime trash person
    # Note: This means that if the app crashes, trash duty goes to someone else, so this is my incentive to not have it crash...or to crash it, depending ;)
    garbageGuy = robot.brain.get('trashDuty')
    if not garbageGuy
        slack.api "users.list", (err, res) ->
            throw err if err
            names = []
            for user in res.members
                if not user.is_bot
                    names.push user.name
            chosenIdx = Math.floor(Math.random() * (names.length))
            console.log "Idx is: #{chosenIdx}"
            first = names[chosenIdx]
            console.log "First time trash duty goes to: #{first}"
            garbageGuy = first
            robot.brain.set 'trashDuty', garbageGuy
#    job = new CronJob TRASH_ASSIGNMENT_TIME,
#            ->
#                # get users here
#                console.log "Job fired"
#                slack.api "users.list", (err, res) ->
#                    throw err if err
#                    names = []
#                    for user in res.members
#                        if not user.is_bot
#                            names.push user.name
#                    chosenIdx = names.indexOf(process.env.HUBOT_TRASH_DUTY)
#                    console.log "Idx is: #{chosenIdx}"
#                    if chosenIdx
#                        first = names[chosenIdx + 1]
#                        console.log "Trash duty changed to: #{first}"
#                        process.env.HUBOT_TRASH_DUTY=first
#            ->
#                console.log "Job complete!"
#            true
#            TIMEZONE
#    job.start
    try
        fiveSecJob = new cronJob
            cronTime: TRASH_ASSIGNMENT_TIME,
            onTick: every5Seconds,
            onComplete: jobCompleted
            start: true,
        console.log "Job started"
    catch
        console.log "Ya dun goofed with the cron pattern"

    jobCompleted = ->
        console.log "HEY LOOK OVER HERE!:!:!: Job is complete"
    every5Seconds = ->
        console.log "Is this happening every five?"

    robot.hear /trash duty goes to (%\S+)/, (slackRes) ->
        chosenOne = slackRes.match[1]
        garbageGuy = robot.brain.get 'trashDuty'
        if garbageGuy
            slackRes.send "Nice try, #{garbageGuy} already has trash duty"
        else
            [symbol, name] = chosenOne.split "%"
            isRealUser = false
            console.log "Symbol is: #{symbol}, name is: #{name}"
            slack.api "users.list", (err, res) ->
                throw err if err
                for user in res.members
                    if not user.is_bot and name == user.name
                        console.log "Found him!!"
                        isRealUser = true
                        break
                console.log "Real User? #{isRealUser}"
                if isRealUser
                    garbageGuy = chosenOne
                    robot.brain.set 'trashDUty', garbageGuy
                    console.log "#{chosenOne} has been assigned trash duty"
                else
                    console.log "#{chosenOne} is not a real user dummy"

    robot.hear /who has trash duty/i, (slackRes) ->
        garbageGuy = robot.brain.get 'trashDuty'
        if garbageGuy
            slackRes.send "#{garbageGuy} is on trash duty"
        else
            slack.api "users.list", (err, res) ->
                throw err if err
                names = []
                for user in res.members
                    if not user.is_bot
                        names.push user.name
                chosenIdx = Math.floor(Math.random() * (names.length - 0) + 0)
                console.log "Idx is: #{chosenIdx}"
                first = names[chosenIdx]
                console.log "First name is: #{first}"
                garbageGuy = first
                robot.brain.set 'trashDuty', garbageGuy
                slackRes.send "#{garbageGuy} is on trash duty"
