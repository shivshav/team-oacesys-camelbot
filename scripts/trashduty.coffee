# Author: Shiv

# Setup
SlackClient = require('slack-node')
slackToken = process.env.HUBOT_SLACK_TOKEN
slack = new SlackClient(slackToken)

TIMEZONE='America/Los_Angeles'
TRASH_ASSIGNMENT_TIME='5 0 0 * * *' # Sec, Min, Hr, Day, Mon, DayOfWeek
cronJob = require('cron').CronJob
        

# Get firstime trash person
# Note: This means that if the app crashes, trash duty goes to someone else, so this is my incentive to not have it crash...or to crash it, depending ;)
if not process.env.HUBOT_TRASH_DUTY
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
        process.env.HUBOT_TRASH_DUTY=first

util = require('util')

module.exports = (robot) ->

    console.log "Job started"
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

    fiveSecJob = new cronJob TRASH_ASSIGNMENT_TIME, every5Seconds, null, true, TIMEZONE

    every5Seconds = ->
        console.log "Is this happening every five?"

    robot.hear /trash duty goes to (%\S+)/, (slackRes) ->
        chosenOne = slackRes.match[1]
        if process.env.HUBOT_TRASH_DUTY
            slackRes.send "Nice try, #{process.env.HUBOT_TRASH_DUTY} already has trash duty"
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
                    process.env.HUBOT_TRASH_DUTY=chosenOne
                    console.log "#{chosenOne} has been assigned trash duty"
                else
                    console.log "#{chosenOne} is not a real user dummy"
    robot.hear /who has trash duty/i, (slackRes) ->
        if process.env.HUBOT_TRASH_DUTY
            slackRes.send "#{process.env.HUBOT_TRASH_DUTY} is on trash duty"
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
                process.env.HUBOT_TRASH_DUTY=first
    #            console.log "Trash duty goes to #{process.env.HUBOT_TRASH_DUTY}"
                slackRes.send "#{process.env.HUBOT_TRASH_DUTY} is on trash duty"
