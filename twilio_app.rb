require 'sinatra'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

class TwilioApp < Sinatra::Base 
  post '/send_sms' do
    content_type :json
    payload = JSON.parse(request.body.read).with_indifferent_access
    request_id = payload[:request_id]
    sms = payload[:sms]
    params = payload[:parameters]

    begin
      client = Twilio::REST::Client.new(params[:account_sid], params[:auth_token])
      client.account.messages.create(
        :from => sms[:from],
        :to => sms[:phone],
        :body => sms[:message])
    rescue => e
      # tell the hub about the unsuccessful delivery attempt
      status 500
      return { request_id: request_id, summary: "Unable to send SMS message. Error: #{e.message}" }.to_json + "\n"
    end

    # acknowledge the successful delivery of the message
    { request_id: request_id, summary: "SMS message sent" }.to_json + "\n"
  end
end