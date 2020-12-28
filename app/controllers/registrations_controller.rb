# i really, really wanted this controller in a namespace, but devise doesn't
# appear to support it. instead, i got the following error:
#
#   'Authentication::RegistrationsController' is not a supported controller name.
#   This can lead to potential routing problems.

class RegistrationsController < Devise::RegistrationsController
  def new
    if invitation_only?
      unless session[:invitation_uuid] || session[:invitation_key]
        return redirect_to root_path
      end
    end

    # do all the regular devise stuff.
    super
  end

  def create

    # do all the regular devise stuff first.
    super

    # if current_user is defined, that means they were successful registering.
    if current_user

      # TODO i think this might be redundant. we've added a hook into `session["user_return_to"]` in the
      # `invitations#accept` action and that might be enough to get them where they're supposed to be after
      # either creating a new account or signing into an existing account.

      # was this user registering to claim an invitation?
      if session[:invitation_uuid].present?

        # try to find the invitation, if it still exists.
        invitation = Invitation.find_by_uuid(session[:invitation_uuid])

        if invitation
          # if the invitation was found, claim it for this user.
          invitation.accept_for(current_user)
        end

        # remove the uuid from the session.
        session.delete(:invitation_uuid)

      end

      # if the user doesn't have a team at this point, create one.
      unless current_user.teams.any?
        current_user.create_default_team
      end

      # send the welcome email.
      current_user.send_welcome_email unless current_user.email_is_oauth_placeholder?

    end

  end

end