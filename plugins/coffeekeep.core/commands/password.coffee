new Command
  name: 'password'
  aliases: ['pword']
  description: "Changes the password on the current account."
  help: "Usage: password"
  action: (context, request, callback) ->
    {mob, room, session} = context
    {verb, args} = request

    session.setEcho 'secret'
    session.question "Old password: ", (response) ->
      if not mob.checkPassword response
        mob.print "That password is incorrect. Please try again."
        session.setEcho 'normal'
        return do callback
      else
        session.question "New Password: ", (response) ->
          if not response
            mob.print "Empty passwords are not allowed. Please try again."
            session.setEcho 'normal'
            return do callback

          session.question "New Password (Again): ", (response2) ->
            if not response2
              mob.print "The second password was empty. Please try again."
              session.setEcho 'normal'
              return do callback

            if not (response == response2)
              mob.print "Passwords did not match."
              session.setEcho 'normal'
              return do callback
            else
              mob.setPassword response
              mob.print "Password was changed successfully."
              session.setEcho 'normal'
              return do callback
