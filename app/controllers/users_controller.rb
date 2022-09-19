class UsersController < ApplicationController

  def index
    render jsonapi: User.all
  end

  #curl --request POST --header "Authentication: Bearer <token>" --header "Content-Type: application/json" http://localhost:3189/users/archive --data '{"user": {"id": "4"}, "type": "archive"}'
  def archive
    user = User.get_record(user_params[:id])
    if user.blank? || !AdminType::DELETE_TYPES.include?(params[:type])
      render jsonapi_errors: {detail: 'User already deleted / Type is incorrect', status: :not_acceptable, title: "Valid parameters required"}, status: :not_acceptable
    elsif current_user.id == user_params[:id].to_i 
      render jsonapi_errors: {detail: 'User Id should not be same as authorized user', status: :not_acceptable, title: "Valid id required"}, status: :not_acceptable
    else     
      if user.paranoia_destroyed? && params[:type] == AdminType::ARCHIVE
        render jsonapi_errors: {detail: 'User not found or already archived', status: :not_found, title: "User not found"}, status: :not_found
      else       
        is_user_updated = User.archive_unarchive(params[:type], user) #calling User model archive_unarchive method
        render jsonapi: [user], status: :ok unless !is_user_updated
        render jsonapi_errors: { detail:  'User not updated', status: :internal_server_error, title: "User not updated", code: :internal_server_error}, status: :internal_server_error unless is_user_updated
      end
    end
  end

  #curl --request GET --header "Authentication: Bearer <token>" --header "Content-Type: application/json" http://localhost:3189/users/deleted_list --data '{"type": "archive"}'
  def deleted_list
    if [AdminType::ARCHIVE, AdminType::UNARCHIVE].include?(params[:type])
      render jsonapi: User.get_list(params[:type]), status: :ok
    else
      render jsonapi_errors: { detail:  'Type is incorrect', status: :unprocessable_entity, title: "Type is required", code: :unprocessable_entity}, status: :unprocessable_entity
    end
  end

  #curl --request GET --header "Authentication: Bearer <token>" --header "Content-Type: application/json" http://localhost:3189/users/track_logs
  def track_logs
    logs = PaperTrail::Version.where(item_type: "User")
    users_email_hash = User.pluck(:id, :email).to_h
    logs_arr = []
    logs.each do |log|
      next if log.object.blank?
      obj_hash = YAML.load(log.object)
      log_record = {}
      log_record[:modified_type] = log.event
      log_record[:modified_user] = obj_hash["email"]
      log_record[:modified_by] = users_email_hash[log.whodunnit.to_i]
      logs_arr << log_record
    end
    render json: { message: 'Success' , status: :success, data: logs_arr } 
  end


  private

  def user_params
    params.require(:user).permit(:id)
  end
  
end
