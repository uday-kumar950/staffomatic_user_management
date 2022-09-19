require 'rails_helper'

RSpec.describe 'Users', type: :request do
  let(:user) do
    User.create(
      email: 'danie@example.com',
      password: 'supersecurepassword',
      password_confirmation: 'supersecurepassword',
      )
  end

  let(:second_user) do
    User.create(
      email: 'roy@example.com',
      password: 'supersecurepassword1',
      password_confirmation: 'supersecurepassword1',
      )
  end

  let(:auth_token) do  
    authenticate_user(user)
  end

  describe 'GET /index' do
    it 'returns http success' do
      auth_token = authenticate_user(user)
      get users_path, headers: { 'Authentication' => "Bearer #{auth_token}" }
      expect(response).to have_http_status(:success)
    end
  end


  describe "POST /archive" do

    # end
    fit "returns http success" do
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{second_user.id}"}, type: AdminType::ARCHIVE}.to_json
      expect(response).to have_http_status(:ok)
    end

    fit "returns http error while archive login user" do
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{user.id}"}, type: AdminType::ARCHIVE}.to_json
      expect(response).to have_http_status(:not_acceptable)
    end

    fit "returns http error while user already archived" do
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{User.last.id}"}, type: AdminType::ARCHIVE}.to_json
      expect(response).to have_http_status(:not_acceptable)
    end

    fit "returns http error while type is incorrect" do
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{second_user.id}"}, type: "invalidtype"}.to_json
      expect(response).to have_http_status(:not_acceptable)
    end

    fit "returns http success while updating archive to unarchive" do
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{second_user.id}"}, type: AdminType::UNARCHIVE}.to_json
      expect(response).to have_http_status(:ok)
    end

    fit "returns http success after deleting" do
      undeleted_users_count = User.all.length
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{second_user.id}"}, type: AdminType::DELETE}.to_json
      expect(response).to have_http_status(:ok)
    end

  end

  describe "GET /deleted_list" do  
    fit "returns http success with type archive" do
      deleted_users_count = User.only_deleted.length
      get deleted_list_users_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {type: AdminType::ARCHIVE}
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["data"]
      expect(data.length).to eq(deleted_users_count)
    end

    fit "returns http success with type unarchive" do
      get deleted_list_users_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {type: AdminType::UNARCHIVE}
      expect(response).to have_http_status(:ok)
      undeleted_users_count = User.all.length
      data = JSON.parse(response.body)["data"]
      expect(data.length).to eq(undeleted_users_count)
    end

    fit "returns http error with invalid type" do
      get deleted_list_users_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {type: 'invalidtype'}
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end


  describe "GET /track_logs" do 
    fit "returns http success with type archive" do
      post users_archive_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }, params: {user: {id: "#{second_user.id}"}, type: AdminType::ARCHIVE}.to_json
      get track_logs_users_path, headers: { 'Authentication' => "Bearer #{auth_token}", "Content-Type": "application/json" }
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)["data"]
      expect(PaperTrail::Version.all.length).to eq(1)
      expect(data.first["modified_by"]).to eq(user.email)
    end
  end
end
