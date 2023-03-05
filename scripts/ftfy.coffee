##
# Description
#   Because those GitHubbers keep using the wrong alias
{TextMessage} = require 'hubot'

module.exports = (robot) ->
  robot.hear /^\.(\w+)(.*)/, (msg) ->
    payload = new TextMessage(msg.envelope.user, true)
    payload.text = "#{robot.name} #{msg.match[1].trim()} #{msg.match[2].trim()}"
    robot.logger.debug payload.text
    robot.receive payload, () ->
      robot.logger.debug 'Message sent back for processing with correct alias.'
